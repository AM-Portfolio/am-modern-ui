import 'config_service.dart';

/// Central domain registry.
///
/// Cluster: host from Helm-mounted config.json (via [ConfigService]).
/// Local: `.env` dart-defines and/or config.{env}.json `domain` / `services`.
/// No environment host is hardcoded here (native falls back via [ConfigService]).
class EnvDomains {
  static String get _domain => ConfigService.domain;

  /// [Uri.origin] throws for `file:///` (Android/iOS).
  static String? _httpOrigin() {
    final uri = Uri.base;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    try {
      final origin = uri.origin;
      return origin.isNotEmpty ? origin : null;
    } catch (_) {
      return null;
    }
  }

  static String get apiBase {
    if (_domain.isNotEmpty) return 'https://$_domain';
    final origin = _httpOrigin();
    if (origin != null && !origin.contains('://localhost')) return origin;
    return origin ?? '';
  }

  static String get wsBase {
    if (_domain.isNotEmpty) return 'wss://$_domain';
    final origin = _httpOrigin();
    if (origin == null) return '';
    if (origin.startsWith('https://')) {
      return 'wss://${Uri.base.host}${Uri.base.hasPort ? ':${Uri.base.port}' : ''}';
    }
    if (origin.startsWith('http://')) {
      return 'ws://${Uri.base.host}${Uri.base.hasPort ? ':${Uri.base.port}' : ''}';
    }
    return '';
  }

  // Service Base URLs (respecting overrides for Local Dev)
  static String get auth =>
      ConfigService.override('auth') ??
      ConfigService.override('identity') ??
      '$apiBase/identity';
  static String get users => ConfigService.override('users') ?? '$apiBase/users';
  static String get portfolio =>
      ConfigService.override('portfolio') ?? '$apiBase/portfolio';
  static String get market => ConfigService.override('market') ?? '$apiBase/market';
  static String get trades =>
      ConfigService.override('trade') ??
      ConfigService.override('trades') ??
      '$apiBase/trade';
  static String get analysis =>
      ConfigService.override('analysis') ?? '$apiBase/analysis';
  static String get docs =>
      ConfigService.override('docs') ?? '$apiBase/doc/processor';
  static String get gmail => ConfigService.override('gmail') ?? '$apiBase/gmail';
  static String get etf => ConfigService.override('etf') ?? '$apiBase/api/etf';
  static String get subscription =>
      ConfigService.override('subscription') ?? '$apiBase/subscriptions';

  // WebSocket — all real-time UI uses am-gateway STOMP
  static String get wsStream =>
      ConfigService.override('wsStream') ?? '$wsBase/v1/streams';

  /// Deprecated: use [wsStream].
  @Deprecated('Use wsStream via AmStompClient instead of direct am-market WebSocket')
  static String get marketWs =>
      ConfigService.override('marketWs') ??
      '$wsBase/market/ws/market-data-stream';
}
