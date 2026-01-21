---
phase: 3
plan: 2
wave: 1
---

# Plan 3.2: Media API Service

## Objective
Create the service layer for fetching media from PSN API. Handles authentication, pagination, and error handling.

## Context
- .gsd/phases/3/RESEARCH.md
- lib/core/services/psn_auth_service.dart (pattern)
- lib/features/clips/data/media_item.dart
- lib/features/clips/data/media_gallery_response.dart

## Tasks

<task type="auto">
  <name>Create PSN media service</name>
  <files>lib/core/services/psn_media_service.dart</files>
  <action>
    Create lib/core/services/psn_media_service.dart:
    
    ```dart
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
            options: Options(
              headers: {
                'Authorization': 'Bearer $accessToken',
              },
            ),
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
    ```
  </action>
  <verify>dart analyze lib/core/services/psn_media_service.dart</verify>
  <done>PsnMediaService created with getMediaGallery method</done>
</task>

<task type="auto">
  <name>Create media provider</name>
  <files>lib/features/clips/providers/media_provider.dart</files>
  <action>
    Create lib/features/clips/providers/media_provider.dart:
    
    ```dart
    import 'package:riverpod_annotation/riverpod_annotation.dart';
    import '../../../core/services/psn_media_service.dart';
    import '../../auth/providers/auth_provider.dart';
    import '../data/media_item.dart';
    
    part 'media_provider.g.dart';
    
    /// Media service provider
    @Riverpod(keepAlive: true)
    PsnMediaService psnMediaService(Ref ref) {
      return PsnMediaService();
    }
    
    /// State for paginated media list
    class MediaListState {
      final List<MediaItem> items;
      final String? nextCursor;
      final bool isLoading;
      final String? error;
    
      const MediaListState({
        this.items = const [],
        this.nextCursor,
        this.isLoading = false,
        this.error,
      });
    
      MediaListState copyWith({
        List<MediaItem>? items,
        String? nextCursor,
        bool? isLoading,
        String? error,
      }) {
        return MediaListState(
          items: items ?? this.items,
          nextCursor: nextCursor,
          isLoading: isLoading ?? this.isLoading,
          error: error,
        );
      }
    }
    
    /// Media list notifier with pagination
    @Riverpod(keepAlive: true)
    class MediaList extends _$MediaList {
      @override
      Future<MediaListState> build() async {
        return _fetchInitialPage();
      }
    
      Future<MediaListState> _fetchInitialPage() async {
        final authState = await ref.read(authProvider.future);
        if (authState is! Authenticated) {
          return const MediaListState(error: 'Not authenticated');
        }
    
        try {
          final mediaService = ref.read(psnMediaServiceProvider);
          final response = await mediaService.getMediaGallery(
            accessToken: authState.tokens.accessToken,
          );
    
          return MediaListState(
            items: response.items,
            nextCursor: response.nextCursor,
          );
        } catch (e) {
          return MediaListState(error: e.toString());
        }
      }
    
      /// Load next page
      Future<void> loadMore() async {
        final currentState = state.valueOrNull;
        if (currentState == null ||
            currentState.isLoading ||
            currentState.nextCursor == null) {
          return;
        }
    
        state = AsyncValue.data(currentState.copyWith(isLoading: true));
    
        final authState = await ref.read(authProvider.future);
        if (authState is! Authenticated) return;
    
        try {
          final mediaService = ref.read(psnMediaServiceProvider);
          final response = await mediaService.getMediaGallery(
            accessToken: authState.tokens.accessToken,
            cursor: currentState.nextCursor,
          );
    
          state = AsyncValue.data(MediaListState(
            items: [...currentState.items, ...response.items],
            nextCursor: response.nextCursor,
          ));
        } catch (e) {
          state = AsyncValue.data(
            currentState.copyWith(isLoading: false, error: e.toString()),
          );
        }
      }
    
      /// Refresh from start
      Future<void> refresh() async {
        state = const AsyncValue.loading();
        state = AsyncValue.data(await _fetchInitialPage());
      }
    }
    ```
    
    Run build_runner after creating.
  </action>
  <verify>dart run build_runner build --delete-conflicting-outputs</verify>
  <done>media_provider.dart with pagination support</done>
</task>

## Success Criteria
- [ ] PsnMediaService fetches from PSN API
- [ ] MediaList provider handles pagination
- [ ] Build runner generates provider files
- [ ] `dart analyze lib/` passes
