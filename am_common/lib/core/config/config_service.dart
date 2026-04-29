import 'package:am_common/core/config/app_config.dart';
import 'package:am_library/am_library.dart';

/// Minimal stub ConfigService for getting app running
/// TODO: Replace with full implementation later
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
    
    // Create minimal hardcoded config with ALL required parameters
    _config = AppConfig(
      google: GoogleConfig(
        webClientId: 'your-client-id',
      ),
      api: ApiConfig(
        baseUrl: 'http://localhost:8001',
        timeout: 30000,
        useMockData: true,
        auth: AuthApiConfig(
          baseUrl: 'https://am.asrax.in/auth',
          loginEndpoint: '/v1/auth/login',
          logoutEndpoint: '/v1/auth/logout',
          refreshTokenEndpoint: '/v1/auth/refresh',
          googleLoginEndpoint: '/v1/auth/google',
          connectTimeout: 30000,
          receiveTimeout: 30000,
          sendTimeout: 30000,
          enabled: true,
        ),
        user: UserApiConfig(
          baseUrl: 'https://am.asrax.in/users',
          registerEndpoint: '/v1/user/register',
          forgotPasswordEndpoint: '/v1/user/forgot-password',
          resetPasswordEndpoint: '/v1/user/reset-password',
          connectTimeout: 30000,
          receiveTimeout: 30000,
          sendTimeout: 30000,
          enabled: true,
        ),
        portfolio: PortfolioApiConfig(
          baseUrl: 'https://am.asrax.in/portfolio',
          holdingsResource: '/v1/portfolios/holdings',
          summaryResource: '/v1/portfolios/summary',
          transactionsResource: '/v1/portfolios/transactions',
        ),
        trade: TradeApiConfig(
          baseUrl: 'https://am.asrax.in/trade',
          portfolioListResource: '/v1/portfolio-summary/by-owner',
          portfolioSummaryResource: '/v1/portfolio-summary',
          holdingsResource: '/v1/trades/details/portfolio',
          tradeDetailsResource: '/v1/trades',
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
        gmail: GmailApiConfig(
          baseUrl: 'https://am.asrax.in/gmail',
          statusEndpoint: '/v1/gmail/status',
          connectEndpoint: '/v1/gmail/connect',
          extractEndpoint: '/v1/gmail/extract',
          enabled: true,
        ),
        marketData: MarketDataConfig(
          wsUrl: 'wss://am.asrax.in/market/ws/market-data-stream',
          baseUrl: 'https://am.asrax.in/market',
          connectEndpoint: '/v1/market-data/stream/connect',
        ),
        analysis: AnalysisApiConfig(
          baseUrl: 'https://am.asrax.in/analysis',
        ),
      ),
      environment: Environment.development,
    );
  }
}
