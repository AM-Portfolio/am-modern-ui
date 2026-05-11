// import 'package:am_common/core/constants/constants.dart';
import 'package:am_library/am_library.dart' show Environment;

/// Application configuration
class AppConfig {
  const AppConfig({
    required this.api,
    required this.environment,
    required this.google,
    this.appName = 'AM App',
    this.version = '1.0.0',
    this.debugMode = true,
    this.defaultPort = 8080,
    this.devAuthToken,
    this.devUserId,
  });
  final String appName;
  final String version;
  final bool debugMode;
  final int defaultPort;
  final ApiConfig api;
  final Environment environment;
  final GoogleConfig google;
  final String? devAuthToken;
  final String? devUserId;
}

/// Cloudinary API configuration
class CloudinaryApiConfig {
  const CloudinaryApiConfig({
    required this.baseUrl,
    this.connectTimeout = 30,
    this.receiveTimeout = 60,
    this.sendTimeout = 60,
    this.enabled = true,
  });
  final String baseUrl;
  final int connectTimeout;
  final int receiveTimeout;
  final int sendTimeout;
  final bool enabled;
}

/// API configuration
class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    required this.timeout,
    required this.useMockData,
    required this.portfolio,
    required this.trade,
    this.document,
    this.cloudinary,
    this.marketData,
    this.auth,
    this.user,
    this.gmail,
    this.analysis,
  });
  final String baseUrl;
  final int timeout;
  final bool useMockData;
  final PortfolioApiConfig portfolio;
  final TradeApiConfig trade;
  final DocumentApiConfig? document;
  final CloudinaryApiConfig? cloudinary;
  final MarketDataConfig? marketData;
  final AuthApiConfig? auth;
  final UserApiConfig? user;
  final GmailApiConfig? gmail;
  final AnalysisApiConfig? analysis;
}

/// Analysis & Dashboard API configuration
class AnalysisApiConfig {
  const AnalysisApiConfig({
    required this.baseUrl,
    this.summaryResource = '/v1/analysis/dashboard/summary',
    this.overviewsResource = '/v1/analysis/dashboard/portfolio-overviews',
    this.recentActivityResource = '/v1/analysis/dashboard/recent-activity',
    this.performanceResource = '/v1/analysis/dashboard/performance',
    this.topMoversResource = '/v1/analysis/dashboard/top-movers',
    this.connectTimeout = 30000,
    this.receiveTimeout = 30000,
    this.sendTimeout = 30000,
    this.enabled = true,
  });
  final String baseUrl;
  final String summaryResource;
  final String overviewsResource;
  final String recentActivityResource;
  final String performanceResource;
  final String topMoversResource;
  final int connectTimeout;
  final int receiveTimeout;
  final int sendTimeout;
  final bool enabled;
}

/// Gmail Sync API configuration
class GmailApiConfig {
  const GmailApiConfig({
    required this.baseUrl,
    required this.statusEndpoint,
    required this.connectEndpoint,
    required this.extractEndpoint,
    this.connectTimeout = 30,
    this.receiveTimeout = 60,
    this.sendTimeout = 60,
    this.enabled = true,
  });
  final String baseUrl;
  final String statusEndpoint;
  final String connectEndpoint;
  final String extractEndpoint;
  final int connectTimeout;
  final int receiveTimeout;
  final int sendTimeout;
  final bool enabled;
}

/// Portfolio API configuration
class PortfolioApiConfig {
  const PortfolioApiConfig({
    required this.baseUrl,
    required this.holdingsResource,
    required this.summaryResource,
    required this.transactionsResource,
  });
  final String baseUrl;
  final String holdingsResource;
  final String summaryResource;
  final String transactionsResource;
}

/// Trade API configuration
class TradeApiConfig {
  const TradeApiConfig({
    required this.baseUrl,
    required this.portfolioListResource,
    required this.portfolioSummaryResource,
    required this.holdingsResource,
    required this.tradeDetailsResource,
    required this.calendarMonthResource,
    required this.calendarDayResource,
    required this.calendarQuarterResource,
    required this.calendarFinancialYearResource,
    required this.searchResource,
    this.connectTimeout = 30,
    this.receiveTimeout = 60,
    this.sendTimeout = 60,
    this.enabled = true,
  });
  final String baseUrl;
  final String portfolioListResource;
  final String portfolioSummaryResource;
  final String holdingsResource;
  final String tradeDetailsResource;
  final String calendarMonthResource;
  final String calendarDayResource;
  final String calendarQuarterResource;
  final String calendarFinancialYearResource;
  final String searchResource;
  final int connectTimeout;
  final int receiveTimeout;
  final int sendTimeout;
  final bool enabled;
}

/// Document API configuration
/// Note: With Retrofit, only baseUrl and client settings can be configured dynamically
/// API endpoints are hardcoded in @RestApi() annotations
class DocumentApiConfig {
  const DocumentApiConfig({
    required this.baseUrl,
    this.connectTimeout = 30,
    this.receiveTimeout = 60,
    this.sendTimeout = 60,
    this.enabled = true,
  });
  final String baseUrl;
  final int connectTimeout;
  final int receiveTimeout;
  final int sendTimeout;
  final bool enabled;
}

/// Google Sign-In configuration
class GoogleConfig {
  const GoogleConfig({required this.webClientId});
  final String webClientId;

  /// Check if Google Sign-In is configured
  bool get isConfigured => webClientId.isNotEmpty;
}

/// Authentication API configuration
class AuthApiConfig {
  const AuthApiConfig({
    required this.baseUrl,
    required this.loginEndpoint,
    required this.refreshTokenEndpoint,
    required this.logoutEndpoint,
    required this.googleLoginEndpoint,
    this.connectTimeout = 30,
    this.receiveTimeout = 60,
    this.sendTimeout = 60,
    this.enabled = true,
  });
  final String baseUrl;
  final String loginEndpoint;
  final String refreshTokenEndpoint;
  final String logoutEndpoint;
  final String googleLoginEndpoint;
  final int connectTimeout;
  final int receiveTimeout;
  final int sendTimeout;
  final bool enabled;
}

/// User Management API configuration
class UserApiConfig {
  const UserApiConfig({
    required this.baseUrl,
    required this.registerEndpoint,
    required this.forgotPasswordEndpoint,
    required this.resetPasswordEndpoint,
    this.connectTimeout = 30,
    this.receiveTimeout = 60,
    this.sendTimeout = 60,
    this.enabled = true,
  });
  final String baseUrl;
  final String registerEndpoint;
  final String forgotPasswordEndpoint;
  final String resetPasswordEndpoint;
  final int connectTimeout;
  final int receiveTimeout;
  final int sendTimeout;
  final bool enabled;
}

/// Market Data API configuration
class MarketDataConfig {
  const MarketDataConfig({
    required this.wsUrl,
    required this.baseUrl,
    required this.connectEndpoint,
    this.connectTimeout = 30,
    this.enabled = true,
  });
  final String wsUrl;
  final String baseUrl;
  final String connectEndpoint;
  final int connectTimeout;
  final bool enabled;
}
