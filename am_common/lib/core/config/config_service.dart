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
          baseUrl: 'http://localhost:8001',
          loginEndpoint: '/api/v1/auth/login',
          logoutEndpoint: '/api/v1/auth/logout',
          refreshTokenEndpoint: '/api/v1/auth/refresh',
          googleLoginEndpoint: '/api/v1/auth/google',
          connectTimeout: 30000,
          receiveTimeout: 30000,
          sendTimeout: 30000,
          enabled: true,
        ),
        user: UserApiConfig(
          baseUrl: 'http://localhost:8002',
          registerEndpoint: '/api/v1/user/register',
          forgotPasswordEndpoint: '/api/v1/user/forgot-password',
          resetPasswordEndpoint: '/api/v1/user/reset-password',
          connectTimeout: 30000,
          receiveTimeout: 30000,
          sendTimeout: 30000,
          enabled: true,
        ),
        portfolio: PortfolioApiConfig(
          baseUrl: 'https://am.asrax.in/api/portfolio',
          holdingsResource: '/v1/portfolios/holdings',
          summaryResource: '/v1/portfolios/summary',
          transactionsResource: '/v1/portfolios/transactions',
        ),
        trade: TradeApiConfig(
          baseUrl: 'https://am.asrax.in/api/trade',
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
          baseUrl: 'http://localhost:8080',
          statusEndpoint: '/api/v1/gmail/status',
          connectEndpoint: '/api/v1/gmail/connect',
          extractEndpoint: '/api/v1/gmail/extract',
          enabled: true,
        ),
        marketData: MarketDataConfig(
          wsUrl: 'ws://localhost:8092/ws/market-data-stream',
          baseUrl: 'http://localhost:8092',
          connectEndpoint: '/v1/market-data/stream/connect',
        ),
        analysis: AnalysisApiConfig(
          baseUrl: 'http://localhost:8090',
        ),
      ),
      environment: Environment.development,
    );
  }
}
