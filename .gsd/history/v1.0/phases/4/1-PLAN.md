---
phase: 4
plan: 1
wave: 1
---

# Plan 4.1: Media Detail View

## Objective
Create a detailed view screen for media items that displays metadata and handles video playback or full-screen image preview.

## Context
- .gsd/SPEC.md
- lib/features/clips/data/media_item.dart
- lib/core/services/psn_media_service.dart

## Tasks

<task type="auto">
  <name>Add video player dependencies</name>
  <files>pubspec.yaml</files>
  <action>
    Add `video_player` and `chewie` packages to `pubspec.yaml` for video playback support.
    Run `flutter pub get`.
    
    *Note: Verify Windows support requirements for video_player.*
  </action>
  <verify>flutter pub get</verify>
  <done>Packages installed</done>
</task>

<task type="auto">
  <name>Create DetailScreen widget</name>
  <files>lib/features/clips/presentation/detail_screen.dart</files>
  <action>
    Create `DetailScreen` accepting `MediaItem` and `CloudFrontCookies`.
    Layout:
    - Split view or scrollable column
    - Top: Media player/Preview (VideoPlayer for videos, interactive Image for screenshots)
    - Bottom: Metadata (Game title, Title, Date, Duration, File size)
    - Actions: Download button placeholder
    
    Ensure `video_player` uses the signed URL generated from `CloudFrontCookies`.
  </action>
  <verify>dart analyze lib/features/clips/presentation/detail_screen.dart</verify>
  <done>Widget compiles and handles both media types</done>
</task>

<task type="auto">
  <name>Integrate navigation to DetailScreen</name>
  <files>lib/features/clips/presentation/gallery_screen.dart</files>
  <action>
    Update `GalleryScreen`'s grid item `onTap` to navigate to `DetailScreen`.
    Pass the current item and the active cookies.
  </action>
  <verify>Manual verification of navigation</verify>
  <done>Clicking a grid item opens the detail view</done>
</task>

## Success Criteria
- [ ] Tapping a grid item opens detail view
- [ ] Screenshots appear full-resolution (using signed URL)
- [ ] Videos play using `video_player` (using signed URL)
- [ ] Metadata is clearly visible
- [ ] "Download" button exists (functional logic in next plan)
