// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(uploadConfigStorage)
const uploadConfigStorageProvider = UploadConfigStorageProvider._();

final class UploadConfigStorageProvider
    extends $FunctionalProvider<UploadConfigStorage, UploadConfigStorage,
        UploadConfigStorage> with $Provider<UploadConfigStorage> {
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
  $ProviderElement<UploadConfigStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UploadConfigStorage create(Ref ref) {
    return uploadConfigStorage(ref);
  }

  Override overrideWithValue(UploadConfigStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UploadConfigStorage>(value),
    );
  }
}

String _$uploadConfigStorageHash() => r'upload_config_storage';

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

String _$uploadConfigNotifierHash() => r'upload_config_notifier';

abstract class _$UploadConfigNotifier extends $AsyncNotifier<UploadConfig?> {
  FutureOr<UploadConfig?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<UploadConfig?>, UploadConfig?>;
    final element = ref.element
        as $ClassProviderElement<
            AnyNotifier<AsyncValue<UploadConfig?>, UploadConfig?>,
            AsyncValue<UploadConfig?>,
            Object?,
            Object?>;
    element.handleValue(ref, created);
  }
}
