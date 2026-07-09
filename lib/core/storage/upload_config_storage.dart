import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/upload/data/upload_config.dart';

/// Secure storage for upload config (ShareX-style). Same pattern as TokenStorage.
class UploadConfigStorage {
  static const _key = 'upload_config';

  final FlutterSecureStorage _storage;

  UploadConfigStorage({FlutterSecureStorage? storage})
      : _storage =
            storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  Future<void> saveConfig(UploadConfig config) async {
    await _storage.write(key: _key, value: jsonEncode(config.toJson()));
  }

  Future<UploadConfig?> loadConfig() async {
    final json = await _storage.read(key: _key);
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return UploadConfig.fromJson(map);
    } catch (_) {
      await clearConfig();
      return null;
    }
  }

  Future<void> clearConfig() async {
    await _storage.delete(key: _key);
  }

  Future<bool> hasConfig() async {
    return _storage.containsKey(key: _key);
  }
}
