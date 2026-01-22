# PS Clips Viewer (Unofficial)

> **Status**: v1.0.0 (Stable Release) | **Testing**: v1.1 (Verified)

A native Windows desktop application to view and download your PlayStation game clips and screenshots. Built with Flutter, it provides a fast, secure, and modern interface for your PS5 interactions.

## ✨ Features

- **Media Gallery**: Grid layout of your recent gameplay clips and screenshots.
- **Secure Authentication**: Official Sony login flow with 2FA support.
- **Direct Downloads**: Save videos (MP4) and screenshots (JPG/PNG) directly to your PC.
- **Video Preview**: Watch clips immediately within the app before downloading.
- **Metadata**: View game titles, upload dates, and duration details.
- **Native Experience**: Optimized window management and responsive grid.

## 🚀 Getting Started

### Installation
1. Go to the [Releases](https://github.com/yourusername/psn-clips/releases) page.
2. Download `psclips-v1.0.0.zip`.
3. Extract the contents to any folder.
4. Run `psclips.exe`.

### Usage Guide
1. **Sign In**: Launch the app and sign in with your PlayStation Network account. 
   *(Note: The login window connects strictly to `sonyentertainmentnetwork.com`)*.
2. **Browse**: Your library auto-loads. Pull down or click refresh to sync recent captures.
3. **Download**: Click any clip to open the Detail View, then hit the **Download** button to save.

## 🛠 For Developers

### Tech Stack
- **Framework**: Flutter (Windows Desktop)
- **State Management**: Riverpod (Code Generation)
- **Networking**: Dio
- **Auth**: Direct OAuth2 flow via `desktop_webview_window`
- **Video**: `video_player_win` + `chewie`
- **Testing**: Mockito + Flutter Test

### Setup
Prerequisites: [Flutter SDK](https://docs.flutter.dev/get-started/install) and [Visual Studio 2022 (C++)](https://visualstudio.microsoft.com/).

```bash
# 1. Clone repo
git clone https://github.com/yourusername/psn-clips.git
cd psclips

# 2. Install dependencies
flutter pub get

# 3. Generate code (Riverpod/Mocks)
dart run build_runner build --delete-conflicting-outputs

# 4. Run app
flutter run -d windows
```

### Testing (v1.1 Verified)
We maintain high coverage of the critical authentication logic.

```bash
# Run unit tests
flutter test
```

**Key Test Coverage:**
- ✅ **NPSSO Exchange**: Verifies redirect parsing for auth codes.
- ✅ **Token Lifecycle**: Verifies auto-refresh of access tokens.
- ✅ **Persistence**: Ensures tokens are securely encrypted via Windows Credential Locker.

## 🔒 Security & Privacy

- **Zero Middlemen**: This app communicates **directly** between your PC and Sony's servers. No data is sent to us.
- **Secure Storage**: Sensitive tokens are stored using `flutter_secure_storage`, which uses the **Windows Credential Locker**.
- **Ephemeral Session**: The login WebView session is isolated and cleared on logout.

## ⚠️ Disclaimer

This is a third-party tool. It is **not** official software from Sony Interactive Entertainment.
"PlayStation", "PSN", and "PS5" are registered trademarks of Sony Interactive Entertainment Inc.

---
*Created with ❤️ by the PSN Clips Community*
