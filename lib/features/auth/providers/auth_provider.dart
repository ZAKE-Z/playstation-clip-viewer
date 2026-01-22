import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/services/psn_auth_service.dart';
import '../../../core/storage/token_storage.dart';
import '../presentation/psn_login_webview.dart';
import '../data/token_model.dart';

part 'auth_provider.g.dart';

/// Auth state: loading, authenticated, or unauthenticated
sealed class AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final PsnTokens tokens;
  Authenticated(this.tokens);
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

/// Auth service provider (singleton)
@Riverpod(keepAlive: true)
PsnAuthService psnAuthService(Ref ref) {
  return PsnAuthService();
}

/// Token storage provider (singleton)
@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) {
  return TokenStorage();
}

/// Auth state notifier
@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  Future<AuthState> build() async {
    final authService = ref.read(psnAuthServiceProvider);

    // Try to load existing valid tokens
    final tokens = await authService.getValidTokens();
    if (tokens != null) {
      return Authenticated(tokens);
    }
    return Unauthenticated();
  }

  /// Authenticate with NPSSO (called after WebView login in Phase 2)
  Future<void> authenticateWithNpsso(String npsso) async {
    state = const AsyncValue.loading();

    try {
      final authService = ref.read(psnAuthServiceProvider);
      final tokens = await authService.authenticateWithNpsso(npsso);
      state = AsyncValue.data(Authenticated(tokens));
    } on PsnAuthException catch (e) {
      state = AsyncValue.data(AuthError(e.message));
    }
  }

  /// Logout
  Future<void> logout() async {
    // Clear server-side session and webview data
    await PsnLoginWebview.logout();

    final authService = ref.read(psnAuthServiceProvider);
    await authService.logout();
    state = AsyncValue.data(Unauthenticated());
  }
}
