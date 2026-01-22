---
phase: 4
plan: 2
wave: 2
---

# Plan 4.2: Media Download

## Objective
Implement functionality to download clips and screenshots to the user's local file system.

## Context
- .gsd/SPEC.md
- lib/features/clips/presentation/detail_screen.dart

## Tasks

<task type="auto">
  <name>Add file selector dependency</name>
  <files>pubspec.yaml</files>
  <action>
    Add `file_selector` or `file_picker` package to `pubspec.yaml`.
    Run `flutter pub get`.
  </action>
  <verify>flutter pub get</verify>
  <done>Package installed</done>
</task>

<task type="auto">
  <name>Implement DownloadService</name>
  <files>lib/core/services/download_service.dart</files>
  <action>
    Create `DownloadService` class:
    - Method `downloadMedia(MediaItem item, CloudFrontCookies cookies)`
    - Open save dialog to pick location (default filename from metadata)
    - Use `Dio` to download file stream to target path
    - Use signed URL for the request
    - Return progress stream or status
  </action>
  <verify>dart analyze lib/core/services/download_service.dart</verify>
  <done>Service implemented</done>
</task>

<task type="auto">
  <name>Connect Download UI</name>
  <files>lib/features/clips/presentation/detail_screen.dart</files>
  <action>
    Connect "Download" button in `DetailScreen` to `DownloadService`.
    Show progress dialog or snackbar during download.
    Show success/error notification on completion.
  </action>
  <verify>Manual verification of download flow</verify>
  <done>Download button saves file correctly</done>
</task>

## Success Criteria
- [ ] Clicking download opens a file saver dialog
- [ ] File is saved successfully to chosen location
- [ ] Progress is visible during download
- [ ] Videos play correctly from local disk after download
