# PS Clips Viewer (Unofficial)

> [!TIP]
> **Looking for the headless Debian web gallery?**
>
> **[Linux setup and usage guide →](linux-headless/README.md)**

> **Status**: v1.1 (Stable Release)

A desktop application to view and download your PlayStation game clips and screenshots. Built with Flutter. Compatible with Windows/Linux/Mac, but only tested and built on Windows for now.

## Preface

This tool was built using AI as a way for me to test the capabilities of LLMs in building a desktop application. While the PSN API has been reverse-engineered by others, I could not find any information about the endpoint for the PlayStation cloud gallery, so I had to reverse-engineer it myself using an Android device, a patched version of the PS Mobile app, and Fiddler to intercept the requests and responses. I then used Google's Antigravity tool to use my findings and write code for a desktop application. This is the result.

## ✨ Features

- **Media Gallery**: Grid layout of your recent gameplay clips and screenshots.
- **Secure Authentication**: Official Sony login flow with 2FA support.
- **Direct Downloads**: Save videos (MP4) and screenshots (JPG/PNG) directly to your PC.
- **ShareX Upload Integration**: Import your ShareX .sxcu config and upload clips/screenshots directly to your own server or image host.
- **Video Preview**: Watch clips immediately within the app before downloading.

## 📖 How to Use

1. **Capture**: Create a clip or screenshot on your PS5 using the **Share** button.
2. **Upload**: 
   - **Automatic**: The console usually uploads captures automatically.
   - **Manual**: In the **Media Gallery**, press **Options** on a clip/screenshot and select **Upload to PlayStation App**.
3. **View**: Open the app and click the **Refresh** button.

> [!NOTE]  
> Media may take a few minutes to appear. Sony stores cloud captures for **14 days**; after this, they must be re-uploaded from the console to view them in the app..

## 🚀 Getting Started

### Installation
1. Go to the [Releases](https://github.com/CallMeTak/psn-clips/releases) page.
2. Download `psclips-v1.1.zip`.
3. Extract the contents to any folder.
4. Run `psclips.exe`.

### Usage Guide
1. **Sign In**: Launch the app and sign in with your PlayStation Network account. 
   *(Note: The login window connects strictly to `sonyentertainmentnetwork.com`)*.
2. **Browse**: Your library auto-loads. Click refresh to sync recent captures.
3. **Download**: Click any clip to open the Detail View, then hit the **Download** button to save.

## 🛠 For Developers

### Tech Stack
- **Framework**: Flutter (Windows Desktop)
- **State Management**: Riverpod (Code Generation)
- **Networking**: Dio
- **Auth**: Direct OAuth2 flow via `desktop_webview_window` and `dio`
- **Video**: `video_player_win` + `chewie`
- **Testing**: Mockito + Flutter Test

### Setup
Prerequisites: [Flutter SDK](https://docs.flutter.dev/get-started/install).

```bash
# 1. Clone repo
git clone https://github.com/CallMeTak/psn-clips.git
cd psclips

# 2. Install dependencies
flutter pub get

# 3. Generate code (Riverpod/Mocks)
dart run build_runner build --delete-conflicting-outputs

# 4. Run app
flutter run -d windows
```

### Testing

```bash
# Run unit tests
flutter test
```

**Key Test Coverage:**
- ✅ **NPSSO Exchange**: Verifies redirect parsing for auth codes.
- ✅ **Token Lifecycle**: Verifies auto-refresh of access tokens.

## 🔒 Security & Privacy

- **Zero Middlemen**: This app communicates **directly** between your PC and Sony's servers.
- **Secure Tokens**: Sensitive auth tokens are stored using `flutter_secure_storage`


## 📝 Todo
- [ ] Multi-account support
- [X] Auto-refresh logic (background fetch)
- [ ] Scheduled auto refresh and downloading
- [ ] Simple video trimming

## ⚠️ Disclaimer

This is a third-party tool. It is **not** official software from Sony Interactive Entertainment.
"PlayStation", "PSN", and "PS5" are registered trademarks of Sony Interactive Entertainment Inc.

