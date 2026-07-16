import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../auth/user_context.dart';
import '../config/environment.dart';
import 'telemetry_ids.dart';

/// First-party product / RUM events → am-logging → Loki.
class ProductTelemetry {
  ProductTelemetry._();
  static final ProductTelemetry instance = ProductTelemetry._();

  static const _flushInterval = Duration(seconds: 8);
  static const _maxBatch = 40;

  final List<Map<String, dynamic>> _queue = [];
  Timer? _flushTimer;
  bool _ready = false;
  String? _ingestUrl;
  String? _currentScreen;
  String? _currentSection;
  String _envLabel = 'production';

  /// Call once after config/env is known.
  Future<void> initialize({
    required String loggingBaseUrl,
    String? env,
  }) async {
    if (!(EnvironmentConfig.settings['analyticsEnabled'] as bool? ?? false)) {
      debugPrint('[ProductTelemetry] disabled (analyticsEnabled=false)');
      return;
    }
    final base = loggingBaseUrl.trim().replaceAll(RegExp(r'/$'), '');
    if (base.isEmpty) {
      debugPrint('[ProductTelemetry] no logging base URL — sink off');
      return;
    }
    if (env != null && env.isNotEmpty) {
      _envLabel = env;
      EnvironmentConfig.setEnvironment(env);
    }
    _ingestUrl = '$base/v1/telemetry/events';
    await TelemetryIds.instance.ensureReady();
    _ready = true;
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) => flush());
    debugPrint('[ProductTelemetry] sink → $_ingestUrl env=$_envLabel');
  }

  void dispose() {
    _flushTimer?.cancel();
    unawaited(flush());
  }

  String? get currentScreen => _currentScreen;
  String? get currentSection => _currentSection;

  void screenView(String path) {
    final section = sectionForPath(path);
    _currentScreen = path;
    _currentSection = section;
    _enqueue('screen_view', section: section, screen: path);
  }

  void sessionStart() {
    _enqueue('session_start', section: _currentSection, screen: _currentScreen);
  }

  void apiTiming({
    required String method,
    required String path,
    required int status,
    required int durationMs,
    String? category,
  }) {
    _enqueue(
      'api_timing',
      section: _currentSection,
      screen: _currentScreen,
      durationMs: durationMs,
      extra: {
        'method': method,
        'path': path,
        'status': status,
        if (category != null) 'category': category,
      },
      props: {
        'method': method,
        'path': path,
        'status': status,
        if (category != null) 'category': category,
      },
    );
  }

  void bootRum(Map<String, dynamic> summary) {
    final total = (summary['totalMs'] as num?)?.toDouble();
    _enqueue(
      'boot_rum',
      section: 'boot',
      screen: summary['path']?.toString() ?? '/',
      durationMs: total,
      props: summary,
    );
  }

  void featureAction(
    String action, {
    String? tag,
    Map<String, dynamic>? metadata,
  }) {
    _enqueue(
      'feature_action',
      section: _currentSection,
      screen: _currentScreen,
      extra: {
        'action': action,
        if (tag != null) 'tag': tag,
      },
      props: {
        'action': action,
        if (tag != null) 'tag': tag,
        if (metadata != null) ...metadata,
      },
    );
  }

  void _enqueue(
    String event, {
    String? section,
    String? screen,
    num? durationMs,
    Map<String, dynamic>? props,
    Map<String, dynamic>? extra,
  }) {
    if (!_ready) return;
    String? userId;
    try {
      userId = UserContext.instance.cachedUserId;
    } catch (_) {
      userId = null;
    }
    _queue.add({
      'event': event,
      'ts': DateTime.now().toUtc().toIso8601String(),
      'anon_id': TelemetryIds.instance.anonId,
      'session_id': TelemetryIds.instance.sessionId,
      if (userId != null && userId.isNotEmpty) 'user_id': userId,
      'platform': TelemetryIds.platformLabel(),
      'env': _envLabel,
      if (section != null) 'section': section,
      if (screen != null) 'screen': screen,
      if (durationMs != null) 'duration_ms': durationMs,
      if (extra != null) ...extra,
      if (props != null && props.isNotEmpty) 'props': props,
    });
    if (_queue.length >= _maxBatch) {
      unawaited(flush());
    }
  }

  Future<void> flush() async {
    if (!_ready || _ingestUrl == null || _queue.isEmpty) return;
    final batch = List<Map<String, dynamic>>.from(_queue);
    _queue.clear();
    try {
      final resp = await http
          .post(
            Uri.parse(_ingestUrl!),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'events': batch}),
          )
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode >= 300) {
        debugPrint(
          '[ProductTelemetry] flush ${resp.statusCode}: ${resp.body}',
        );
        // Drop on failure — avoid unbounded retry storms on mobile.
      }
    } catch (e) {
      debugPrint('[ProductTelemetry] flush error: $e');
    }
  }

  /// Map GoRouter path → product section.
  static String sectionForPath(String path) {
    final p = path.toLowerCase();
    if (p.startsWith('/login') ||
        p.startsWith('/register') ||
        p.startsWith('/forgot') ||
        p.startsWith('/reset') ||
        p.startsWith('/verify')) {
      return 'auth';
    }
    if (p.startsWith('/app/dashboard')) return 'dashboard';
    if (p.startsWith('/app/portfolio')) return 'portfolio';
    if (p.startsWith('/app/trade')) return 'trade';
    if (p.startsWith('/app/market')) return 'market';
    if (p.startsWith('/app/doc-intel')) return 'docs';
    if (p.startsWith('/app/ai-chat')) return 'ai';
    if (p.startsWith('/app/analysis')) return 'analysis';
    if (p.startsWith('/app/profile') || p.startsWith('/app/subscription')) {
      return 'profile';
    }
    return 'other';
  }
}
