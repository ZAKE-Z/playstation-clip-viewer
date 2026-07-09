import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/psn_media_service.dart';
import '../../../../core/services/download_service.dart';
import '../../../../core/services/upload_service.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../upload/providers/upload_settings_provider.dart';
import '../data/media_item.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final MediaItem item;
  final CloudFrontCookies? cookies;

  const DetailScreen({super.key, required this.item, required this.cookies});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.ugcType == MediaType.video) {
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    try {
      // Get signed video URL
      // Priority: downloadUrl (MP4) > videoUrl (HLS) because video_player_win lacks HLS support
      String videoUrl = widget.item.downloadUrl ?? widget.item.videoUrl ?? '';
      if (videoUrl.isEmpty) {
        throw Exception('No video URL found');
      }

      if (widget.cookies != null) {
        videoUrl = widget.cookies!.signUrl(videoUrl);
      }

      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        hideControlsTimer: const Duration(seconds: 1),
        autoPlay: true,
        looping: true,
        aspectRatio: _videoController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error loading video: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Video initialization error: $e');
      if (mounted) {
        setState(() {
          _isError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  final _downloadService = DownloadService();
  final _uploadService = UploadService();
  bool _isDownloading = false;
  bool _isUploading = false;
  double _downloadProgress = 0.0;
  double _uploadProgress = 0.0;

  Future<void> _handleDownload() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    await _downloadService.downloadMedia(
      widget.item,
      cookies: widget.cookies,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
          });
        }
      },
      onSuccess: (path) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Saved to $path')));
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Download failed: $error')));
        }
      },
    );
  }

  Future<void> _handleUpload(BuildContext context) async {
    if (_isUploading) return;

    final config = await ref.read(uploadConfigProvider.future);
    if (config == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Import a ShareX config in Settings to upload',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    await _uploadService.uploadMedia(
      widget.item,
      config: config,
      cookies: widget.cookies,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _uploadProgress = progress;
          });
        }
      },
      onSuccess: (result) {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
          if (result.responseUrl != null && result.responseUrl!.isNotEmpty) {
            Clipboard.setData(ClipboardData(text: result.responseUrl!));
          }
          final msg = result.responseUrl != null
              ? 'Uploaded! URL copied to clipboard'
              : 'Upload complete!';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Upload failed: $error')));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.sceTitleName),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: _isUploading ? null : () => _handleUpload(context),
            tooltip: 'Upload',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _isDownloading ? null : _handleDownload,
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media Preview (Left/Top side)
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black,
              child: Center(child: _buildMediaPreview()),
            ),
          ),

          // Metadata (Right/Bottom side)
          Container(
            width: 350,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.sceTitleName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(widget.item.uploadDate),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                _buildMetadataRow(
                  'Type',
                  widget.item.ugcType == MediaType.video
                      ? 'Video'
                      : 'Screenshot',
                ),
                if (widget.item.videoDuration != null)
                  _buildMetadataRow(
                    'Duration',
                    _formatDuration(widget.item.videoDuration!),
                  ),
                _buildMetadataRow(
                  'Size',
                  _formatFileSize(widget.item.fileSize ?? 0),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isUploading ? null : () => _handleUpload(context),
                    icon: _isUploading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                              value:
                                  _uploadProgress > 0 ? _uploadProgress : null,
                            ),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(
                      _isUploading
                          ? 'Uploading ${(_uploadProgress * 100).toInt()}%'
                          : 'Upload',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _isDownloading ? null : _handleDownload,
                    icon: _isDownloading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                              value: _downloadProgress > 0
                                  ? _downloadProgress
                                  : null,
                            ),
                          )
                        : const Icon(Icons.download),
                    label: Text(
                      _isDownloading
                          ? 'Downloading ${(_downloadProgress * 100).toInt()}%'
                          : 'Download',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (widget.item.ugcType == MediaType.video) {
      if (_isError) {
        return const Icon(Icons.error_outline, color: Colors.red, size: 48);
      }
      if (_chewieController != null &&
          _chewieController!.videoPlayerController.value.isInitialized) {
        return Chewie(controller: _chewieController!);
      }
      return const CircularProgressIndicator();
    } else {
      // For screenshots
      String imageUrl = widget.item.largePreviewImage;
      if (widget.cookies != null) {
        imageUrl = widget.cookies!.signUrl(imageUrl);
      }

      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return const CircularProgressIndicator();
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, color: Colors.white, size: 48);
        },
      );
    }
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, y • h:mm a').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
