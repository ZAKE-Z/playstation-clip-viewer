import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:psclips/core/services/psn_auth_service.dart';

import '../../mocks/mock_definitions.mocks.dart';

void main() {
  late PsnAuthService authService;
  late MockDio mockDio;
  late MockTokenStorage mockTokenStorage;

  setUp(() {
    mockDio = MockDio();
    mockTokenStorage = MockTokenStorage();
    authService = PsnAuthService(dio: mockDio, tokenStorage: mockTokenStorage);
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
}
