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

/// Service for fetching media from PSN
class PsnMediaService {
  final Dio _dio;

  PsnMediaService({Dio? dio}) : _dio = dio ?? Dio();

  /// Fetch media gallery page
  Future<MediaGalleryResponse> getMediaGallery({
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

      return MediaGalleryResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw PsnMediaException(
        'Failed to fetch media: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
