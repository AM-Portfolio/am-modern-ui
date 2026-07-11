import 'config_service.dart';

/// Central domain registry.
///
/// Cluster URLs use the gateway path prefix (e.g. /market, /auth).
/// Local [config.*.json] `services` entries are full base URLs (no prefix).
/// 
/// All module paths should start with '/v1' or the relative resource path.
class EnvDomains {
  static String get _domain => ConfigService.domain;

  static String get apiBase => 'https://$_domain';
  static String get wsBase  => 'wss://$_domain';

  // Service Base URLs (respecting overrides for Local Dev)
  static String get auth      => ConfigService.override('auth')      ?? '$apiBase/auth';
  static String get users     => ConfigService.override('users')     ?? '$apiBase/users';
  static String get portfolio => ConfigService.override('portfolio') ?? '$apiBase/portfolio';
  static String get market    => ConfigService.override('market')    ?? '$apiBase/market';
  static String get trades =>
      ConfigService.override('trade') ??
      ConfigService.override('trades') ??
      '$apiBase/trade';
  static String get analysis  => ConfigService.override('analysis')  ?? '$apiBase/analysis';
  static String get docs      => ConfigService.override('docs')      ?? '$apiBase/doc/processor';
  static String get gmail     => ConfigService.override('gmail')     ?? '$apiBase/gmail';
  static String get etf       => ConfigService.override('etf')       ?? '$apiBase/api/etf';
  static String get subscription => ConfigService.override('subscription') ?? '$apiBase/subscriptions';
  
  // WebSocket — all real-time UI uses am-gateway STOMP
  static String get wsStream  => ConfigService.override('wsStream')  ?? '$wsBase/v1/streams';

  /// Deprecated: use [wsStream]. Market prices now relay via gateway `/topic/stock/{symbol}`.
  @Deprecated('Use wsStream via AmStompClient instead of direct am-market WebSocket')
  static String get marketWs  => ConfigService.override('marketWs')  ?? '$wsBase/market/ws/market-data-stream';
}
