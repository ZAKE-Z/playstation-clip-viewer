import 'package:dio/dio.dart';
import '../constants/psn_api.dart';
import '../../features/clips/data/media_gallery_response.dart';

/// Exception for PSN media API errors
class PsnMediaException implements Exception {
  final String message;
  final int? statusCode;

  PsnMediaException(this.message, {this.statusCode});

  @override
  String toString() => 'PsnMediaException: $message';
}

/// CloudFront credentials required for accessing media URLs
class CloudFrontCookies {
  final String keyPairId;
  final String signature;
  final String policy;

  const CloudFrontCookies({
    required this.keyPairId,
    required this.signature,
    required this.policy,
  });

  /// Append CloudFront query parameters to a URL
  String signUrl(String url) {
    final separator = url.contains('?') ? '&' : '?';
    // URL-encode the signature and policy values
    final encodedSignature = Uri.encodeComponent(signature);
    final encodedPolicy = Uri.encodeComponent(policy);
    return '$url${separator}Key-Pair-Id=$keyPairId&Signature=$encodedSignature&Policy=$encodedPolicy';
  }

  @override
  String toString() =>
      'CloudFrontCookies(keyPairId: ${keyPairId.substring(0, 10)}...)';
}

/// Result containing both media response and cookies
class MediaGalleryResult {
  final MediaGalleryResponse response;
  final CloudFrontCookies? cookies;

  const MediaGalleryResult({required this.response, this.cookies});
}

/// Service for fetching media from PSN
class PsnMediaService {
  final Dio _dio;

  PsnMediaService({Dio? dio}) : _dio = dio ?? Dio();

  /// Fetch media gallery page with CloudFront cookies
  Future<MediaGalleryResult> getMediaGallery({
    required String accessToken,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        PsnApi.mediaApiBaseUrl,
        queryParameters: {
          'limit': limit,
          if (cursor != null) 'cursorMark': cursor,
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      // Extract CloudFront cookies from response headers
      final cookies = _extractCloudFrontCookies(response.headers);

      return MediaGalleryResult(
        response: MediaGalleryResponse.fromJson(
          response.data as Map<String, dynamic>,
        ),
        cookies: cookies,
      );
    } on DioException catch (e) {
      throw PsnMediaException(
        'Failed to fetch media: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Extract CloudFront cookies from Set-Cookie headers
  CloudFrontCookies? _extractCloudFrontCookies(Headers headers) {
    final setCookies = headers['set-cookie'];
    if (setCookies == null || setCookies.isEmpty) return null;

    String? keyPairId;
    String? signature;
    String? policy;

    for (final cookie in setCookies) {
      if (cookie.startsWith('CloudFront-Key-Pair-Id=')) {
        keyPairId = _extractCookieValue(cookie, 'CloudFront-Key-Pair-Id');
      } else if (cookie.startsWith('CloudFront-Signature=')) {
        signature = _extractCookieValue(cookie, 'CloudFront-Signature');
      } else if (cookie.startsWith('CloudFront-Policy=')) {
        policy = _extractCookieValue(cookie, 'CloudFront-Policy');
      }
    }

    if (keyPairId != null && signature != null && policy != null) {
      return CloudFrontCookies(
        keyPairId: keyPairId,
        signature: signature,
        policy: policy,
      );
    }
    return null;
  }

  /// Extract value from a Set-Cookie header
  String _extractCookieValue(String cookie, String name) {
    final start = cookie.indexOf('$name=') + name.length + 1;
    final end = cookie.indexOf(';', start);
    if (end == -1) {
      return cookie.substring(start);
    }
    return cookie.substring(start, end);
  }
}
