import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Required for webview title bar on desktop
  if (runWebViewTitleBarWidget(args)) {
    return;
  }

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1024, 768),
    minimumSize: Size(800, 600),
    center: true,
    title: 'PS Clips',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: PsClipsApp()));
}
