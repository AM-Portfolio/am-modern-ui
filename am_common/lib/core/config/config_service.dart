import 'package:am_common/core/config/app_config.dart';
import 'package:am_library/am_library.dart' show Environment;

/// Application Configuration Service
///
/// Routing Strategy:
///   - LOCAL services (running on this machine):
///       Analysis  → http://localhost:8061
///       Portfolio  → http://localhost:8072
///       Gateway    → http://localhost:8091  (WebSocket / STOMP)
///   - PRODUCTION services (not running locally):
///       Auth       → https://am.munish.org/auth
///       User       → https://am.munish.org/users
///       Trade      → https://am.munish.org/trade
///       Gmail      → https://am.munish.org/gmail
///       MarketData → https://am.munish.org/market
class ConfigService {
  static AppConfig? _config;

  static AppConfig get config {
    if (_config == null) {
      throw StateError('ConfigService not initialized. Call initialize() first.');
    }
    return _config!;
  }

  static Future<void> initialize() async {
    if (_config != null) return; // Already initialized

    _config = AppConfig(
      google: GoogleConfig(
        webClientId: const String.fromEnvironment('AM_GOOGLE_CLIENT_ID', defaultValue: 'your-client-id'),
      ),
      api: ApiConfig(
        // Default base URL used by ApiClient when no specific service URL is provided
        baseUrl: const String.fromEnvironment('AM_API_BASE_URL', defaultValue: 'https://am.munish.org/analysis'),
        timeout: 30000,
        useMockData: const bool.fromEnvironment('AM_USE_MOCK_DATA', defaultValue: false),

        // ── Auth (PRODUCTION — not running locally) ──
        auth: AuthApiConfig(
          baseUrl: const String.fromEnvironment('AM_AUTH_BASE_URL', defaultValue: 'https://am.munish.org/auth'),
          loginEndpoint: '/v1/auth/login',
          logoutEndpoint: '/v1/auth/logout',
          refreshTokenEndpoint: '/v1/auth/refresh',
          googleLoginEndpoint: '/v1/auth/google',
          connectTimeout: 30000,
          receiveTimeout: 30000,
          sendTimeout: 30000,
          enabled: true,
        ),

        // ── User Management (PRODUCTION — not running locally) ──
        user: UserApiConfig(
          baseUrl: const String.fromEnvironment('AM_USER_BASE_URL', defaultValue: 'https://am.munish.org/users'),
          registerEndpoint: '/v1/user/register',
          forgotPasswordEndpoint: '/v1/user/forgot-password',
          resetPasswordEndpoint: '/v1/user/reset-password',
          connectTimeout: 30000,
          receiveTimeout: 30000,
          sendTimeout: 30000,
          enabled: true,
        ),

        // ── Portfolio (PRODUCTION — local 8072 has MappingException bug) ──
        portfolio: PortfolioApiConfig(
          baseUrl: const String.fromEnvironment('AM_PORTFOLIO_BASE_URL', defaultValue: 'https://am.munish.org/portfolio'),
          holdingsResource: '/v1/portfolios/holdings',
          summaryResource: '/v1/portfolios/summary',
          transactionsResource: '/v1/portfolios/transactions',
          listResource: '/v1/portfolios/list',
        ),

        // ── Trade (PRODUCTION — not running locally) ──
        trade: TradeApiConfig(
          baseUrl: const String.fromEnvironment('AM_TRADE_BASE_URL', defaultValue: 'https://am.munish.org/trade'),
          portfolioListResource: '/v1/portfolio-summary/by-owner',
          portfolioSummaryResource: '/v1/portfolio-summary',
          holdingsResource: '/v1/trades/details/portfolio',
          tradeDetailsResource: '/v1/trades/details',
          calendarMonthResource: '/v1/trades/calendar/month',
          calendarDayResource: '/v1/trades/calendar/day',
          calendarQuarterResource: '/v1/trades/calendar/quarter',
          calendarFinancialYearResource: '/v1/trades/calendar/financial-year',
          searchResource: '/v1/trades/search',
          connectTimeout: 30000,
          receiveTimeout: 30000,
          sendTimeout: 30000,
          enabled: true,
        ),

        // ── Gmail (PRODUCTION — not running locally) ──
        gmail: GmailApiConfig(
          baseUrl: const String.fromEnvironment('AM_GMAIL_BASE_URL', defaultValue: 'https://am.munish.org/gmail'),
          statusEndpoint: '/v1/gmail/status',
          connectEndpoint: '/v1/gmail/connect',
          extractEndpoint: '/v1/gmail/extract',
          enabled: true,
        ),

        // ── Market Data & WebSocket (PRODUCTION — Gateway WS not stable locally) ──
        marketData: MarketDataConfig(
          wsUrl: const String.fromEnvironment('AM_MARKET_WS_URL', defaultValue: 'wss://am.munish.org/market/ws/market-data-stream'),
          baseUrl: const String.fromEnvironment('AM_MARKET_BASE_URL', defaultValue: 'https://am.munish.org/market'),
          connectEndpoint: '/v1/market-data/stream/connect',
        ),

        // ── Analysis (PRODUCTION — fallback from localhost) ──
        analysis: AnalysisApiConfig(
          baseUrl: const String.fromEnvironment('AM_ANALYSIS_BASE_URL', defaultValue: 'https://am.munish.org/analysis'),
        ),
      ),
      environment: Environment.development,
    );
  }
}
