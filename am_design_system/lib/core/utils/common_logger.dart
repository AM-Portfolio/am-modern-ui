
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

enum LogLevel {
  debug(0, 'DEBUG', '🔍'),
  info(1, 'INFO', 'ℹ️'),
  warning(2, 'WARNING', '⚠️'),
  error(3, 'ERROR', '❌'),
  shout(4, 'SHOUT', '📢');

  const LogLevel(this.priority, this.label, this.emoji);
  final int priority;
  final String label;
  final String emoji;
}

/// A simplified, environment-agnostic logger for common UI components.
/// Can be configured by the host app.
class CommonLogger {
  static bool _loggingEnabled = true; // Default to true, host app can disable
  static LogLevel _minimumLogLevel = LogLevel.debug;

  /// Configure the logger (call this from the host app's main or init)
  static void configure({bool enabled = true, LogLevel minLevel = LogLevel.debug}) {
    _loggingEnabled = enabled;
    _minimumLogLevel = minLevel;
  }

  static void debug(String message, {String? tag}) {
    _log(message, LogLevel.debug, tag: tag);
  }

  static void info(String message, {String? tag}) {
    _log(message, LogLevel.info, tag: tag);
  }

  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(message, LogLevel.warning, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(message, LogLevel.error, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void shout(String message, {String? tag}) {
    _log(message, LogLevel.shout, tag: tag);
  }

  /// Convenience method for logging user actions
  static void userAction(String action, {String? tag, Map<String, dynamic>? metadata}) {
    final metaStr = metadata != null ? ' | META: $metadata' : '';
    _log('👤 ACTION: $action$metaStr', LogLevel.info, tag: tag);
  }

  /// Convenience method for method entry tracking
  static void methodEntry(String methodName, {String? tag, Map<String, dynamic>? metadata}) {
    final metaStr = metadata != null ? ' | PARAMS: $metadata' : '';
    _log('➡️ ENTRY: $methodName$metaStr', LogLevel.debug, tag: tag);
  }

  /// Convenience method for method exit tracking
  static void methodExit(String methodName, {String? tag, Map<String, dynamic>? metadata}) {
    final metaStr = metadata != null ? ' | RESULT: $metadata' : '';
    _log('⬅️ EXIT: $methodName$metaStr', LogLevel.debug, tag: tag);
  }

  /// Convenience method for state change logging
  static void stateChange(String fromState, String toState, {String? tag, Map<String, dynamic>? metadata, String? event}) {
    final metaStr = metadata != null ? ' | DATA: $metadata' : '';
    final eventStr = event != null ? ' | EVENT: $event' : '';
    _log('🔄 STATE: $fromState -> $toState$eventStr$metaStr', LogLevel.debug, tag: tag);
  }

  static void _log(String message, LogLevel level, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (!_loggingEnabled || level.priority < _minimumLogLevel.priority) return;

    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final tagInfo = tag != null ? '[$tag] ' : '';
    final finalMessage = '$timestamp ${level.emoji} ${level.label}: $tagInfo$message';

    if (kDebugMode) {
      // Use print in debug mode for immediate console output with colors
      final colorCode = _getColorCode(level);
      const resetColor = '\x1B[0m';
      
      print('$colorCode$finalMessage$resetColor');
      if (error != null) print('${colorCode}Error Detail: $error$resetColor');
      if (stackTrace != null) {
        print('${colorCode}Stack Trace:');
        final lines = stackTrace.toString().trim().split('\n');
        // Limit stack trace lines: 10 for errors/shouts, 5 for others
        final maxLines = (level.priority >= LogLevel.error.priority) ? 10 : 5;
        
        for (var i = 0; i < lines.length && i < maxLines; i++) {
          print('  ${lines[i]}');
        }
        if (lines.length > maxLines) {
          print('  ... (${lines.length - maxLines} more lines truncated)');
        }
        print('$resetColor');
      }

    } else {
      // Use developer log in release/other modes
      developer.log(
        message,
        name: tag ?? 'CommonUI',
        level: level.priority * 300,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static String _getColorCode(LogLevel level) {
    switch (level) {
      case LogLevel.debug: return '\x1B[36m'; // Cyan
      case LogLevel.info: return '\x1B[34m'; // Blue
      case LogLevel.warning: return '\x1B[33m'; // Yellow
      case LogLevel.error: return '\x1B[31m'; // Red
      case LogLevel.shout: return '\x1B[35m'; // Magenta
    }
  }
}

