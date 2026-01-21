import 'dart:convert';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/psn_api.dart';
import '../providers/auth_provider.dart';

/// Helper to launch PSN login WebView
class PsnLoginWebview {
  PsnLoginWebview._();

  /// SSO Cookie endpoint that returns NPSSO as JSON
  static const String _ssoCookieUrl =
      'https://ca.account.sony.com/api/v1/ssocookie';

  /// Show the PSN login webview and handle authentication
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    // Check if WebView is available (Windows needs WebView2 Runtime)
    final isAvailable = await WebviewWindow.isWebviewAvailable();
    if (!isAvailable) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'WebView2 Runtime not available. Please install it from Microsoft.',
            ),
            duration: Duration(seconds: 5),
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
      ),
    );

    // Track if we've completed auth
    bool authComplete = false;
    bool checkingNpsso = false;

    // Monitor URL changes to detect login completion
    webview.addOnUrlRequestCallback((url) async {
      // Check if we're on the ssocookie endpoint (direct NPSSO response)
      if (url.contains('ssocookie') && !authComplete) {
        // The page will show JSON with npsso - extract it
        await _extractNpssoFromSsoCookie(webview, ref, () {
          authComplete = true;
          webview.close();
        });
        return;
      }

      // After login on account.sony.com, navigate to ssocookie endpoint
      if (url.contains('account.sony.com') &&
          !url.contains('signin') &&
          !url.contains('ssocookie') &&
          !authComplete &&
          !checkingNpsso) {
        checkingNpsso = true;
        // Small delay to ensure login is complete
        await Future.delayed(const Duration(milliseconds: 500));
        webview.launch(_ssoCookieUrl);
      }
    });

    // Launch to PlayStation login page
    webview.launch(PsnApi.loginUrl);
  }

  /// Extract NPSSO from the ssocookie endpoint JSON response
  static Future<void> _extractNpssoFromSsoCookie(
    Webview webview,
    WidgetRef ref,
    VoidCallback onSuccess,
  ) async {
    String? bodyContent;
    try {
      // Wait for page to load
      await Future.delayed(const Duration(milliseconds: 500));

      // Get the page body which should be pure JSON
      bodyContent = await webview.evaluateJavaScript('document.body.innerText');

      if (bodyContent == null || bodyContent.isEmpty) return;
      // Parse the JSON response directly
      final data = jsonDecode(jsonDecode(bodyContent));
      final npsso = data['npsso'];

      if (npsso != null && npsso.isNotEmpty) {
        onSuccess();
        // Authenticate with the NPSSO token
        await ref.read(authProvider.notifier).authenticateWithNpsso(npsso);
      }
    } catch (e) {
      // Silently fail, user can retry
    }
  }
}
