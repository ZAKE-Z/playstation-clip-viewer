import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/image_cache_service.dart';
import '../data/media_item.dart';
import '../providers/media_provider.dart';

class MediaGridItem extends ConsumerStatefulWidget {
  final MediaItem item;
  final VoidCallback? onTap;

  const MediaGridItem({super.key, required this.item, this.onTap});

  @override
  ConsumerState<MediaGridItem> createState() => _MediaGridItemState();
}

class _MediaGridItemState extends ConsumerState<MediaGridItem> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(MediaGridItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if the item changed
    if (oldWidget.item.id != widget.item.id) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final cookies = ref.read(cloudFrontCookiesProvider);
    if (cookies == null) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }

    final signedUrl = cookies.signUrl(widget.item.smallPreviewImage);

    try {
      final bytes = await ImageCacheService.instance.getImage(signedUrl);

      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _hasError = bytes == null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Image load error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImage(),
          ),
          // Video indicator
          if (widget.item.ugcType == MediaType.video)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      size: 16,
                      color: Colors.white,
                    ),
                    if (widget.item.videoDuration != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(widget.item.videoDuration!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          // Game name overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
              ),
              child: Text(
                widget.item.sceTitleName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (_isLoading) {
      return Container(
        color: Colors.grey[800],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_hasError || _imageBytes == null) {
      return Container(color: Colors.grey[800], child: const Icon(Icons.error));
    }

    return Image.memory(_imageBytes!, fit: BoxFit.cover);
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}
