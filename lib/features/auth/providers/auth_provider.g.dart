// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Auth service provider (singleton)

@ProviderFor(psnAuthService)
const psnAuthServiceProvider = PsnAuthServiceProvider._();

/// Auth service provider (singleton)

final class PsnAuthServiceProvider
    extends $FunctionalProvider<PsnAuthService, PsnAuthService, PsnAuthService>
    with $Provider<PsnAuthService> {
  /// Auth service provider (singleton)
  const PsnAuthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'psnAuthServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$psnAuthServiceHash();

  @$internal
  @override
  $ProviderElement<PsnAuthService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PsnAuthService create(Ref ref) {
    return psnAuthService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PsnAuthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PsnAuthService>(value),
    );
  }
}

String _$psnAuthServiceHash() => r'19a751f4c15fdacdebf350b0b21e5aafbf154ff4';

/// Token storage provider (singleton)

@ProviderFor(tokenStorage)
const tokenStorageProvider = TokenStorageProvider._();

/// Token storage provider (singleton)

final class TokenStorageProvider
    extends $FunctionalProvider<TokenStorage, TokenStorage, TokenStorage>
    with $Provider<TokenStorage> {
  /// Token storage provider (singleton)
  const TokenStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tokenStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tokenStorageHash();

  @$internal
  @override
  $ProviderElement<TokenStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TokenStorage create(Ref ref) {
    return tokenStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TokenStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TokenStorage>(value),
    );
  }
}

String _$tokenStorageHash() => r'23b0f4fbc323ec56119e50446aeaa2c5e3abe772';

/// Auth state notifier

@ProviderFor(Auth)
const authProvider = AuthProvider._();

/// Auth state notifier
final class AuthProvider extends $AsyncNotifierProvider<Auth, AuthState> {
  /// Auth state notifier
  const AuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authHash();

  @$internal
  @override
  Auth create() => Auth();
}

String _$authHash() => r'dfd3d477d68801d2bacf4191bfb47529cca12c4c';

/// Auth state notifier

abstract class _$Auth extends $AsyncNotifier<AuthState> {
  FutureOr<AuthState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<AuthState>, AuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AuthState>, AuthState>,
              AsyncValue<AuthState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
