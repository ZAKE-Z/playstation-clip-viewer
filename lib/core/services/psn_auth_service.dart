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

  PsnAuthService({Dio? dio, TokenStorage? tokenStorage})
    : _dio = dio ?? Dio(),
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
            'Authorization':
                'Basic MDk1MTUxNTktNzIzNy00MzcwLTliNDAtMzgwNmU2N2MwODkxOnVjUGprYTV0bnRCMktxc1A=',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final now = DateTime.now();

      final tokens = PsnTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        expiresAt: now.add(Duration(seconds: data['expires_in'] as int)),
        refreshExpiresAt: now.add(
          Duration(seconds: data['refresh_token_expires_in'] as int),
        ),
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
          'token_format': 'jwt',
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
          'scope': PsnApi.scopes,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Authorization':
                'Basic MDk1MTUxNTktNzIzNy00MzcwLTliNDAtMzgwNmU2N2MwODkxOnVjUGprYTV0bnRCMktxc1A=',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final now = DateTime.now();

      final tokens = PsnTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        expiresAt: now.add(Duration(seconds: data['expires_in'] as int)),
        refreshExpiresAt: now.add(
          Duration(seconds: data['refresh_token_expires_in'] as int),
        ),
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
