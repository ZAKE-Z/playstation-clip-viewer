---
phase: 1
plan: 1
wave: 1
---

# Plan 1.1: Project Setup & Dependencies

## Objective
Configure Flutter for Windows desktop development and add all required dependencies. This establishes the foundation for the entire application.

## Context
- .gsd/SPEC.md
- .gsd/DECISIONS.md (ADR-001: Riverpod, ADR-002: Feature-first)
- pubspec.yaml

## Tasks

<task type="auto">
  <name>Verify Windows desktop is enabled</name>
  <files>windows/</files>
  <action>
    Run `flutter config --enable-windows-desktop` if not already enabled.
    Verify the windows/ directory exists and contains CMakeLists.txt.
    Run `flutter doctor` and confirm Windows desktop toolchain is ready.
  </action>
  <verify>flutter doctor | Select-String "Windows"</verify>
  <done>Windows desktop development is enabled and flutter doctor shows no issues for Windows</done>
</task>

<task type="auto">
  <name>Add project dependencies to pubspec.yaml</name>
  <files>pubspec.yaml</files>
  <action>
    Add the following dependencies:
    
    **dependencies:**
    - dio: ^5.4.0 (HTTP client)
    - flutter_riverpod: ^2.4.0 (state management)
    - riverpod_annotation: ^2.3.0 (code generation)
    - flutter_secure_storage: ^9.0.0 (encrypted token storage)
    - freezed_annotation: ^2.4.0 (immutable models)
    - json_annotation: ^4.8.0 (JSON serialization)
    
    **dev_dependencies:**
    - build_runner: ^2.4.0 (code generation)
    - freezed: ^2.4.0 (model generator)
    - json_serializable: ^6.7.0 (JSON generator)
    - riverpod_generator: ^2.3.0 (provider generator)
    
    Run `flutter pub get` after adding dependencies.
    
    Do NOT add desktop_webview_window yet — that's Phase 2.
  </action>
  <verify>flutter pub get</verify>
  <done>All dependencies installed without errors, pubspec.lock updated</done>
</task>

## Success Criteria
- [ ] `flutter doctor` shows Windows desktop ready
- [ ] All dependencies in pubspec.yaml
- [ ] `flutter pub get` succeeds
- [ ] App still builds: `flutter build windows --debug`
