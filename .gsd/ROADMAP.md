# ROADMAP.md

> **Current Phase**: 1 (Complete)  
> **Milestone**: v1.0

## Must-Haves (from SPEC)

- [ ] WebView-based PSN authentication with token persistence
- [ ] Clips/screenshots grid view with thumbnails
- [ ] Metadata display for each item
- [ ] Download via native file picker

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
**Status**: ⬜ Not Started  
**Objective**: Display user's clips and screenshots in a grid

- Implement clips API integration
- Create clip data model
- Build gallery screen with grid layout
- Display thumbnails for each item
- Handle pagination / lazy loading
- Cache metadata locally

---

### Phase 4: Preview & Download
**Status**: ⬜ Not Started  
**Objective**: View details and download media

- Create detail view for selected item
- Display metadata (game, date, duration, type)
- Integrate video player for clip preview
- Implement download with native file picker
- Handle CloudFront cookie authentication for downloads
- Show download progress

---

### Phase 5: Polish & Release
**Status**: ⬜ Not Started  
**Objective**: Final touches for daily-driver quality

- Error handling and retry logic
- Loading states and empty states
- App icon and branding
- Windows build configuration
- User testing and bug fixes
