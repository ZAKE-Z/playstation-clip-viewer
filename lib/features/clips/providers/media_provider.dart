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

/// CloudFront cookies provider - stores cookies from last API call
@Riverpod(keepAlive: true)
class CloudFrontCookiesNotifier extends _$CloudFrontCookiesNotifier {
  @override
  CloudFrontCookies? build() => null;

  void setCookies(CloudFrontCookies? cookies) {
    state = cookies;
  }
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
      final result = await mediaService.getMediaGallery(
        accessToken: authState.tokens.accessToken,
      );

      // Store the CloudFront cookies for image requests
      ref.read(cloudFrontCookiesProvider.notifier).setCookies(result.cookies);

      return MediaListState(
        items: result.response.ugcDocument,
        nextCursor: result.response.nextCursorMark,
      );
    } catch (e) {
      return MediaListState(error: e.toString());
    }
  }

  /// Load next page
  Future<void> loadMore() async {
    final currentState = state.value;
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
      final result = await mediaService.getMediaGallery(
        accessToken: authState.tokens.accessToken,
        cursor: currentState.nextCursor,
      );

      // Update cookies (they may refresh)
      ref.read(cloudFrontCookiesProvider.notifier).setCookies(result.cookies);

      state = AsyncValue.data(
        MediaListState(
          items: [...currentState.items, ...result.response.ugcDocument],
          nextCursor: result.response.nextCursorMark,
        ),
      );
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
