---
phase: 3
plan: 1
wave: 1
---

# Plan 3.1: Token Verification & Lifecycle

## Objective
Implement comprehensive unit tests for `TokenStorage` and the auto-refresh logic in `PsnAuthService`. This ensures that user sessions are persisted correctly and securely refreshed when expired, handling the "happy path" and potential failures/rollbacks.

## Context
- .gsd/SPEC.md
- lib/core/storage/token_storage.dart
- lib/core/services/psn_auth_service.dart
- test/mocks/mock_definitions.dart

## Tasks

<task type="auto">
  <name>Test TokenStorage</name>
  <files>test/core/storage/token_storage_test.dart</files>
  <action>
    Create `test/core/storage/token_storage_test.dart`.
    Implement tests for:
    - `saveTokens`: Verifies serialization and call to `FlutterSecureStorage.write`.
    - `loadTokens`: Verifies deserialization from valid JSON.
    - `loadTokens` (Corrupt): Verifies that invalid JSON triggers `clearTokens` and returns null.
    - `clearTokens`: Verifies call to `FlutterSecureStorage.delete`.
  </action>
  <verify>flutter test test/core/storage/token_storage_test.dart</verify>
  <done>All storage operations verified with mocks</done>
</task>

<task type="auto">
  <name>Test Auto-Refresh Logic</name>
  <files>test/core/services/psn_auth_service_test.dart</files>
  <action>
    Append `group('PsnAuthService.getValidTokens')` to the existing test file:
    - `returns tokens if valid`: Mock storage returning young tokens. Verify no network call.
    - `refreshes if access token expired`: Mock storage returning old access token. Mock Dio refresh response. Verify `refreshTokens` called.
    - `clears tokens if refresh token expired`: Mock storage returning old refresh token. Verify `clearTokens` called.
    - `clears tokens if refresh fails`: Mock refresh API failure. Verify `clearTokens` called.
  </action>
  <verify>flutter test test/core/services/psn_auth_service_test.dart --plain-name "PsnAuthService.getValidTokens"</verify>
  <done>Lifecycle logic verified</done>
</task>

## Success Criteria
- [ ] Token persistence is verified against `FlutterSecureStorage` mocks
- [ ] Application correctly handles expired sessions (both access and refresh)
- [ ] Application correctly recovers logic (refresh) vs. fails safe (logout)
