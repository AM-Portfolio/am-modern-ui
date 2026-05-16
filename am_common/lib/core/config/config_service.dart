import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:am_library/am_library.dart';
import 'app_config.dart';

/// Service responsible for loading and managing application configuration.
/// Supports a 3-layer resolution:
/// 1. config.local.json (Local developer overrides)
/// 2. config.json (Kubernetes ConfigMap domain)
/// 3. Built-in fallback (am.asrax.in)
class ConfigService {
  static AppConfig? _config;
  static String _domain = 'am-dev.asrax.in';       // Layer 3 fallback: Default to DEV
  static Map<String, String> _overrides = {};       // Layer 1 local overrides

  // ─── Public API ─────────────────────────────────────────────────────────

  /// The root domain (from config.json or fallback)
  static String get domain => _domain;

  /// Per-service override, e.g. override('market') → 'http://localhost:8092'
  /// Returns null if no override exists for this key.
  static String? override(String key) => _overrides[key];

  /// Get the current application configuration.
  static AppConfig get config {
    if (_config == null) {
      // Return a default config instead of throwing to prevent crashes
      return _buildConfig();
    }
    return _config!;
  }

  /// Initialize application configuration.
  /// Typically called during app startup.
  static Future<void> initialize() async {
    if (_config != null) return;

    // Layer 1: load local developer overrides (gitignored file)
    await _loadLocalOverrides();

    // Layer 2: load environment domain from Kubernetes ConfigMap
    await _loadRemoteConfig();

    // Build and cache AppConfig
    _config = _buildConfig();
  }

  // ─── Private ─────────────────────────────────────────────────────────────

  /// Tries to fetch /config.local.json — gitignored, only on dev machines.
  static Future<void> _loadLocalOverrides() async {
    try {
      final res = await http.get(Uri.parse('/config.local.json'))
                    .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        
        // 1. Domain can be overridden locally (e.g. switch between dev/preprod cluster)
        _domain = json['domain'] as String? ?? _domain;

        // 2. Service overrides (e.g. localhost)
        final bool useOverrides = json['useOverrides'] as bool? ?? false;
        
        if (useOverrides) {
          final raw = json['overrides'] as Map<String, dynamic>? ?? {};
          _overrides = raw.map((k, v) => MapEntry(k, v.toString()));
          AppLogger.info('🔧 Local service overrides ENABLED (domain: $_domain)',
                         tag: 'ConfigService');
        } else {
          AppLogger.info('ℹ️ Using cluster domain: $_domain (local overrides disabled)',
                         tag: 'ConfigService');
        }
      }
    } catch (_) {
      // Not present — normal in staging/prod/CI
    }
  }

  /// Fetches /config.json mounted by Kubernetes ConfigMap.
  static Future<void> _loadRemoteConfig() async {
    try {
      final res = await http.get(Uri.parse('/config.json'))
                    .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        _domain = (json['domain'] as String?) ?? _domain;
        AppLogger.info('🌐 Domain loaded from config.json: $_domain', tag: 'ConfigService');
      }
    } catch (_) {
      AppLogger.warning('⚠️ config.json not found — using fallback: $_domain',
                        tag: 'ConfigService');
    }
  }

  static AppConfig _buildConfig() {
    final api = 'https://$_domain';
    final ws  = 'wss://$_domain';
    
    // Base URLs respect overrides
    final authUrl      = _overrides['auth']      ?? '$api/auth';
    final usersUrl     = _overrides['users']     ?? '$api/users';
    final portfolioUrl = _overrides['portfolio'] ?? '$api/portfolio';
    final marketUrl    = _overrides['market']    ?? '$api/market';
    final tradesUrl    = _overrides['trades']    ?? '$api/trades';
    final analysisUrl  = _overrides['analysis']  ?? '$api/analysis';
    final gmailUrl     = _overrides['gmail']     ?? '$api/gmail';
    final marketWsUrl  = _overrides['marketWs']  ?? '$ws/market/ws/market-data-stream';

    return AppConfig(
      google: const GoogleConfig(webClientId: ''),
      environment: Environment.production,
      api: ApiConfig(
        baseUrl: analysisUrl,
        timeout: 30000,
        useMockData: false,
        auth: AuthApiConfig(
          baseUrl: authUrl,
          loginEndpoint: '/v1/tokens',
          logoutEndpoint: '/v1/auth/logout',
          refreshTokenEndpoint: '/v1/auth/refresh',
          googleLoginEndpoint: '/v1/auth/google/token',
        ),
        user: UserApiConfig(
          baseUrl: usersUrl,
          registerEndpoint: '/v1/auth/register',
          forgotPasswordEndpoint: '/v1/auth/request-reset',
          resetPasswordEndpoint: '/v1/auth/confirm-reset',
        ),
        portfolio: PortfolioApiConfig(
          baseUrl: portfolioUrl,
          holdingsResource: '/v1/portfolios/holdings',
          summaryResource: '/v1/portfolios/summary',
          transactionsResource: '/v1/portfolios/transactions',
        ),
        trade: TradeApiConfig(
          baseUrl: tradesUrl,
          portfolioListResource: '/v1/portfolio-summary/by-owner',
          portfolioSummaryResource: '/v1/portfolio-summary',
          holdingsResource: '/v1/trades/details/portfolio',
          tradeDetailsResource: '/v1/trades/details',
          calendarMonthResource: '/v1/trades/calendar/month',
          calendarDayResource: '/v1/trades/calendar/day',
          calendarQuarterResource: '/v1/trades/calendar/quarter',
          calendarFinancialYearResource: '/v1/trades/calendar/financial-year',
          searchResource: '/v1/trades/search',
        ),
        marketData: MarketDataConfig(
          baseUrl: marketUrl,
          wsUrl: marketWsUrl,
          connectEndpoint: '/v1/market-data/stream/connect',
        ),
        analysis: AnalysisApiConfig(baseUrl: analysisUrl),
        gmail: GmailApiConfig(
          baseUrl: gmailUrl,
          statusEndpoint: '/v1/gmail/status',
          connectEndpoint: '/v1/gmail/connect',
          extractEndpoint: '/v1/gmail/extract',
        ),
      ),
    );
  }
}
