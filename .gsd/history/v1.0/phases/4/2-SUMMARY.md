## Plan 4.2 Summary: Media Download

**Status**: ✅ Complete

### What Was Done
- Added `file_selector` and `intl` dependencies
- Created `DownloadService` with:
  - Filename sanitization and localization
  - File picker dialog for saving
  - CloudFront signed URL support (prioritizing MP4 `downloadUrl`)
  - Dio-based file downloading with progress tracking
- Integrated download functionality into `DetailScreen`:
  - Download button with loading state
  - Progress indicator in button
  - Success/Error snackbars

### Files Modified
- `pubspec.yaml`
- `lib/core/services/download_service.dart` [NEW]
- `lib/features/clips/presentation/detail_screen.dart`

### Verification
- Analyzer checks passed
- Logic prioritizes `downloadUrl` > `videoUrl` > `screenshotUrl` as requested
- Windows platform support explicitly handled
