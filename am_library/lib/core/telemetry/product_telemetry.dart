import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../auth/user_context.dart';
import '../config/environment.dart';
import 'telemetry_ids.dart';

/// First-party product / RUM events → am-logging → Loki.
class ProductTelemetry with WidgetsBindingObserver {
  ProductTelemetry._();
  static final ProductTelemetry instance = ProductTelemetry._();

  static const _flushInterval = Duration(seconds: 8);
  static const _maxBatch = 40;
  static final _uuidRe = RegExp(
    r'[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}',
    caseSensitive: false,
  );

  final List<Map<String, dynamic>> _queue = [];
  Timer? _flushTimer;
  bool _ready = false;
  bool _lifecycleAttached = false;
  String? _ingestUrl;
  String? _currentScreen;
  String? _currentSection;
  String? _previousSection;
  String _envLabel = 'prod';
  DateTime? _screenEnteredAt;
  String? _entrySection;
  String? _entryScreen;
  String? _entrySource;
  bool _entryRecorded = false;

  /// Call once after config/env is known.
  Future<void> initialize({
    required String loggingBaseUrl,
    String? env,
    String? entrySource,
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
      _envLabel = _normalizeEnvLabel(env);
      EnvironmentConfig.setEnvironment(_envLabel);
    }
    if (entrySource != null && entrySource.isNotEmpty) {
      _entrySource = entrySource;
    }
    _ingestUrl = '$base/v1/telemetry/events';
    await TelemetryIds.instance.ensureReady();
    _ready = true;
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) => flush());
    if (!_lifecycleAttached) {
      WidgetsBinding.instance.addObserver(this);
      _lifecycleAttached = true;
    }
    debugPrint('[ProductTelemetry] sink → $_ingestUrl env=$_envLabel');
  }

  void dispose() {
    _closeScreenTiming(exit: true);
    if (_lifecycleAttached) {
      WidgetsBinding.instance.removeObserver(this);
      _lifecycleAttached = false;
    }
    _flushTimer?.cancel();
    unawaited(flush());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _closeScreenTiming(exit: true);
      unawaited(flush());
    } else if (state == AppLifecycleState.resumed &&
        _currentScreen != null &&
        _screenEnteredAt == null) {
      _screenEnteredAt = DateTime.now().toUtc();
    }
  }

  String? get currentScreen => _currentScreen;
  String? get currentSection => _currentSection;

  void screenView(String path, {String? entrySource}) {
    final clean = _stripQuery(path);
    final section = sectionForPath(clean);
    final portfolioId = portfolioIdFromPath(clean);
    final template = routeTemplate(clean);
    final name = screenName(clean);

    if (_currentScreen != null && _currentScreen != clean) {
      _closeScreenTiming();
      if (_previousSection != null &&
          _currentSection != null &&
          _previousSection != section) {
        // from_section was previous current before update below
      }
    }

    final fromSection = _currentSection;
    _previousSection = _currentSection;
    _currentScreen = clean;
    _currentSection = section;
    _screenEnteredAt = DateTime.now().toUtc();

    if (!_entryRecorded) {
      _entryRecorded = true;
      _entrySection = section;
      _entryScreen = clean;
      if (entrySource != null && entrySource.isNotEmpty) {
        _entrySource = entrySource;
      } else {
        _entrySource ??= _inferEntrySource(path);
      }
    }

    if (fromSection != null && fromSection != section) {
      _enqueue(
        'section_transition',
        section: section,
        screen: clean,
        extra: {
          'from_section': fromSection,
          'to_section': section,
        },
      );
    }

    _enqueue(
      'screen_view',
      section: section,
      screen: clean,
      portfolioId: portfolioId,
      extra: {
        'screen_name': name,
        'route_template': template,
        if (_entrySection != null) 'entry_section': _entrySection,
        if (_entryScreen != null) 'entry_screen': _entryScreen,
        if (_entrySource != null) 'entry_source': _entrySource,
        if (fromSection != null) 'from_section': fromSection,
        'to_section': section,
      },
    );
  }

  void sessionStart() {
    _enqueue(
      'session_start',
      section: _currentSection,
      screen: _currentScreen,
      extra: {
        if (_entrySection != null) 'entry_section': _entrySection,
        if (_entryScreen != null) 'entry_screen': _entryScreen,
        if (_entrySource != null) 'entry_source': _entrySource,
      },
    );
  }

  void authLogout() {
    _closeScreenTiming(exit: true);
    _enqueue(
      'auth_logout',
      section: _currentSection ?? 'auth',
      screen: _currentScreen,
      extra: {
        if (_currentSection != null) 'exit_section': _currentSection,
        if (_currentScreen != null) 'exit_screen': _currentScreen,
      },
    );
    unawaited(flush());
  }

  void apiTiming({
    required String method,
    required String path,
    required int status,
    required int durationMs,
    String? category,
  }) {
    final clean = _stripQuery(path);
    _enqueue(
      'api_timing',
      section: _currentSection,
      screen: _currentScreen,
      durationMs: durationMs,
      extra: {
        'method': method,
        'path': clean,
        'status': status,
        if (category != null) 'category': category,
      },
      props: {
        'method': method,
        'path': clean,
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
      props: {
        if (total != null) 'totalMs': total,
      },
    );
  }

  void featureAction(
    String action, {
    String? tag,
    String? planCode,
    String? billingInterval,
    Map<String, dynamic>? metadata,
  }) {
    _enqueue(
      'feature_action',
      section: _currentSection,
      screen: _currentScreen,
      portfolioId: portfolioIdFromPath(_currentScreen),
      extra: {
        'action': action,
        if (tag != null) 'tag': tag,
        if (planCode != null) 'plan_code': planCode,
        if (billingInterval != null) 'billing_interval': billingInterval,
      },
      props: {
        'action': action,
        if (tag != null) 'tag': tag,
        if (planCode != null) 'plan_code': planCode,
        if (billingInterval != null) 'billing_interval': billingInterval,
        if (metadata != null)
          ...metadata.map((k, v) => MapEntry(k, v is String || v is num || v is bool ? v : '$v')),
      },
    );
  }

  void widgetTiming({
    required String widget,
    required int durationMs,
    String? operation,
    String? technicalArea,
  }) {
    _enqueue(
      'widget_timing',
      section: _currentSection,
      screen: _currentScreen,
      durationMs: durationMs,
      portfolioId: portfolioIdFromPath(_currentScreen),
      extra: {
        'widget': widget,
        if (operation != null) 'operation': operation,
        if (technicalArea != null) 'technical_area': technicalArea,
        'screen_name': screenName(_currentScreen),
        'route_template': routeTemplate(_currentScreen),
      },
    );
  }

  void feedbackSubmit({
    required num score,
    String? category,
  }) {
    _enqueue(
      'feedback_submit',
      section: _currentSection,
      screen: _currentScreen,
      extra: {
        'feedback_score': score,
        if (category != null) 'feedback_category': category,
      },
    );
  }

  void emptyState(String reason) {
    _enqueue(
      'empty_state',
      section: _currentSection,
      screen: _currentScreen,
      extra: {'empty_reason': reason},
    );
  }

  void clientError({
    required String errorType,
    String? section,
    String? screen,
  }) {
    _enqueue(
      'client_error',
      section: section ?? _currentSection,
      screen: screen ?? _currentScreen,
      extra: {'error_type': errorType},
    );
  }

  void _closeScreenTiming({bool exit = false}) {
    if (_currentScreen == null || _screenEnteredAt == null) return;
    final ms =
        DateTime.now().toUtc().difference(_screenEnteredAt!).inMilliseconds;
    _screenEnteredAt = null;
    if (ms < 0) return;
    _enqueue(
      'screen_timing',
      section: _currentSection,
      screen: _currentScreen,
      durationMs: ms,
      portfolioId: portfolioIdFromPath(_currentScreen),
      extra: {
        'screen_name': screenName(_currentScreen),
        'route_template': routeTemplate(_currentScreen),
        if (exit && _currentSection != null) 'exit_section': _currentSection,
        if (exit && _currentScreen != null) 'exit_screen': _currentScreen,
      },
    );
    if (ms < 2000) {
      // Weak interest / bounce proxy on key product screens.
      _enqueue(
        'feature_action',
        section: _currentSection,
        screen: _currentScreen,
        extra: {
          'action': 'short_dwell',
          'duration_ms': ms,
          'screen_name': screenName(_currentScreen),
        },
      );
    }
  }

  void _enqueue(
    String event, {
    String? section,
    String? screen,
    String? portfolioId,
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
    final cleanScreen = screen == null ? null : _stripQuery(screen);
    _queue.add({
      'event': event,
      'ts': DateTime.now().toUtc().toIso8601String(),
      'anon_id': TelemetryIds.instance.anonId,
      'session_id': TelemetryIds.instance.sessionId,
      if (userId != null && userId.isNotEmpty) 'user_id': userId,
      'platform': TelemetryIds.platformLabel(),
      'env': _envLabel,
      if (section != null) 'section': section,
      if (cleanScreen != null) 'screen': cleanScreen,
      if (cleanScreen != null) 'screen_name': screenName(cleanScreen),
      if (cleanScreen != null) 'route_template': routeTemplate(cleanScreen),
      if (portfolioId != null) 'portfolio_id': portfolioId,
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
      }
    } catch (e) {
      debugPrint('[ProductTelemetry] flush error: $e');
    }
  }

  static String _normalizeEnvLabel(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'development':
      case 'dev':
      case 'local':
        return 'dev';
      case 'preprod':
      case 'staging':
        return 'preprod';
      case 'production':
      case 'prod':
      default:
        return 'prod';
    }
  }

  static String _stripQuery(String path) {
    final i = path.indexOf('?');
    return i < 0 ? path : path.substring(0, i);
  }

  static String? _inferEntrySource(String path) {
    final uri = Uri.tryParse(path.startsWith('http') ? path : 'https://x$path');
    if (uri == null) return null;
    final highlight = uri.queryParameters['highlight'];
    if (highlight == 'subscription') return 'highlight_subscription';
    final utm = uri.queryParameters['utm_source'];
    if (utm != null && utm.isNotEmpty) return 'utm_$utm';
    return null;
  }

  static String routeTemplate(String? path) {
    if (path == null || path.isEmpty) return '';
    return path.replaceAll(_uuidRe, '{id}');
  }

  static String screenName(String? path) {
    final tmpl = routeTemplate(path);
    if (tmpl.isEmpty) return '';
    final parts = tmpl.split('/').where((p) => p.isNotEmpty).toList();
    return parts.isEmpty ? tmpl : parts.last;
  }

  static String? portfolioIdFromPath(String? path) {
    if (path == null) return null;
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 3 &&
        parts[0] == 'app' &&
        (parts[1] == 'trade' || parts[1] == 'portfolio')) {
      final candidate = parts[2];
      if (_uuidRe.hasMatch(candidate)) return candidate;
    }
    return null;
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
    if (p.startsWith('/app/subscription')) return 'subscription';
    if (p.startsWith('/app/profile')) return 'profile';
    return 'other';
  }
}
