
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:psclips/core/services/psn_auth_service.dart';

import 'package:psclips/features/auth/data/token_model.dart';

import '../../mocks/mock_definitions.mocks.dart';

void main() {
  late PsnAuthService authService;
  late MockDio mockDio;
  late MockTokenStorage mockTokenStorage;
  late MockLoggerService mockLogger;

  final testTokens = PsnTokens(
    accessToken: 'access_123',
    refreshToken: 'refresh_123',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
    refreshExpiresAt: DateTime.now().add(const Duration(days: 60)),
  );

  setUp(() {
    mockDio = MockDio();
    mockTokenStorage = MockTokenStorage();
    mockLogger = MockLoggerService();
    authService = PsnAuthService(
      dio: mockDio,
      tokenStorage: mockTokenStorage,
      logger: mockLogger,
    );
  });

  group('PsnAuthService.getCodeFromNpsso', () {
    const npsso = 'test_npsso_token';
    const authCode = 'v3.MqVHAS';
    const redirectUrl =
        'com.scee.psxandroid.scecompcall://redirect/?code=$authCode&cid=ffbc624d-9131-4e2b-b662-738b04052ca1';

    test('getCodeFromNpsso returns code on success', () async {
      // Arrange
      when(
        mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 302,
          headers: Headers.fromMap({
            'location': [redirectUrl],
          }),
        ),
      );

      // Act
      final result = await authService.getCodeFromNpsso(npsso);

      // Assert
      expect(result, authCode);
      verify(
        mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        ),
      ).called(1);
    });
  });

  group('PsnAuthService.getTokensFromCode', () {
    const code = 'auth_code_123';
    const accessToken = 'access_123';
    const refreshToken = 'refresh_123';
    const expiresIn = 3600;

    test('getTokensFromCode returns valid tokens', () async {
      // Arrange
      when(
        mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: {
            'access_token': accessToken,
            'refresh_token': refreshToken,
            'expires_in': expiresIn,
            'refresh_token_expires_in': expiresIn * 2,
          },
        ),
      );

      // Act
      final result = await authService.getTokensFromCode(code);

      // Assert
      expect(result.accessToken, accessToken);
      expect(result.refreshToken, refreshToken);
      // Verify expires_in conversion (allow 1s delta for execution time)
      final expectedExpiry = DateTime.now().add(Duration(seconds: expiresIn));
      expect(
        result.expiresAt.difference(expectedExpiry).inSeconds.abs(),
        lessThanOrEqualTo(1),
      );
      verify(mockTokenStorage.saveTokens(any)).called(1);
    });
  });

  group('PsnAuthService Error Handling', () {
    test('getCodeFromNpsso throws on network error', () async {
      when(
        mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          message: 'Network error',
        ),
      );

      expect(
        () => authService.getCodeFromNpsso('test_npsso'),
        throwsA(isA<PsnAuthException>()),
      );
    });

    test('getTokensFromCode throws on API error', () async {
      when(
        mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
          ),
        ),
      );

      expect(
        () => authService.getTokensFromCode('bad_code'),
        throwsA(isA<PsnAuthException>()),
      );
    });
  });

  group('PsnAuthService.getValidTokens', () {
    test('returns tokens directly if valid', () async {
      when(mockTokenStorage.loadTokens()).thenAnswer((_) async => testTokens);

      final result = await authService.getValidTokens();

      expect(result, testTokens);
      verifyZeroInteractions(mockDio);
    });

    test('refreshes if access token is expired', () async {
      final expiredTokens = testTokens.copyWith(
        expiresAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      when(
        mockTokenStorage.loadTokens(),
      ).thenAnswer((_) async => expiredTokens);

      when(
        mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: {
            'access_token': 'new_access',
            'refresh_token': 'new_refresh',
            'expires_in': 3600,
            'refresh_token_expires_in': 3600 * 24,
          },
        ),
      );

      final result = await authService.getValidTokens();

      expect(result?.accessToken, 'new_access');
      expect(result?.refreshToken, 'new_refresh');
      verify(mockTokenStorage.saveTokens(any)).called(1);
    });

    test('clears tokens if refresh token is expired', () async {
      final oldRefreshTokens = testTokens.copyWith(
        refreshExpiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      when(
        mockTokenStorage.loadTokens(),
      ).thenAnswer((_) async => oldRefreshTokens);

      final result = await authService.getValidTokens();

      expect(result, isNull);
      verify(mockTokenStorage.clearTokens()).called(1);
    });

    test('clears tokens if refresh returns 401', () async {
      final expiredTokens = testTokens.copyWith(
        expiresAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      when(
        mockTokenStorage.loadTokens(),
      ).thenAnswer((_) async => expiredTokens);

      when(
        mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 401,
          ),
        ),
      );

      final result = await authService.getValidTokens();

      expect(result, isNull);
      verify(mockTokenStorage.clearTokens()).called(1);
    });
    test('clears tokens if refresh returns 403', () async {
      final expiredTokens = testTokens.copyWith(
        expiresAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      when(
        mockTokenStorage.loadTokens(),
      ).thenAnswer((_) async => expiredTokens);

      when(
        mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 403,
          ),
        ),
      );

      final result = await authService.getValidTokens();

      expect(result, isNull);
      verify(mockTokenStorage.clearTokens()).called(1);
    });

    test('rethrows error if refresh fails with network error', () async {
      final expiredTokens = testTokens.copyWith(
        expiresAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      when(
        mockTokenStorage.loadTokens(),
      ).thenAnswer((_) async => expiredTokens);

      when(
        mockDio.post(any, data: anyNamed('data'), options: anyNamed('options')),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '')));

      expect(
        () => authService.getValidTokens(),
        throwsA(isA<PsnAuthException>()),
      );
      verifyNever(mockTokenStorage.clearTokens());
    });
  });
}
