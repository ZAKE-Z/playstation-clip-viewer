# ROADMAP.md

> **Current Milestone**: v1.1-testing
> **Goal**: Comprehensive unit testing to verify authentication flow and token stability.

## Must-Haves
- [x] Test infrastructure setup (mockito, build_runner)
- [ ] Unit tests for NPSSO exchange logic
- [ ] Unit tests for Token Refresh logic (expiration checks, storage)
- [ ] Verify `PsnAuthService` handles network errors gracefully

## Phases

### Phase 1: Test Foundation
**Status**: ✅ Complete
**Objective**: Configure testing environment and generate mocks

- Add `mockito` and `build_runner` dependencies
- Create mock classes for `FlutterSecureStorage` and `Dio`
- Set up test helpers and fixtures

### Phase 2: Auth Logic Verification
**Status**: ⬜ Not Started
**Objective**: Test the core authentication exchange flow

- Test `PsnAuthService.exchangeNpssoForCode`
- Test `PsnAuthService.exchangeCodeForTokens`
- Verify correct parsing of API responses
- Verify error handling for invalid grants

### Phase 3: Token Management & Refresh
**Status**: ⬜ Not Started
**Objective**: Verify long-term session stability

- Test `TokenStorage` read/write operations
- Test `PsnAuthService.refreshAccessToken`
- Verify token expiry calculation
- Verify automatic refresh triggers when loading valid tokens

---

## History

### v1.0 (Released)
> **Goal**: Desktop app for viewing and downloading PSN clips.
- ✅ **Phase 1**: Project Foundation
- ✅ **Phase 2**: Authentication UI
- ✅ **Phase 3**: Clips Gallery
- ✅ **Phase 4**: Preview & Download
- ✅ **Phase 5**: Polish & Release
