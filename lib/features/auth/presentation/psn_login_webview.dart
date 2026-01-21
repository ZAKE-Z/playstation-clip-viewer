import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Helper to launch PSN login WebView
class PsnLoginWebview {
  PsnLoginWebview._();

  /// Show the PSN login webview and handle authentication
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    // TODO: Implement in Plan 2.3
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('WebView login coming soon...')),
    );
  }
}
