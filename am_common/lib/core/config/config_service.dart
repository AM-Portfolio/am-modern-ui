import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:am_library/am_library.dart';
import '../telemetry/boot_trace.dart';
import 'app_config.dart';

/// Loads web config: [config.template.json] defaults, then [config.{env}.json],
/// then [config.json] (env selector locally, domain override in Kubernetes).
class ConfigService {
  static AppConfig? _config;
  static const _envFromDefine = String.fromEnvironment('AM_ENV');
  static const _domainFromDefine = String.fromEnvironment('AM_DOMAIN');
  /// No baked env host. Prefer same-tab host on web until Helm/config loads.
  static String _domain = _bootstrapDomain();
  static String _resolvedEnv = _envFromDefine;
  static Map<String, String> _services = {};
  static String _googleClientId = '';

  /// Cluster: browser host (am-dev / am-preprod / am.asrax.in). Localhost → empty.
  static String _bootstrapDomain() {
    final host = Uri.base.host;
    if (host.isNotEmpty &&
        host != 'localhost' &&
        host != '127.0.0.1' &&
        !host.endsWith('.local')) {
      return host;
    }
    return '';
  }

  static String get domain => _domain;

  /// Per-service URL override (localhost or full gateway path).
  static String? override(String key) => _services[key];

  static AppConfig get config {
    if (_config == null) {
      return _buildConfig();
    }
    return _config!;
  }

  static Future<void> initialize() async {
    if (_config != null) return;

    BootTrace.instance.mark('config_start');
    final merged = await _loadMergedConfig();
    _applyMergedConfig(merged);
    _config = _buildConfig();
    BootTrace.instance.mark('config_done');
  }

  static Future<Map<String, dynamic>> _loadMergedConfig() async {
    final parallel = await Future.wait([
      _fetchJson('/config.template.json'),
      _fetchJson('/config.json'),
    ]);

    var merged = parallel[0] ??
        <String, dynamic>{
          'domain': _domain,
          'services': <String, dynamic>{},
        };

    final bootstrap = parallel[1];
    // Runtime Helm/bootstrap `env` wins over compile-time AM_ENV so one image
    // can load config.dev.json / config.preprod.json per namespace.
    final bootstrapEnv = bootstrap?['env'] as String?;
    final env = (bootstrapEnv != null && bootstrapEnv.isNotEmpty)
        ? bootstrapEnv
        : (_envFromDefine.isNotEmpty ? _envFromDefine : null);
    _resolvedEnv = env ?? _resolvedEnv;
    if (env != null && env.isNotEmpty) {
      final envConfig = await _fetchJson('/config.$env.json');
      if (envConfig != null) {
        merged = _deepMerge(merged, envConfig);
      } else {
        AppLogger.warning(
          'config.$env.json not found — using template only',
          tag: 'ConfigService',
        );
      }
    }
    if (bootstrap != null) {
      merged = _deepMerge(merged, bootstrap);
    }

    return merged;
  }

  static void _applyMergedConfig(Map<String, dynamic> json) {
    // Priority: Helm/config.json domain → local AM_DOMAIN (.env) → browser host.
    // Never keep a compile-time host over runtime Helm config.
    final jsonDomain = json['domain'] as String?;
    if (jsonDomain != null && jsonDomain.isNotEmpty) {
      _domain = jsonDomain;
    } else if (_domainFromDefine.isNotEmpty) {
      _domain = _domainFromDefine;
    } else if (_domain.isEmpty) {
      _domain = _bootstrapDomain();
    }

    final raw = json['services'] as Map<String, dynamic>? ??
        json['overrides'] as Map<String, dynamic>? ??
        {};
    _services = raw.map(
      (k, v) => MapEntry(k, v?.toString() ?? ''),
    )..removeWhere((_, v) => v.isEmpty);

    // Extract Google Sign-In Web Client ID dynamically
    final google = json['google'] as Map<String, dynamic>?;
    if (google != null) {
      _googleClientId = google['webClientId']?.toString() ??
          google['clientId']?.toString() ??
          '';
    } else if (json['googleWebClientId'] != null) {
      _googleClientId = json['googleWebClientId'].toString();
    }

    final envLabel = _resolvedEnv.isNotEmpty ? _resolvedEnv : 'default';
    if (_services.isEmpty) {
      AppLogger.info(
        'Config resolved: env=$envLabel, domain=$_domain (gateway paths)',
        tag: 'ConfigService',
      );
    } else {
      AppLogger.info(
        'Config resolved: env=$envLabel, domain=$_domain, ${_services.length} local service URL(s)',
        tag: 'ConfigService',
      );
    }
  }

  static Future<Map<String, dynamic>?> _fetchJson(String path) async {
    final fetchSw = Stopwatch()..start();
    try {
      final uri = Uri.base.resolve(path).replace(
        queryParameters: {
          'cb': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final res =
          await http.get(uri).timeout(const Duration(milliseconds: 1500));
      fetchSw.stop();
      BootTrace.instance.mark(
        'config_fetch_done',
        meta: {
          'path': path,
          'status': res.statusCode,
          'ms': fetchSw.elapsedMilliseconds,
        },
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      fetchSw.stop();
      BootTrace.instance.mark(
        'config_fetch_done',
        meta: {
          'path': path,
          'error': e.toString(),
          'ms': fetchSw.elapsedMilliseconds,
        },
      );
      // Optional file — normal in CI or when template is bundled only
    }
    return null;
  }

  static Map<String, dynamic> _deepMerge(
    Map<String, dynamic> base,
    Map<String, dynamic> overlay,
  ) {
    final result = Map<String, dynamic>.from(base);
    for (final entry in overlay.entries) {
      if (entry.key.startsWith('_')) continue;
      final value = entry.value;
      final existing = result[entry.key];
      if (value is Map<String, dynamic> &&
          existing is Map<String, dynamic>) {
        result[entry.key] = _deepMerge(existing, value);
      } else {
        result[entry.key] = value;
      }
    }
    return result;
  }

  static AppConfig _buildConfig() {
    final host = _domain.isNotEmpty ? _domain : _bootstrapDomain();
    final api = host.isNotEmpty ? 'https://$host' : Uri.base.origin;
    final wsScheme = api.startsWith('https') ? 'wss' : 'ws';
    final wsHost = host.isNotEmpty ? host : Uri.base.host;
    final ws = wsHost.isNotEmpty ? '$wsScheme://$wsHost' : api.replaceFirst(RegExp(r'^http'), 'ws');

    final authUrl = _services['auth'] ??
        _services['identity'] ??
        '$api/identity';
    final usersUrl = _services['users'] ?? '$api/users';
    final portfolioUrl = _services['portfolio'] ?? '$api/portfolio';
    final marketUrl = _services['market'] ?? '$api/market';
    final tradesUrl = _services['trade'] ??
        _services['trades'] ??
        '$api/trade';
    final analysisUrl = _services['analysis'] ?? '$api/analysis';
    final gmailUrl = _services['gmail'] ?? '$api/gmail';
    final marketWsUrl =
        _services['marketWs'] ?? '$ws/market/ws/market-data-stream';

    return AppConfig(
      google: GoogleConfig(webClientId: _googleClientId),
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
