# STATE.md — Project Memory

> Last updated: 2026-01-21

## Current Position

- **Milestone**: v1.1-testing (Completed)
- **Phase**: All Complete
- **Status**: ✅ Milestone Finalized

## What Was Just Accomplished

### Refactoring: Storage Directories
- **Configurable**: Implemented `getAppDirectory()` in `storage_utils.dart` to use executable's parent folder on Desktop.
- **Logs**: `LoggerService` now writes logs to the app directory.
- **WebView**: `PsnLoginWebview` stores data in `webview_data` within the app directory.
- **Tests**: Mocked `LoggerService` to silence expected error logs during testing.

### Phase 3: Token Management & Refresh
- **Verified**: Token persistence logic with `TokenStorage` tests.
- **Verified**: Auto-refresh logic (access token expiry) with `PsnAuthService` tests.
- **Verified**: Fail-safe logout logic (refresh token expiry).
- **Verified**: Expiration arithmetic (relative `expires_in` to absolute `expiresAt`).

## Next Steps
1. Milestone v1.1-testing COMPLETE
2. /new-milestone v1.2-features
- **Verified**: NPSSO exchange logic with mocked 302 redirect.
- **Verified**: Token exchange logic with mocked 200 response.
- **Verified**: Error handling for network drops and API errors.

## Next Steps
1. /plan 3 (Token Management & Refresh)
2. /execute 3
- **Dependencies**: Added `mockito` and `build_runner`.
- **Mocks**: Defined and generated mocks for `FlutterSecureStorage` and `Dio`.
- **Verification**: `dart run build_runner build` passed successfully.

## Next Steps
1. /plan 2 (Auth Logic Verification)
2. /execute 2

## What Was Just Accomplished

### Milestone Planning
- **Created**: v1.1-testing (Comprehensive Unit Testing).
- **Phases**: Defined 3 phases focusing on Test Foundation, Auth Logic, and Token Management.
- **Roadmap**: Updated `ROADMAP.md` with new goals and archived v1.0 history.

### Phase 5: Polish
- **UI**: Added empty states, error handling retry, and refresh indicators.
- **Window**: Configured 1024x768 initial size and "PS Clips" title using `window_manager`.
- **Packaging**: Built release version and packaged into `psclips-v1.0.0.zip`.

## Verification
- ✅ `flutter build windows --release` builds successfully.
- ✅ `psclips-v1.0.0.zip` created (11MB).
- ✅ Login flow verified by user.

## Next Steps

1. Enjoy your clips!
