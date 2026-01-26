---
phase: 1
plan: 1
wave: 1
---

# Plan 1.1: Test Infrastructure

## Objective
Set up the testing environment with necessary dependencies (`mockito`, `build_runner`) and generate mock classes for core services to enable unit testing.

## Context
- .gsd/SPEC.md
- pubspec.yaml
- lib/core/services/psn_auth_service.dart
- lib/core/storage/token_storage.dart

## Tasks

<task type="auto">
  <name>Add Testing Dependencies</name>
  <files>pubspec.yaml</files>
  <action>
    Add `mockito`, `build_runner`, and `flutter_test` (if missing) to dev_dependencies.
    Ensure compatible versions for Flutter 3.10.x.
  </action>
  <verify>flutter pub get</verify>
  <done>Dependencies resolve successfully</done>
</task>

<task type="auto">
  <name>Create Mock Service definitions</name>
  <files>test/mocks/mock_definitions.dart</files>
  <action>
    Create a file `test/mocks/mock_definitions.dart` to define classes to generate mocks for:
    - `FlutterSecureStorage` using `@GenerateNiceMocks`
    - `Dio`
  </action>
  <verify>dart analyze test/mocks/mock_definitions.dart</verify>
  <done>File compiles with annotations</done>
</task>

<task type="auto">
  <name>Generate Mocks</name>
  <files>test/mocks/mock_definitions.mocks.dart</files>
  <action>
    Run build_runner to generate the mocks.
  </action>
  <verify>dart run build_runner build --delete-conflicting-outputs</verify>
  <done>Mocks generated successfully</done>
</task>

## Success Criteria
- [ ] `flutter test` runs without environment errors
- [ ] Mocks are generated in `test/mocks/`
