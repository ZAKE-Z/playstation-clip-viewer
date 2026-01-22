# PS Clips Viewer (Unofficial)

A desktop application to view and download your PlayStation game clips and screenshots on Windows.

![PS Clips Banner](https://placeholder.com/banner.png)

## Features

- **📷 Media Gallery**: View all your recent gameplay clips and screenshots in a clean grid.
- **🔐 Secure Login**: Standard PlayStation login flow with 2FA support.
- **⬇️ Download**: Save videos (MP4) and screenshots (JPG/PNG) directly to your PC.
- **📼 Video Preview**: Watch clips before downloading.
- **📄 Metadata**: View game titles, upload dates, and file sizes.

## Getting Started

### Installation
1. Download the latest `psclips-vX.X.X.zip` release.
2. Extract the zip file to a folder.
3. Run `psclips.exe`.

### How to Use
1. **Login**: Click "Sign in with PlayStation". A window will open to the official Sony login page. Enter your credentials.
2. **Browse**: Once logged in, your media will load automatically. Scroll down to load more.
3. **View & Download**: Click any item to view details. Click the **Download** icon to save it to your computer.
4. **Refresh**: Pull down on the grid or click the Refresh icon in the top right to check for new uploads.

## Development

Prerequisites:
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Visual Studio 2022](https://visualstudio.microsoft.com/) (with C++ desktop workload)

```bash
# Clone the repository
git clone https://github.com/yourusername/psn-clips.git

# Install dependencies
flutter pub get

# Run in debug mode
flutter run -d windows

# Build release version
flutter build windows --release
```

## Privacy & Security

- **Direct Connection**: This app communicates directly with PlayStation Network APIs. No intermediate servers are used.
- **Token Storage**: Authentication tokens are stored securely on your device using Windows Credential Locker.
- **Open Source**: The code is available for audit.

## Disclaimer

This is an unofficial fan-made application and is not affiliated with, endorsed, sponsored, or approved by Sony Interactive Entertainment Inc. "PlayStation" is a registered trademark of Sony Interactive Entertainment Inc.
