# ROADMAP.md

> **Current Phase**: 5 (Complete)  
> **Milestone**: v1.0

## Must-Haves (from SPEC)

- [x] WebView-based PSN authentication with token persistence
- [x] Clips/screenshots grid view with thumbnails
- [x] Metadata display for each item
- [x] Download via native file picker

## Phases

### Phase 1: Project Foundation
**Status**: ✅ Complete  
**Objective**: Set up project structure, dependencies, and core services

- Configure Flutter for Windows desktop
- Add dependencies (dio, flutter_secure_storage, riverpod, etc.)
- Create project folder structure
- Implement PSN API client (auth flow: NPSSO → code → tokens)
- Implement secure token storage with auto-refresh

---

### Phase 2: Authentication UI
**Status**: ✅ Complete  
**Objective**: WebView login flow with persistent sessions

- Add desktop_webview_window package
- Create login screen with "Sign in with PlayStation" button
- Implement WebView that opens PSN login
- Extract NPSSO cookie after successful login
- Exchange NPSSO for access/refresh tokens
- Persist tokens for future launches
- Handle token refresh on app start

---

### Phase 3: Clips Gallery
**Status**: ✅ Complete  
**Objective**: Display user's clips and screenshots in a grid

- Implement clips API integration
- Create clip data model
- Build gallery screen with grid layout
- Display thumbnails for each item
- Handle pagination / lazy loading
- Rate-limited image caching

---

### Phase 4: Preview & Download
**Status**: ✅ Complete  
**Objective**: View details and download media

- Create detail view for selected item
- Display metadata (game, date, duration, type)
- Integrate video player for clip preview
- Implement download with native file picker
- Handle CloudFront cookie authentication for downloads
- Show download progress

---

### Phase 5: Polish & Release
**Status**: ✅ Complete  
**Objective**: Final touches for daily-driver quality

- Error handling and retry logic
- Loading states and empty states
- App icon and branding
- Windows build configuration
- User testing and bug fixes
