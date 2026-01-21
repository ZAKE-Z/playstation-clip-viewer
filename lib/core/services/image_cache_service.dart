import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Image cache with strict rate-limited sequential loading
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._();
  static ImageCacheService get instance => _instance;

  ImageCacheService._();

  final Map<String, Uint8List> _cache = {};
  final Map<String, Completer<Uint8List?>> _pending = {};
  final Dio _dio = Dio();

  /// Semaphore to limit concurrent requests
  int _activeRequests = 0;
  static const int _maxConcurrent = 2;
  static const Duration _delayBetweenRequests = Duration(milliseconds: 100);

  /// Get image bytes from cache or fetch with rate limiting
  Future<Uint8List?> getImage(String url) async {
    final cacheKey = _getCacheKey(url);

    // Return from cache immediately if available
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    // If already pending, wait for that request
    if (_pending.containsKey(cacheKey)) {
      return _pending[cacheKey]!.future;
    }

    // Create a completer for this request
    final completer = Completer<Uint8List?>();
    _pending[cacheKey] = completer;

    // Wait for a slot to become available
    await _waitForSlot();

    // Double-check cache after waiting (might have been loaded)
    if (_cache.containsKey(cacheKey)) {
      _pending.remove(cacheKey);
      completer.complete(_cache[cacheKey]);
      return completer.future;
    }

    // Fetch the image
    _fetchImage(url, cacheKey, completer);

    return completer.future;
  }

  /// Wait until a request slot is available
  Future<void> _waitForSlot() async {
    while (_activeRequests >= _maxConcurrent) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _activeRequests++;
  }

  /// Release a request slot
  void _releaseSlot() {
    _activeRequests--;
  }

  Future<void> _fetchImage(
    String url,
    String cacheKey,
    Completer<Uint8List?> completer,
  ) async {
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data != null) {
        final bytes = Uint8List.fromList(response.data!);
        _cache[cacheKey] = bytes;
        completer.complete(bytes);
      } else {
        completer.complete(null);
      }
    } catch (e) {
      debugPrint('Image fetch error: $e');
      completer.complete(null);
    } finally {
      _pending.remove(cacheKey);
      _releaseSlot();
      // Small delay between requests to avoid bursts
      await Future.delayed(_delayBetweenRequests);
    }
  }

  String _getCacheKey(String url) {
    final uri = Uri.parse(url);
    return uri.path;
  }

  /// Clear all cached images
  void clearCache() {
    _cache.clear();
  }

  int get cacheSize => _cache.length;
}
