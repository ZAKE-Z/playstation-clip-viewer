---
phase: 2
plan: 1
wave: 1
---

# Plan 2.1: WebView Package Setup

## Objective
Add desktop_webview_window package and configure main.dart for WebView support. This is required before any WebView functionality can work.

## Context
- .gsd/phases/2/RESEARCH.md
- lib/main.dart
- pubspec.yaml

## Tasks

<task type="auto">
  <name>Add desktop_webview_window dependency</name>
  <files>pubspec.yaml</files>
  <action>
    Add to dependencies in pubspec.yaml:
    ```yaml
    desktop_webview_window: ^0.2.3
    ```
    
    Run `flutter pub get` to install.
  </action>
  <verify>flutter pub get</verify>
  <done>Package installed, no pub get errors</done>
</task>

<task type="auto">
  <name>Update main.dart for WebView support</name>
  <files>lib/main.dart</files>
  <action>
    Modify main.dart to support WebView title bar:
    
    ```dart
    import 'package:flutter/material.dart';
    import 'package:flutter_riverpod/flutter_riverpod.dart';
    import 'package:desktop_webview_window/desktop_webview_window.dart';
    import 'app.dart';
    
    void main(List<String> args) async {
      WidgetsFlutterBinding.ensureInitialized();
      
      // Required for webview title bar on desktop
      if (runWebViewTitleBarWidget(args)) {
        return;
      }
      
      runApp(
        const ProviderScope(
          child: PsClipsApp(),
        ),
      );
    }
    ```
    
    Key changes:
    - Add `List<String> args` parameter to main
    - Call `runWebViewTitleBarWidget(args)` before runApp
  </action>
  <verify>dart analyze lib/main.dart</verify>
  <done>main.dart updated, passes dart analyze</done>
</task>

## Success Criteria
- [ ] desktop_webview_window in pubspec.yaml
- [ ] `flutter pub get` succeeds
- [ ] main.dart has WebView title bar setup
- [ ] `dart analyze lib/` passes
