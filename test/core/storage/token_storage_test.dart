import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:psclips/core/storage/token_storage.dart';
import 'package:psclips/features/auth/data/token_model.dart';

import '../../mocks/mock_definitions.mocks.dart';

void main() {
  late TokenStorage tokenStorage;
  late MockFlutterSecureStorage mockSecureStorage;
  const key = 'psn_tokens';

  final testTokens = PsnTokens(
    accessToken: 'access_123',
    refreshToken: 'refresh_123',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
    refreshExpiresAt: DateTime.now().add(const Duration(days: 60)),
  );

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    tokenStorage = TokenStorage(storage: mockSecureStorage);
  });

  group('TokenStorage', () {
    test('saveTokens writes JSON to storage', () async {
      await tokenStorage.saveTokens(testTokens);

      verify(
        mockSecureStorage.write(key: key, value: anyNamed('value')),
      ).called(1);
    });

    test('loadTokens returns tokens when JSON is valid', () async {
      // Arrange
      // We manually construct a JSON string that matches what PsnTokens.toJson() would produce
      // But we can just use the actual model to simplify
      final jsonString =
          '{"accessToken":"access_123","refreshToken":"refresh_123","expiresAt":"${testTokens.expiresAt.toIso8601String()}","refreshExpiresAt":"${testTokens.refreshExpiresAt.toIso8601String()}"}';

      when(
        mockSecureStorage.read(key: key),
      ).thenAnswer((_) async => jsonString);

      // Act
      final result = await tokenStorage.loadTokens();

      // Assert
      expect(result, isNotNull);
      expect(result!.accessToken, testTokens.accessToken);
    });

    test(
      'loadTokens clears storage and returns null on invalid JSON',
      () async {
        when(
          mockSecureStorage.read(key: key),
        ).thenAnswer((_) async => 'INVALID_JSON_BLOB');

        final result = await tokenStorage.loadTokens();

        expect(result, isNull);
        verify(mockSecureStorage.delete(key: key)).called(1);
      },
    );

    test('loadTokens returns null when storage is empty', () async {
      when(mockSecureStorage.read(key: key)).thenAnswer((_) async => null);

      final result = await tokenStorage.loadTokens();

      expect(result, isNull);
    });

    test('clearTokens deletes from storage', () async {
      await tokenStorage.clearTokens();
      verify(mockSecureStorage.delete(key: key)).called(1);
    });
  });
}
