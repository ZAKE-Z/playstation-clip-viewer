---
phase: 2
plan: 1
wave: 1
---

# Plan 2.1: Auth Logic Verification

## Objective
Implement unit tests for `PsnAuthService` to verify the core authentication flow (NPSSO -> Code -> Tokens) and error handling, mocking the API responses.

## Context
- .gsd/SPEC.md
- lib/core/services/psn_auth_service.dart
- test/mocks/mock_definitions.dart

## Tasks

<task type="auto">
  <name>Test NPSSO Exchange</name>
  <files>test/core/services/psn_auth_service_test.dart</files>
  <action>
    Create `test/core/services/psn_auth_service_test.dart`.
    Implement test `getCodeFromNpsso returns code on success`:
    - Mock `Dio.get` to return 302 with `location: com.scee.psxandroid.scecompcall://redirect?code=12345`
    - Verify method returns `12345`.
  </action>
  <verify>flutter test test/core/services/psn_auth_service_test.dart --plain-name "getCodeFromNpsso returns code"</verify>
  <done>Test passes</done>
</task>

<task type="auto">
  <name>Test Token Exchange</name>
  <files>test/core/services/psn_auth_service_test.dart</files>
  <action>
    Append test `getTokensFromCode returns valid tokens`:
    - Mock `Dio.post` to return 200 with standard JSON (access_token, refresh_token, expires_in).
    - Verify `tokenStorage.saveTokens` is called.
    - Verify returned `PsnTokens` object matches mocked data.
  </action>
  <verify>flutter test test/core/services/psn_auth_service_test.dart --plain-name "getTokensFromCode returns valid tokens"</verify>
  <done>Test passes</done>
</task>

<task type="auto">
  <name>Test Error Handling</name>
  <files>test/core/services/psn_auth_service_test.dart</files>
  <action>
    Append tests for failure scenarios:
    - `getCodeFromNpsso throws on invalid redirect` (missing code)
    - `getCodeFromNpsso throws on network error` (DioException)
    - `getTokensFromCode throws on API error` (400 Bad Request)
  </action>
  <verify>flutter test test/core/services/psn_auth_service_test.dart</verify>
  <done>All error tests pass</done>
</task>

## Success Criteria
- [ ] `flutter test test/core/services/psn_auth_service_test.dart` passes all tests
- [ ] Core auth flow (NPSSO->Code->Tokens) is verified with mocks
