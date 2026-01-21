import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import '../../features/clips/data/media_item.dart';
import 'psn_media_service.dart';

class DownloadService {
  final Dio _dio = Dio();

  Future<void> downloadMedia(
    MediaItem item, {
    CloudFrontCookies? cookies,
    required Function(double progress) onProgress,
    required Function(String path) onSuccess,
    required Function(dynamic error) onError,
  }) async {
    try {
      // 1. Determine suggested filename
      final String extension = item.ugcType == MediaType.video ? 'mp4' : 'jpg';
      // Sanitize title for filename
      final safeTitle = item.sceTitleName.replaceAll(
        RegExp(r'[<>:"/\\|?*]'),
        '',
      );
      final date = item.uploadDate.split('T').first;
      final suggestedName = '$safeTitle - $date.$extension';

      // 2. Pick save location
      final FileSaveLocation? result = await getSaveLocation(
        suggestedName: suggestedName,
        acceptedTypeGroups: [
          XTypeGroup(
            label: item.ugcType == MediaType.video ? 'Video' : 'Image',
            extensions: [extension],
          ),
        ],
      );

      if (result == null) {
        // User canceled
        return;
      }

      final String savePath = result.path;

      // 3. Prepare URL (sign if needed)
      // Use downloadUrl if available, otherwise switch on type
      String downloadUrl =
          item.downloadUrl ??
          (item.ugcType == MediaType.video
              ? item.videoUrl
              : item.screenshotUrl) ??
          item.largePreviewImage;

      if (cookies != null) {
        downloadUrl = cookies.signUrl(downloadUrl);
      }

      // 4. Download file
      await _dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      onSuccess(savePath);
    } catch (e) {
      debugPrint('Download error: $e');
      onError(e);
    }
  }
}
