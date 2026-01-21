---
phase: 5
plan: 2
wave: 2
---

# Plan 5.2: Branding & Build

## Objective
Finalize app branding and build configuration for Windows release.

## Context
- .gsd/SPEC.md
- pubspec.yaml
- windows/runner/runner.exe.manifest

## Tasks

<task type="auto">
  <name>Set App Icon</name>
  <files>windows/runner/resources/*</files>
  <action>
    Update Windows app icon:
    - Replace default Flutter icon in `windows/runner/resources/app_icon.ico`.
    - (Optionally) Use `flutter_launcher_icons` if generating from a png.
    
    *Note: Since we don't have a designer, use a generic controller or play button icon if available, or keep default if no asset provided. User might provide one.*
    
    Update `bitsdojo_window` configuration in `main.dart` to ensure window title matches "PSN Clips".
  </action>
  <verify>Run app and check taskbar/window icon</verify>
  <done>App has correct branding</done>
</task>

<task type="auto">
  <name>Configure Window Properties</name>
  <files>lib/main.dart</files>
  <action>
    Review `doWhenWindowReady` in `main.dart`:
    - Set minimum window size (e.g., 800x600).
    - Set initial window size.
    - Set title to "PSN Clips Manager".
  </action>
  <verify>Run app and check window constraints</verify>
  <done>Window behaves like a desktop app</done>
</task>

<task type="auto">
  <name>Final Build Test</name>
  <files>HEAD</files>
  <action>
    Run a release mode build to verify everything works in production mode.
    `flutter build windows`
  </action>
  <verify>flutter build windows</verify>
  <done>Release build completes successfully</done>
</task>

## Success Criteria
- [ ] App has appropriate window title
- [ ] Window has reasonable minimum size constraints
- [ ] Release build succeeds
