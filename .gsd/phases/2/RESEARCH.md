# Phase 2 Research: desktop_webview_window

## Package Info
- **Package**: desktop_webview_window ^0.2.3
- **Platforms**: Windows (WebView2), macOS, Linux (webkit2gtk-4.1)

## Setup Requirements

### Windows
- Requires WebView2 Runtime (ships with Windows 11, may need install on Windows 10)
- Check availability: `WebviewWindow.isWebviewAvailable()`
- User data folder should be set to avoid crashes in read-only directories

### Main Setup
Modify `main.dart`:
```dart
import 'package:desktop_webview_window/desktop_webview_window.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Required for webview title bar
  if (runWebViewTitleBarWidget(args)) {
    return;
  }
  
  runApp(const ProviderScope(child: PsClipsApp()));
}
```

## Key API Methods

### Creating WebView
```dart
final webview = await WebviewWindow.create(
  configuration: CreateConfiguration(
    userDataFolderWindows: 'path/to/data', // Avoid crashes
  ),
);
webview.launch("https://example.com");
```

### Monitoring Navigation
```dart
webview.addOnUrlRequestCallback((url) {
  // Called on every navigation
  if (url.contains('some-pattern')) {
    // Handle specific URL
  }
});
```

### Extracting Cookies
No direct `getCookies()` method. Must use JavaScript:
```dart
final cookies = await webview.evaluateJavaScript('document.cookie');
// Parse cookies from string
```

### Closing WebView
```dart
await webview.close();
```

## Cookie Extraction Strategy

1. Open WebView to PlayStation login URL
2. User completes login (email, password, 2FA)
3. Monitor URL navigation with `addOnUrlRequestCallback`
4. After login success, use `evaluateJavaScript('document.cookie')` to extract cookies
5. Parse the cookie string to find `npsso` value
6. Close webview and pass NPSSO to auth service

## Notes
- NPSSO cookie is set on `ca.account.sony.com` domain
- Login starts at `https://my.account.sony.com/central/signin`
- After login, user may be redirected to success page or stay on account page
- Need to detect when login is complete (URL change or cookie presence)
