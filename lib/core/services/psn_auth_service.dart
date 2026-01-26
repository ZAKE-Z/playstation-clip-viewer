import 'package:dio/dio.dart';
import '../constants/psn_api.dart';
import '../storage/token_storage.dart';
import '../../features/auth/data/token_model.dart';
import 'logger_service.dart';

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
  final LoggerService _logger;

  PsnAuthService({Dio? dio, TokenStorage? tokenStorage, LoggerService? logger})
    : _dio = dio ?? Dio(),
      _tokenStorage = tokenStorage ?? TokenStorage(),
      _logger = logger ?? LoggerService();

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
    } on DioException catch (e, stack) {
      final msg = 'Network error during NPSSO exchange: ${e.message}';
      _logger.logError(msg, e, stack);
      throw PsnAuthException(msg, statusCode: e.response?.statusCode);
    } catch (e, stack) {
      _logger.logError('Unexpected error during NPSSO exchange', e, stack);
      rethrow;
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
    } on DioException catch (e, stack) {
      final msg = 'Token exchange failed: ${e.message}';
      _logger.logError(msg, e, stack);
      throw PsnAuthException(msg, statusCode: e.response?.statusCode);
    } catch (e, stack) {
      _logger.logError('Unexpected error during token exchange', e, stack);
      rethrow;
    }
  }

  /// Refresh tokens using refresh token
  Future<PsnTokens> refreshTokens(String refreshToken) async {
    try {
      _logger.logError(
        'Attempting to refresh tokens...',
      ); // Info log disguised as error for now to ensure we see it
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
    } on DioException catch (e, stack) {
      final msg =
          'Token refresh failed: ${e.message} (Status: ${e.response?.statusCode})';
      _logger.logError(msg, e, stack);
      throw PsnAuthException(msg, statusCode: e.response?.statusCode);
    } catch (e, stack) {
      _logger.logError('Unexpected error during token refresh', e, stack);
      rethrow;
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
      _logger.logError('Refresh token expired. Clearing tokens.');
      await _tokenStorage.clearTokens();
      return null;
    }

    // Check if access token needs refresh (proactive, 80% TTL)
    if (tokens.needsRefresh || tokens.isExpired) {
      try {
        return await refreshTokens(tokens.refreshToken);
      } on PsnAuthException catch (e) {
        // Only clear tokens if the server explicitly rejected the refresh token (400/401)
        if (e.statusCode == 400 || e.statusCode == 401 || e.statusCode == 403) {
          _logger.logError(
            'Refresh rejected (${e.statusCode}). Clearing tokens.',
          );
          await _tokenStorage.clearTokens();
          return null;
        }
        // Otherwise (Network error, etc.), rethrow to preserve session
        _logger.logError('Refresh failed but session preserved: ${e.message}');
        rethrow;
      } catch (e, stack) {
        // Unknown error, rethrow
        _logger.logError('Unknown error checking tokens', e, stack);
        rethrow;
      }
    }

    return tokens;
  }

  /// Logout - clear stored tokens
  Future<void> logout() async {
    _logger.logError('Logging out user.');
    await _tokenStorage.clearTokens();
  }
}
