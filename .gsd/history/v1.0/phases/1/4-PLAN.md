---
phase: 1
plan: 4
wave: 2
---

# Plan 1.4: PSN Auth Service

## Objective
Implement the PSN authentication service with the full OAuth flow: NPSSO → code → tokens, plus token refresh. This is the core business logic that Phase 2 will wire to the UI.

## Context
- .gsd/SPEC.md (auth flow requirements)
- .gsd/DECISIONS.md (ADR-004: Proactive refresh, ADR-005: Service layer in Phase 1)
- lib/core/constants/psn_api.dart
- lib/core/storage/token_storage.dart
- lib/features/auth/data/token_model.dart
- Reference: j:\Projects\psn-clips\info.md (original auth flow documentation)

## Tasks

<task type="auto">
  <name>Create PSN auth service</name>
  <files>lib/core/services/psn_auth_service.dart</files>
  <action>
    Create lib/core/services/psn_auth_service.dart with the full auth flow:
    
    ```dart
    import 'package:dio/dio.dart';
    import '../constants/psn_api.dart';
    import '../storage/token_storage.dart';
    import '../../features/auth/data/token_model.dart';
    
    /// Exception for PSN auth errors
    class PsnAuthException implements Exception {
      final String message;
      final int? statusCode;
      
      PsnAuthException(this.message, {this.statusCode});
      
      @override
      String toString() => 'PsnAuthException: $message';
    }
    
    /// PSN OAuth authentication service
    class PsnAuthService {
      final Dio _dio;
      final TokenStorage _tokenStorage;
      
      PsnAuthService({
        Dio? dio,
        TokenStorage? tokenStorage,
      })  : _dio = dio ?? Dio(),
            _tokenStorage = tokenStorage ?? TokenStorage();
      
      /// Exchange NPSSO token for OAuth code
      /// Returns the authorization code from the redirect URL
      Future<String> getCodeFromNpsso(String npsso) async {
        try {
          final response = await _dio.get(
            '${PsnApi.oauthBaseUrl}/authorize',
            queryParameters: {
              'access_type': 'offline',
              'client_id': PsnApi.clientId,
              'redirect_uri': PsnApi.redirectUri,
              'response_type': 'code',
              'scope': PsnApi.scopes,
            },
            options: Options(
              headers: {'Cookie': 'npsso=$npsso'},
              followRedirects: false,
              validateStatus: (status) => status == 302,
            ),
          );
          
          final location = response.headers['location']?.first;
          if (location == null || !location.contains('code=')) {
            throw PsnAuthException(
              'Invalid NPSSO token or redirect failed',
              statusCode: response.statusCode,
            );
          }
          
          // Extract code from: com.scee.psxandroid.scecompcall://redirect?code=XXX&...
          final uri = Uri.parse(location);
          final code = uri.queryParameters['code'];
          if (code == null) {
            throw PsnAuthException('No code in redirect URL');
          }
          
          return code;
        } on DioException catch (e) {
          throw PsnAuthException(
            'Network error: ${e.message}',
            statusCode: e.response?.statusCode,
          );
        }
      }
      
      /// Exchange authorization code for access and refresh tokens
      Future<PsnTokens> getTokensFromCode(String code) async {
        try {
          final response = await _dio.post(
            '${PsnApi.oauthBaseUrl}/token',
            data: {
              'code': code,
              'grant_type': 'authorization_code',
              'redirect_uri': PsnApi.redirectUri,
            },
            options: Options(
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Authorization': 'Basic MDk1MTUxNTktNzIzNy00MzcwLTliNDAtMzgwNmU2N2MwODkxOnVjUGprYTV0bnRCMktxc1A=',
              },
            ),
          );
          
          final data = response.data as Map<String, dynamic>;
          final now = DateTime.now();
          
          final tokens = PsnTokens(
            accessToken: data['access_token'] as String,
            refreshToken: data['refresh_token'] as String,
            expiresAt: now.add(Duration(seconds: data['expires_in'] as int)),
            refreshExpiresAt: now.add(Duration(seconds: data['refresh_token_expires_in'] as int)),
          );
          
          await _tokenStorage.saveTokens(tokens);
          return tokens;
        } on DioException catch (e) {
          throw PsnAuthException(
            'Token exchange failed: ${e.message}',
            statusCode: e.response?.statusCode,
          );
        }
      }
      
      /// Refresh tokens using refresh token
      Future<PsnTokens> refreshTokens(String refreshToken) async {
        try {
          final response = await _dio.post(
            '${PsnApi.oauthBaseUrl}/token',
            data: {
              'refresh_token': refreshToken,
              'grant_type': 'refresh_token',
              'scope': PsnApi.scopes,
            },
            options: Options(
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Authorization': 'Basic MDk1MTUxNTktNzIzNy00MzcwLTliNDAtMzgwNmU2N2MwODkxOnVjUGprYTV0bnRCMktxc1A=',
              },
            ),
          );
          
          final data = response.data as Map<String, dynamic>;
          final now = DateTime.now();
          
          final tokens = PsnTokens(
            accessToken: data['access_token'] as String,
            refreshToken: data['refresh_token'] as String,
            expiresAt: now.add(Duration(seconds: data['expires_in'] as int)),
            refreshExpiresAt: now.add(Duration(seconds: data['refresh_token_expires_in'] as int)),
          );
          
          await _tokenStorage.saveTokens(tokens);
          return tokens;
        } on DioException catch (e) {
          throw PsnAuthException(
            'Token refresh failed: ${e.message}',
            statusCode: e.response?.statusCode,
          );
        }
      }
      
      /// Full auth flow: NPSSO -> code -> tokens
      Future<PsnTokens> authenticateWithNpsso(String npsso) async {
        final code = await getCodeFromNpsso(npsso);
        return await getTokensFromCode(code);
      }
      
      /// Get valid tokens, refreshing if needed
      Future<PsnTokens?> getValidTokens() async {
        final tokens = await _tokenStorage.loadTokens();
        if (tokens == null) return null;
        
        // Check if refresh token is expired
        if (tokens.isRefreshExpired) {
          await _tokenStorage.clearTokens();
          return null;
        }
        
        // Check if access token needs refresh (proactive, 80% TTL)
        if (tokens.needsRefresh || tokens.isExpired) {
          try {
            return await refreshTokens(tokens.refreshToken);
          } catch (e) {
            // Refresh failed, clear tokens
            await _tokenStorage.clearTokens();
            return null;
          }
        }
        
        return tokens;
      }
      
      /// Logout - clear stored tokens
      Future<void> logout() async {
        await _tokenStorage.clearTokens();
      }
    }
    ```
    
    Note: The Authorization header is the Base64-encoded client_id:client_secret.
    The client secret was extracted from the PlayStation app.
  </action>
  <verify>dart analyze lib/core/services/psn_auth_service.dart</verify>
  <done>psn_auth_service.dart exists with full auth flow, passes dart analyze</done>
</task>

<task type="auto">
  <name>Create auth state provider</name>
  <files>lib/features/auth/providers/auth_provider.dart</files>
  <action>
    Create lib/features/auth/providers/auth_provider.dart:
    
    ```dart
    import 'package:riverpod_annotation/riverpod_annotation.dart';
    import '../../../core/services/psn_auth_service.dart';
    import '../../../core/storage/token_storage.dart';
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
    PsnAuthService psnAuthService(PsnAuthServiceRef ref) {
      return PsnAuthService();
    }
    
    /// Token storage provider (singleton)
    @Riverpod(keepAlive: true)
    TokenStorage tokenStorage(TokenStorageRef ref) {
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
        final authService = ref.read(psnAuthServiceProvider);
        await authService.logout();
        state = const AsyncValue.data(Unauthenticated());
      }
    }
    ```
    
    Run `dart run build_runner build` to generate provider files.
  </action>
  <verify>dart run build_runner build --delete-conflicting-outputs</verify>
  <done>auth_provider.dart exists, auth_provider.g.dart generated successfully</done>
</task>

## Success Criteria
- [ ] psn_auth_service.dart with full OAuth flow
- [ ] auth_provider.dart with AuthState sealed class
- [ ] Generated: auth_provider.g.dart
- [ ] All files pass `dart analyze`
- [ ] App builds: `flutter build windows --debug`
