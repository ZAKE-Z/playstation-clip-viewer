import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/clips/data/media_item.dart';
import '../../features/upload/data/upload_config.dart';
import 'psn_media_service.dart';

/// Result of a successful upload
class UploadResult {
  final String? responseUrl;

  const UploadResult({this.responseUrl});
}

class UploadService {
  final Dio _dio = Dio();

  /// Upload a clip or screenshot using the given config (ShareX-style).
  Future<void> uploadMedia(
    MediaItem item, {
    required UploadConfig config,
    CloudFrontCookies? cookies,
    required Function(double progress) onProgress,
    required Function(UploadResult result) onSuccess,
    required Function(dynamic error) onError,
  }) async {
    File? tempFile;
    try {
      // 1. Resolve download URL
      String downloadUrl = item.downloadUrl ??
          (item.ugcType == MediaType.video
              ? item.videoUrl
              : item.screenshotUrl) ??
          item.largePreviewImage;

      if (downloadUrl.isEmpty) {
        throw Exception('No download URL found for this media');
      }

      if (cookies != null) {
        downloadUrl = cookies.signUrl(downloadUrl);
      }

      // 2. Download to temp file
      final extension = item.ugcType == MediaType.video ? 'mp4' : 'jpg';
      final tempDir = await getTemporaryDirectory();
      tempFile = File('${tempDir.path}/psclips_upload_${item.id}.$extension');

      await _dio.download(
        downloadUrl,
        tempFile.path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total * 0.5);
          }
        },
      );

      // 3. Upload via multipart/form-data
      final formData = FormData.fromMap({
        config.fileFormName: await MultipartFile.fromFile(
          tempFile.path,
          filename:
              '${item.sceTitleName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '')}.$extension',
        ),
      });

      final method = config.requestMethod.toUpperCase();
      final response = await _dio.request(
        config.requestUrl,
        data: formData,
        options: Options(
          method: method,
          headers: config.headers,
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 1),
        ),
        onSendProgress: (sent, total) {
          if (total != -1) {
            onProgress(0.5 + (sent / total) * 0.5);
          }
        },
      );

      String? responseUrl =
          _extractResponseUrl(response.data, config.urlTemplate);

      onSuccess(UploadResult(responseUrl: responseUrl));
    } catch (e) {
      debugPrint('Upload error: $e');
      onError(e);
    } finally {
      tempFile?.deleteSync();
    }
  }

  /// Extract URL from API response using ShareX URL template if provided
  String? _extractResponseUrl(dynamic data, String? urlTemplate) {
    if (data == null) return null;

    // ShareX {json:path} - e.g. {json:data.link} or {json:url}
    if (urlTemplate != null &&
        urlTemplate.contains('{json:') &&
        data is Map<String, dynamic>) {
      final match = RegExp(r'\{json:([^}]+)\}').firstMatch(urlTemplate);
      if (match != null) {
        final path = match.group(1)!.trim();
        final value = _jsonPath(data, path);
        if (value is String && value.startsWith('http')) return value;
      }
    }

    // Fallback: flexible parsing
    if (data is String) {
      final trimmed = data.trim();
      return trimmed.startsWith('http') ? trimmed : null;
    }
    if (data is Map<String, dynamic>) {
      final keys = [
        'response',
        'responseURL',
        'url',
        'link',
        'file',
        'path',
        'data',
      ];
      for (final key in keys) {
        final v = data[key];
        if (v is String && v.startsWith('http')) return v;
      }
      final nested = data['data'] as Map<String, dynamic>? ?? data['result'];
      if (nested is Map<String, dynamic>) {
        return _extractResponseUrl(nested, null);
      }
    }
    return null;
  }

  /// Simple JSON path: "data.link" or "files[0].url"
  dynamic _jsonPath(Map<String, dynamic> obj, String path) {
    dynamic current = obj;
    final segments = path.replaceAll(RegExp(r'\[(\d+)\]'), r'.$1').split('.');
    for (final seg in segments) {
      if (current == null) return null;
      final indexMatch = RegExp(r'^(\d+)$').firstMatch(seg);
      if (indexMatch != null && current is List) {
        final i = int.parse(indexMatch.group(1)!);
        current = i < current.length ? current[i] : null;
      } else if (current is Map) {
        current = (current as Map<String, dynamic>)[seg];
      }
    }
    return current;
  }
}
