import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Get the directory where the application executable is located.
///
/// On Windows/Linux/macOS, this uses the executable's path.
/// On mobile, it falls back to the application support directory.
Future<Directory> getAppDirectory() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Platform.resolvedExecutable points to the .exe
    // We want the folder containing it
    return File(Platform.resolvedExecutable).parent;
  }

  // Fallback for mobile or other platforms
  return await getApplicationSupportDirectory();
}
