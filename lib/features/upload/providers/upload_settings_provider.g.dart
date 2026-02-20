// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(uploadConfigStorage)
const uploadConfigStorageProvider = UploadConfigStorageProvider._();

final class UploadConfigStorageProvider
    extends
        $FunctionalProvider<
          UploadConfigStorage,
          UploadConfigStorage,
          UploadConfigStorage
        >
    with $Provider<UploadConfigStorage> {
  const UploadConfigStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uploadConfigStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uploadConfigStorageHash();

  @$internal
  @override
  $ProviderElement<UploadConfigStorage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UploadConfigStorage create(Ref ref) {
    return uploadConfigStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UploadConfigStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UploadConfigStorage>(value),
    );
  }
}

String _$uploadConfigStorageHash() =>
    r'e33b325fbf82c5707c30d3bd92b63dedd112452c';

@ProviderFor(UploadConfigNotifier)
const uploadConfigProvider = UploadConfigNotifierProvider._();

final class UploadConfigNotifierProvider
    extends $AsyncNotifierProvider<UploadConfigNotifier, UploadConfig?> {
  const UploadConfigNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uploadConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uploadConfigNotifierHash();

  @$internal
  @override
  UploadConfigNotifier create() => UploadConfigNotifier();
}

String _$uploadConfigNotifierHash() =>
    r'7025e382e302e8ad29805d759a2364cdbbc350b5';

abstract class _$UploadConfigNotifier extends $AsyncNotifier<UploadConfig?> {
  FutureOr<UploadConfig?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<UploadConfig?>, UploadConfig?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UploadConfig?>, UploadConfig?>,
              AsyncValue<UploadConfig?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
