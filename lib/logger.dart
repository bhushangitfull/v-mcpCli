import 'package:logging/logging.dart';
import 'package:flutter/widgets.dart';
import 'file_logger.dart';

// Define color codes
const ansiReset = '\x1B[0m';
const ansiRed = '\x1B[31m';
const ansiGreen = '\x1B[32m';
const ansiYellow = '\x1B[33m';
const ansiBlue = '\x1B[34m';
const ansiMagenta = '\x1B[35m';
const ansiGray = '\x1B[37m';


String getLevelColor(Level level) {
  switch (level.name) {
    case 'SEVERE':
      return ansiRed;
    case 'WARNING':
      return ansiYellow;
    case 'INFO':
      return ansiBlue;
    case 'CONFIG':
      return ansiMagenta;
    case 'FINE':
    case 'FINER':
    case 'FINEST':
      return ansiGreen;
    default:
      return ansiGray;
  }
}

void initializeLogger() async {
  // Initialize file logger
  await FileLogger.initLogFile();

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // Get caller location info
    String? caller;

    // Use StackTrace.current to ensure stack trace is always available
    final stackTrace = record.stackTrace ?? StackTrace.current;
    final frames = stackTrace.toString().split('\n');

    if (frames.length > 1) {
      // Parse the first matching stack frame
      final callerFrame = frames.firstWhere(
        (frame) =>
            !frame.contains('log.dart') &&
            !frame.contains('logger.dart') &&
            !frame.contains('logger_mixin.dart') &&
            !frame.contains('main.dart') &&
            !frame.contains('dart:async') &&
            !frame.contains('dart:io') &&
            frame.contains('package:chatmcp/'),
        orElse: () => frames.firstWhere((frame) => frame.contains('package:chatmcp/'), orElse: () => frames[0]),
      );

      // Extract filename and line number
      final match = RegExp(r'\((.+?):(\d+)(?::\d+)\)').firstMatch(callerFrame);
      if (match != null) {
        final file = match.group(1);
        final line = match.group(2);
        caller = '$file:$line';
      } else {
        final flutterMatch = RegExp(r'#\d+\s+.*\s+\((.+?):(\d+)(?::\d+)?\)').firstMatch(callerFrame);
        if (flutterMatch != null) {
          final file = flutterMatch.group(1);
          final line = flutterMatch.group(2);
          caller = '$file:$line';
        }
      }
    }

    final levelColor = getLevelColor(record.level);
    final logMessage = '${record.level.name}: ${caller ?? 'unknown'}: ${record.message}';

    // In development mode, print colored logs to console
    assert(() {
      debugPrint('$levelColor$logMessage$ansiReset');
      return true;
    }());

    // In release mode, write to file
    FileLogger.writeToFile(logMessage);
  });
}
