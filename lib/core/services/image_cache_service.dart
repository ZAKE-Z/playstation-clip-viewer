import 'dart:async';
import 'dart:collection';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Image cache with strict sequential loading using a queue
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._();
  static ImageCacheService get instance => _instance;

  ImageCacheService._();

  final Map<String, Uint8List> _cache = {};
  final Map<String, Completer<Uint8List?>> _pending = {};
  final Queue<_FetchRequest> _queue = Queue();
  final Dio _dio = Dio();

  bool _isProcessing = false;
  static const Duration _delayBetweenRequests = Duration(milliseconds: 150);

  /// Get image bytes from cache or queue for sequential fetch
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

    // Create a completer and add to queue
    final completer = Completer<Uint8List?>();
    _pending[cacheKey] = completer;
    _queue.add(
      _FetchRequest(url: url, cacheKey: cacheKey, completer: completer),
    );

    // Start processing queue if not already running
    _startProcessing();

    return completer.future;
  }

  void _startProcessing() {
    if (_isProcessing) return;
    _isProcessing = true;
    _processNext();
  }

  Future<void> _processNext() async {
    if (_queue.isEmpty) {
      _isProcessing = false;
      return;
    }

    final request = _queue.removeFirst();

    // Skip if already cached (loaded by another request)
    if (_cache.containsKey(request.cacheKey)) {
      request.completer.complete(_cache[request.cacheKey]);
      _pending.remove(request.cacheKey);
      // Process next immediately
      _processNext();
      return;
    }

    int attempts = 0;
    bool success = false;
    const maxRetries = 3;

    while (attempts < maxRetries && !success) {
      attempts++;
      try {
        final response = await _dio.get<List<int>>(
          request.url,
          options: Options(responseType: ResponseType.bytes),
        );

        if (response.data != null) {
          final bytes = Uint8List.fromList(response.data!);
          _cache[request.cacheKey] = bytes;
          request.completer.complete(bytes);
          success = true;
        }
      } catch (e) {
        // Only retry if we haven't hit max attempts
        if (attempts < maxRetries) {
          debugPrint(
            'Image fetch error for ${request.cacheKey} (attempt $attempts): $e. Retrying...',
          );
          // Backoff delay: 500ms, 1000ms...
          await Future.delayed(Duration(milliseconds: 500 * attempts));
        } else {
          debugPrint('Image fetch failed after $maxRetries attempts: $e');
        }
      }
    }

    if (!success) {
      request.completer.complete(null);
    }

    _pending.remove(request.cacheKey);

    // Wait before next request
    await Future.delayed(_delayBetweenRequests);
    _processNext();
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
  int get queueSize => _queue.length;
}

class _FetchRequest {
  final String url;
  final String cacheKey;
  final Completer<Uint8List?> completer;

  _FetchRequest({
    required this.url,
    required this.cacheKey,
    required this.completer,
  });
}
