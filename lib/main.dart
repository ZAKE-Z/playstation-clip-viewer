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

  runApp(const ProviderScope(child: PsClipsApp()));
}
