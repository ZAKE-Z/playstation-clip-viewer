---
phase: 2
plan: 3
wave: 2
---

# Plan 2.3: WebView Login Implementation

## Objective
Implement the actual WebView login flow that opens PlayStation login, extracts NPSSO cookie, and exchanges it for tokens.

## Context
- .gsd/phases/2/RESEARCH.md
- lib/features/auth/presentation/psn_login_webview.dart
- lib/features/auth/providers/auth_provider.dart
- lib/core/constants/psn_api.dart

## Tasks

<task type="auto">
  <name>Implement PSN login WebView</name>
  <files>lib/features/auth/presentation/psn_login_webview.dart</files>
  <action>
    Replace placeholder with full implementation:
    
    ```dart
    import 'package:desktop_webview_window/desktop_webview_window.dart';
    import 'package:flutter/material.dart';
    import 'package:flutter_riverpod/flutter_riverpod.dart';
    import 'package:path_provider/path_provider.dart';
    import '../../../core/constants/psn_api.dart';
    import '../providers/auth_provider.dart';
    
    /// Helper to launch PSN login WebView
    class PsnLoginWebview {
      PsnLoginWebview._();
    
      /// Show the PSN login webview and handle authentication
      static Future<void> show(BuildContext context, WidgetRef ref) async {
        // Check if WebView is available (Windows needs WebView2 Runtime)
        final isAvailable = await WebviewWindow.isWebviewAvailable();
        if (!isAvailable) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('WebView2 Runtime not available. Please install it.'),
              ),
            );
          }
          return;
        }
    
        // Get user data folder for WebView
        final appDir = await getApplicationSupportDirectory();
        final userDataFolder = '${appDir.path}/webview_data';
    
        // Create webview
        final webview = await WebviewWindow.create(
          configuration: CreateConfiguration(
            userDataFolderWindows: userDataFolder,
            title: 'Sign in with PlayStation',
            titleBarHeight: 0, // Hide title bar for cleaner look
          ),
        );
    
        // Track if we've completed auth
        bool authComplete = false;
    
        // Monitor URL changes to detect login completion
        webview.addOnUrlRequestCallback((url) async {
          // After login, Sony redirects or the URL contains account info
          // We need to check for NPSSO cookie on any page under ca.account.sony.com
          if (url.contains('account.sony.com') && !authComplete) {
            // Try to extract NPSSO cookie
            final npsso = await _extractNpssoCookie(webview);
            if (npsso != null) {
              authComplete = true;
              await webview.close();
              
              // Authenticate with the NPSSO token
              await ref.read(authProvider.notifier).authenticateWithNpsso(npsso);
            }
          }
        });
    
        // Launch to PlayStation login page
        webview.launch(PsnApi.loginUrl);
      }
    
      /// Extract NPSSO cookie from WebView using JavaScript
      static Future<String?> _extractNpssoCookie(Webview webview) async {
        try {
          // Get all cookies via JavaScript
          final cookieString = await webview.evaluateJavaScript('document.cookie');
          if (cookieString == null || cookieString.isEmpty) return null;
    
          // Parse cookies to find npsso
          final cookies = cookieString.split(';');
          for (final cookie in cookies) {
            final trimmed = cookie.trim();
            if (trimmed.startsWith('npsso=')) {
              final npsso = trimmed.substring(6); // Remove 'npsso=' prefix
              if (npsso.isNotEmpty && npsso != 'null') {
                return npsso;
              }
            }
          }
          return null;
        } catch (e) {
          return null;
        }
      }
    }
    ```
  </action>
  <verify>dart analyze lib/features/auth/presentation/psn_login_webview.dart</verify>
  <done>psn_login_webview.dart fully implemented with cookie extraction</done>
</task>

<task type="auto">
  <name>Add path_provider dependency</name>
  <files>pubspec.yaml</files>
  <action>
    Add path_provider to dependencies (needed for WebView user data folder):
    ```yaml
    path_provider: ^2.1.0
    ```
    
    Run `flutter pub get`.
  </action>
  <verify>flutter pub get</verify>
  <done>path_provider added and installed</done>
</task>

## Success Criteria
- [ ] psn_login_webview.dart opens WebView to PSN login
- [ ] NPSSO cookie extracted after login
- [ ] Auth provider called with NPSSO
- [ ] WebView closes after successful auth
- [ ] `dart analyze lib/` passes
