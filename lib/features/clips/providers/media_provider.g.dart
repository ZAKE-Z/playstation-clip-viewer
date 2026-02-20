// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Media service provider

@ProviderFor(psnMediaService)
const psnMediaServiceProvider = PsnMediaServiceProvider._();

/// Media service provider

final class PsnMediaServiceProvider
    extends
        $FunctionalProvider<PsnMediaService, PsnMediaService, PsnMediaService>
    with $Provider<PsnMediaService> {
  /// Media service provider
  const PsnMediaServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'psnMediaServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$psnMediaServiceHash();

  @$internal
  @override
  $ProviderElement<PsnMediaService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PsnMediaService create(Ref ref) {
    return psnMediaService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PsnMediaService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PsnMediaService>(value),
    );
  }
}

String _$psnMediaServiceHash() => r'a793b48fe39b8dc06a70a5e0b0fdf63589e5bf73';

/// CloudFront cookies provider - stores cookies from last API call

@ProviderFor(CloudFrontCookiesNotifier)
const cloudFrontCookiesProvider = CloudFrontCookiesNotifierProvider._();

/// CloudFront cookies provider - stores cookies from last API call
final class CloudFrontCookiesNotifierProvider
    extends $NotifierProvider<CloudFrontCookiesNotifier, CloudFrontCookies?> {
  /// CloudFront cookies provider - stores cookies from last API call
  const CloudFrontCookiesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudFrontCookiesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cloudFrontCookiesNotifierHash();

  @$internal
  @override
  CloudFrontCookiesNotifier create() => CloudFrontCookiesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CloudFrontCookies? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CloudFrontCookies?>(value),
    );
  }
}

String _$cloudFrontCookiesNotifierHash() =>
    r'83d8114db58e069a662a7511ab2531b5a3484448';

/// CloudFront cookies provider - stores cookies from last API call

abstract class _$CloudFrontCookiesNotifier
    extends $Notifier<CloudFrontCookies?> {
  CloudFrontCookies? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<CloudFrontCookies?, CloudFrontCookies?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CloudFrontCookies?, CloudFrontCookies?>,
              CloudFrontCookies?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Media list notifier with pagination

@ProviderFor(MediaList)
const mediaListProvider = MediaListProvider._();

/// Media list notifier with pagination
final class MediaListProvider
    extends $AsyncNotifierProvider<MediaList, MediaListState> {
  /// Media list notifier with pagination
  const MediaListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaListHash();

  @$internal
  @override
  MediaList create() => MediaList();
}

String _$mediaListHash() => r'2891b532dfe1d2e045d9a2b2e88180e1f6150083';

/// Media list notifier with pagination

abstract class _$MediaList extends $AsyncNotifier<MediaListState> {
  FutureOr<MediaListState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<MediaListState>, MediaListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MediaListState>, MediaListState>,
              AsyncValue<MediaListState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
