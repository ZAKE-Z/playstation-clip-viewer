---
phase: 1
plan: 3
wave: 2
---

# Plan 1.3: Token Models & Secure Storage

## Objective
Create the token data models and secure storage service. This is foundational for the auth service in Plan 1.4.

## Context
- .gsd/DECISIONS.md (ADR-004: Proactive token refresh)
- lib/core/constants/psn_api.dart
- pubspec.yaml (flutter_secure_storage, freezed)

## Tasks

<task type="auto">
  <name>Create token models with Freezed</name>
  <files>lib/features/auth/data/token_model.dart</files>
  <action>
    Create lib/features/auth/data/token_model.dart:
    
    ```dart
    import 'package:freezed_annotation/freezed_annotation.dart';
    
    part 'token_model.freezed.dart';
    part 'token_model.g.dart';
    
    /// PSN OAuth tokens with expiration tracking
    @freezed
    class PsnTokens with _$PsnTokens {
      const factory PsnTokens({
        required String accessToken,
        required String refreshToken,
        required DateTime expiresAt,
        required DateTime refreshExpiresAt,
      }) = _PsnTokens;
      
      factory PsnTokens.fromJson(Map<String, dynamic> json) => 
          _$PsnTokensFromJson(json);
    }
    
    /// Extension for token expiration checks
    extension PsnTokensX on PsnTokens {
      /// Check if access token needs refresh (80% of TTL elapsed)
      bool get needsRefresh {
        final now = DateTime.now();
        final totalDuration = expiresAt.difference(refreshExpiresAt.subtract(
          Duration(hours: 1), // refresh token lasts longer
        ));
        final threshold = expiresAt.subtract(
          Duration(seconds: (totalDuration.inSeconds * 0.2).round()),
        );
        return now.isAfter(threshold);
      }
      
      /// Check if access token is expired
      bool get isExpired => DateTime.now().isAfter(expiresAt);
      
      /// Check if refresh token is expired
      bool get isRefreshExpired => DateTime.now().isAfter(refreshExpiresAt);
    }
    ```
    
    Run `dart run build_runner build` to generate freezed files.
  </action>
  <verify>dart run build_runner build --delete-conflicting-outputs</verify>
  <done>token_model.freezed.dart and token_model.g.dart generated successfully</done>
</task>

<task type="auto">
  <name>Create secure token storage service</name>
  <files>lib/core/storage/token_storage.dart</files>
  <action>
    Create lib/core/storage/token_storage.dart:
    
    ```dart
    import 'dart:convert';
    import 'package:flutter_secure_storage/flutter_secure_storage.dart';
    import '../../features/auth/data/token_model.dart';
    
    /// Secure storage for PSN tokens
    class TokenStorage {
      static const _key = 'psn_tokens';
      
      final FlutterSecureStorage _storage;
      
      TokenStorage({FlutterSecureStorage? storage})
          : _storage = storage ?? const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
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
    ```
  </action>
  <verify>dart analyze lib/core/storage/token_storage.dart</verify>
  <done>token_storage.dart exists and passes dart analyze</done>
</task>

## Success Criteria
- [ ] token_model.dart with PsnTokens freezed class
- [ ] Generated files: token_model.freezed.dart, token_model.g.dart
- [ ] token_storage.dart with save/load/clear methods
- [ ] All files pass `dart analyze`
