# Summary: Phase 2.1

## Accomplishments
- [x] Implemented `test/core/services/psn_auth_service_test.dart`
- [x] Verified **NPSSO Exchange** logic (mocked 302 redirect)
- [x] Verified **Token Exchange** logic (mocked 200 JSON response)
- [x] Verified **Error Handling** (Network errors, 400 Bad Request)

## Test Results
- ✅ `getCodeFromNpsso returns code on success`
- ✅ `getTokensFromCode returns valid tokens`
- ✅ `getCodeFromNpsso throws on network error`
- ✅ `getTokensFromCode throws on API error`
