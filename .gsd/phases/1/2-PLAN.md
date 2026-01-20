---
phase: 1
plan: 2
wave: 1
---

# Plan 1.2: Project Folder Structure

## Objective
Create the feature-first folder structure as decided in ADR-002. This establishes consistent organization for all future development.

## Context
- .gsd/DECISIONS.md (ADR-002: Feature-first structure)
- lib/main.dart

## Tasks

<task type="auto">
  <name>Create folder structure</name>
  <files>lib/</files>
  <action>
    Create the following directory structure under lib/:
    
    ```
    lib/
    ├── main.dart (existing, will update in next task)
    ├── app.dart (new - app widget with ProviderScope)
    ├── core/
    │   ├── constants/
    │   │   └── psn_api.dart (API URLs, client IDs, scopes)
    │   ├── services/
    │   │   └── .gitkeep
    │   └── storage/
    │       └── .gitkeep
    ├── features/
    │   ├── auth/
    │   │   ├── data/
    │   │   ├── presentation/
    │   │   └── providers/
    │   ├── clips/
    │   │   ├── data/
    │   │   ├── presentation/
    │   │   └── providers/
    │   └── settings/
    │       ├── data/
    │       ├── presentation/
    │       └── providers/
    └── shared/
        └── widgets/
    ```
    
    Create .gitkeep files in empty directories to ensure they're tracked.
  </action>
  <verify>Get-ChildItem -Path "lib" -Recurse -Directory | Select-Object FullName</verify>
  <done>All directories exist under lib/ with proper structure</done>
</task>

<task type="auto">
  <name>Create PSN API constants file</name>
  <files>lib/core/constants/psn_api.dart</files>
  <action>
    Create psn_api.dart with PSN OAuth configuration:
    
    ```dart
    /// PlayStation Network API constants
    class PsnApi {
      PsnApi._();
      
      /// OAuth base URL
      static const String oauthBaseUrl = 'https://ca.account.sony.com/api/authz/v3/oauth';
      
      /// Media API base URL  
      static const String mediaApiBaseUrl = 'https://m.np.playstation.com/api/gamemedia/v1';
      
      /// OAuth client ID (PlayStation Android app)
      static const String clientId = '09515159-7237-4370-9b40-3806e67c0891';
      
      /// OAuth redirect URI
      static const String redirectUri = 'com.scee.psxandroid.scecompcall://redirect';
      
      /// OAuth scopes
      static const String scopes = 'psn:mobile.v2.core psn:clientapp';
      
      /// Login URL for WebView
      static const String loginUrl = 'https://my.account.sony.com/central/signin';
      
      /// Domain to check for NPSSO cookie
      static const String cookieDomain = 'ca.account.sony.com';
    }
    ```
    
    These values are extracted from the existing FastAPI server code.
  </action>
  <verify>dart analyze lib/core/constants/psn_api.dart</verify>
  <done>psn_api.dart exists with all constants, passes dart analyze</done>
</task>

<task type="auto">
  <name>Update main.dart and create app.dart</name>
  <files>lib/main.dart, lib/app.dart</files>
  <action>
    Create lib/app.dart:
    ```dart
    import 'package:flutter/material.dart';
    
    class PsClipsApp extends StatelessWidget {
      const PsClipsApp({super.key});
    
      @override
      Widget build(BuildContext context) {
        return MaterialApp(
          title: 'PS Clips',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const Scaffold(
            body: Center(
              child: Text('PS Clips - Coming Soon'),
            ),
          ),
        );
      }
    }
    ```
    
    Update lib/main.dart:
    ```dart
    import 'package:flutter/material.dart';
    import 'package:flutter_riverpod/flutter_riverpod.dart';
    import 'app.dart';
    
    void main() {
      runApp(
        const ProviderScope(
          child: PsClipsApp(),
        ),
      );
    }
    ```
    
    This sets up Riverpod at the app root.
  </action>
  <verify>flutter analyze lib/</verify>
  <done>main.dart uses ProviderScope, app.dart defines PsClipsApp, no analyzer errors</done>
</task>

## Success Criteria
- [ ] All directories exist under lib/
- [ ] psn_api.dart contains all constants
- [ ] main.dart wraps app in ProviderScope
- [ ] `flutter analyze lib/` passes with no errors
