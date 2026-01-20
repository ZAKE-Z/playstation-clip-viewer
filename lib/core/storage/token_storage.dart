import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/data/token_model.dart';

/// Secure storage for PSN tokens
class TokenStorage {
  static const _key = 'psn_tokens';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  /// Save tokens to secure storage
  Future<void> saveTokens(PsnTokens tokens) async {
    final json = jsonEncode(tokens.toJson());
    await _storage.write(key: _key, value: json);
  }

  /// Load tokens from secure storage
  Future<PsnTokens?> loadTokens() async {
    final json = await _storage.read(key: _key);
    if (json == null) return null;

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return PsnTokens.fromJson(map);
    } catch (e) {
      // Invalid stored data, clear it
      await clearTokens();
      return null;
    }
  }

  /// Clear tokens (logout)
  Future<void> clearTokens() async {
    await _storage.delete(key: _key);
  }

  /// Check if tokens exist
  Future<bool> hasTokens() async {
    return await _storage.containsKey(key: _key);
  }
}
