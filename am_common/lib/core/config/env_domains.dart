import 'config_service.dart';

/// Central domain registry.
/// 
/// Cluster URLs include the gateway/path prefix (e.g., /market, /auth).
/// Local Overrides (localhost) typically do NOT have the prefix, 
/// as they hit the service port directly.
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
  static String get trades    => ConfigService.override('trades')    ?? '$apiBase/trades';
  static String get analysis  => ConfigService.override('analysis')  ?? '$apiBase/analysis';
  static String get docs      => ConfigService.override('docs')      ?? '$apiBase/doc/processor';
  static String get gmail     => ConfigService.override('gmail')     ?? '$apiBase/gmail';
  static String get etf       => ConfigService.override('etf')       ?? '$apiBase/api/etf';
  
  // WebSocket
  static String get wsStream  => ConfigService.override('wsStream')  ?? '$wsBase/v1/streams';
  static String get marketWs  => ConfigService.override('marketWs')  ?? '$wsBase/market/ws/market-data-stream';
}
