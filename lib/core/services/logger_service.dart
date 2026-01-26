import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:psclips/core/utils/storage_utils.dart';

part 'logger_service.g.dart';

@Riverpod(keepAlive: true)
LoggerService loggerService(Ref ref) {
  return LoggerService();
}

class LoggerService {
  File? _logFile;

  LoggerService() {
    _init();
  }

  Future<void> _init() async {
    try {
      final docDir = await getAppDirectory();
      _logFile = File('${docDir.path}\\psclips_error.log');
    } catch (e) {
      // Fallback or print to console if we can't find dir
      debugPrint('Logger init failed: $e');
    }
  }

  Future<void> logError(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) async {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final logMessage = StringBuffer();

    logMessage.writeln('[$timestamp] ERROR: $message');
    if (error != null) {
      logMessage.writeln('  Details: $error');
    }
    if (stackTrace != null) {
      logMessage.writeln('  Stack Trace:');
      logMessage.writeln(stackTrace.toString());
    }
    logMessage.writeln('-' * 80);

    // Print to console for debug
    print(logMessage.toString());

    // Write to file
    try {
      if (_logFile == null) await _init();
      if (_logFile != null) {
        await _logFile!.writeAsString(
          logMessage.toString(),
          mode: FileMode.append,
          flush: true,
        );
      }
    } catch (e) {
      print('Failed to write to log file: $e');
    }
  }

  Future<String?> getLogFilePath() async {
    if (_logFile == null) await _init();
    return _logFile?.path;
  }

  Future<void> clearLog() async {
    try {
      if (_logFile == null) await _init();
      if (_logFile != null && await _logFile!.exists()) {
        await _logFile!.writeAsString('');
      }
    } catch (e) {
      print('Failed to clear log: $e');
    }
  }
}
