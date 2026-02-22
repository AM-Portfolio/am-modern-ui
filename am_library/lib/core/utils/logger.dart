import 'package:am_design_system/am_design_system.dart' as am_ui;
import 'package:flutter/foundation.dart';
import '../config/environment.dart';

/// Legacy LogLevel for compatibility
enum LogLevel {
  debug(0, 'DEBUG'),
  info(1, 'INFO'),
  warning(2, 'WARNING'),
  error(3, 'ERROR');

  const LogLevel(this.priority, this.label);
  final int priority;
  final String label;
}

/// Centralized logging service redirected to CommonLogger
class AppLogger {
  static bool _isInitialized = false;

  static void initialize() {
    if (_isInitialized) return;
    _updateLoggingConfig(Environment.development); // Default to development
    _isInitialized = true;
    am_ui.CommonLogger.info('AppLogger initialized for am_library', tag: 'Logger');
  }

  static void _updateLoggingConfig(Environment environment) {
    switch (environment) {
      case Environment.development:
        am_ui.CommonLogger.configure(enabled: true, minLevel: am_ui.LogLevel.info);
        break;
      case Environment.preprod:
        am_ui.CommonLogger.configure(enabled: true, minLevel: am_ui.LogLevel.info);
        break;
      case Environment.production:
        am_ui.CommonLogger.configure(enabled: false, minLevel: am_ui.LogLevel.error);
        break;
    }
  }

  static void debug(String message, {String? tag}) {
    am_ui.CommonLogger.debug(message, tag: tag);
  }


  static void info(String message, {String? tag}) {
    am_ui.CommonLogger.info(message, tag: tag);
  }

  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    am_ui.CommonLogger.warning(message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    am_ui.CommonLogger.error(message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void methodEntry(String methodName, {String? tag, Map<String, dynamic>? params}) {
    final paramsStr = params != null ? '(${params.entries.map((e) => '${e.key}: ${e.value}').join(', ')})' : '()';
    am_ui.CommonLogger.debug('→ $methodName$paramsStr', tag: tag);
  }

  static void methodExit(String methodName, {String? tag, dynamic result}) {
    final resultStr = result != null ? ' -> $result' : '';
    am_ui.CommonLogger.debug('← $methodName$resultStr', tag: tag);
  }

  static void apiRequest(String method, String url, {String? tag, Map<String, dynamic>? headers, dynamic body}) {
    am_ui.CommonLogger.info('API Req: $method $url', tag: tag ?? 'API');
    if (headers != null) am_ui.CommonLogger.debug('Headers: $headers', tag: tag ?? 'API');
    if (body != null) am_ui.CommonLogger.debug('Body: $body', tag: tag ?? 'API');
  }

  static void apiResponse(String method, String url, int statusCode, {String? tag, dynamic body, int? duration}) {
    final durationInfo = duration != null ? ' (${duration}ms)' : '';
    final msg = 'API Res: $method $url -> $statusCode$durationInfo';
    if (statusCode >= 400) {
      am_ui.CommonLogger.warning(msg, tag: tag ?? 'API');
    } else {
      am_ui.CommonLogger.info(msg, tag: tag ?? 'API');
    }
  }

  static void userAction(String action, {String? tag, Map<String, dynamic>? context}) {
    am_ui.CommonLogger.info('User Action: $action context: $context', tag: tag ?? 'UserAction');
  }

  static void stateChange(String from, String to, {String? tag, dynamic event}) {
    am_ui.CommonLogger.debug('State: $from -> $to event: $event', tag: tag ?? 'State');
  }

}
