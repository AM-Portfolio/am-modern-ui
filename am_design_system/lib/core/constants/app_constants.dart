/// Application configuration constants
/// All configuration values should be defined here instead of passing as parameters
class AppConstants {
  /// Application Information
  static const String appName = 'AM Investment';
  static const String appVersion = '1.0.0';
  static const int defaultPort = 3000;

  /// Asset Paths
  static const String assetsPath = 'lib/assets';
  static const String imagesPath = '$assetsPath/images';
  static const String mockDataPath = '$assetsPath/mock_data';

  /// Configuration Files
  static const String mainPropertiesFile = 'lib/assets/application.properties';
  static const String devPropertiesFile =
      'lib/assets/application-dev.properties';
  static const String prodPropertiesFile =
      'lib/assets/application-prod.properties';
  static const String testPropertiesFile =
      'lib/assets/application-test.properties';
  static const String stagingPropertiesFile =
      'lib/assets/application-staging.properties';

  /// Default Environment
  static const String defaultEnvironment = 'dev';

  /// API Configuration
  static const String defaultBaseUrl = 'https://am.asrax.in/portfolio';
  static const int defaultTimeout = 30000;
  static const bool defaultUseMockData = true;

  /// Portfolio API Defaults
  static const String defaultPortfolioBaseUrl = 'https://am.asrax.in/portfolio';
  static const String defaultHoldingsResource = '/v1/portfolios/holdings';
  static const String defaultSummaryResource = '/v1/portfolios/summary';
  static const String defaultTransactionsResource =
      '/v1/portfolios/transactions';

  /// Trade API Defaults
  static const String defaultTradeBaseUrl = 'https://am.asrax.in/trades';
  static const String defaultTradePortfolioListResource =
      '/v1/portfolio-summary/by-owner';
  static const String defaultTradePortfolioSummaryResource =
      '/v1/portfolio-summary';
  static const String defaultTradeHoldingsResource =
      '/v1/trades/portfolio-details';
  static const String defaultTradeDetailsResource =
      '/v1/trades/details/by-ids';
  static const String defaultTradeCalendarMonthResource =
      '/v1/trades/calendar/{portfolioId}/month';
  static const String defaultTradeCalendarDayResource =
      '/v1/trades/calendar/{portfolioId}/day';
  static const String defaultTradeCalendarQuarterResource =
      '/v1/trades/calendar/{portfolioId}/quarter';
  static const String defaultTradeCalendarFinancialYearResource =
      '/v1/trades/calendar/{portfolioId}/financial-year';
  static const String defaultTradeSearchResource = '/v1/trades/search';
  static const int defaultTradeConnectTimeout = 30;
  static const int defaultTradeReceiveTimeout = 60;
  static const int defaultTradeSendTimeout = 60;
  static const bool defaultTradeEnabled = true;

  /// Document API Defaults
  static const String defaultDocumentBaseUrl = 'https://am.asrax.in/documents';
  static const int defaultConnectTimeout = 30;
  static const int defaultReceiveTimeout = 60;
  static const int defaultSendTimeout = 60;
  static const bool defaultDocumentEnabled = true;

  /// Auth API Defaults
  static const String defaultAuthBaseUrl = 'https://am.asrax.in/auth/token/v1';
  // Endpoints are relative to Auth Base URL
  static const String defaultAuthLoginEndpoint = '/tokens';
  static const String defaultAuthRefreshTokenEndpoint = '/refresh';
  static const String defaultAuthLogoutEndpoint = '/logout';
  static const String defaultAuthGoogleLoginEndpoint = '/google/token';
  static const bool defaultAuthEnabled = true;

  /// User API Defaults
  static const String defaultUserBaseUrl = 'https://am.asrax.in/users/account/v1';
  static const String defaultUserRegisterEndpoint = '/register';
  static const String defaultUserForgotPasswordEndpoint = '/forgot-password';
  static const String defaultUserResetPasswordEndpoint = '/reset-password';
  static const bool defaultUserEnabled = true;

  /// Environment Configuration
  static const String defaultEnvironmentName = 'development';
  static const bool defaultDebugMode = true;
  static const String defaultLogLevel = 'debug';

  /// Google Sign-In Configuration
  static const String defaultGoogleWebClientId = '';
}

/// Property keys used in configuration files
class PropertyKeys {
  // Application properties
  static const String appDefaultPort = 'app.default.port';

  // API properties
  static const String apiBaseUrl = 'api.baseUrl';
  static const String apiTimeout = 'api.timeout';
  static const String mockDataEnabled = 'mock.data.enabled';

  // Portfolio API properties
  static const String apiPortfolioBaseUrl = 'api.portfolio.baseUrl';
  static const String apiPortfolioHoldingsResource =
      'api.portfolio.holdingsResource';
  static const String apiPortfolioSummaryResource =
      'api.portfolio.summaryResource';
  static const String apiPortfolioTransactionsResource =
      'api.portfolio.transactionsResource';

  // Trade API properties
  static const String apiTradeBaseUrl = 'api.trade.baseUrl';
  static const String apiTradePortfolioListResource =
      'api.trade.portfolioListResource';
  static const String apiTradePortfolioSummaryResource =
      'api.trade.portfolioSummaryResource';
  static const String apiTradeHoldingsResource = 'api.trade.holdingsResource';
  static const String apiTradeDetailsResource =
      'api.trade.tradeDetailsResource';
  static const String apiTradeCalendarMonthResource =
      'api.trade.calendarMonthResource';
  static const String apiTradeCalendarDayResource =
      'api.trade.calendarDayResource';
  static const String apiTradeCalendarQuarterResource =
      'api.trade.calendarQuarterResource';
  static const String apiTradeCalendarFinancialYearResource =
      'api.trade.calendarFinancialYearResource';
  static const String apiTradeSearchResource = 'api.trade.searchResource';
  static const String apiTradeConnectTimeout = 'api.trade.connectTimeout';
  static const String apiTradeReceiveTimeout = 'api.trade.receiveTimeout';
  static const String apiTradeSendTimeout = 'api.trade.sendTimeout';
  static const String apiTradeEnabled = 'api.trade.enabled';

  // Document API properties
  static const String apiDocumentBaseUrl = 'api.document.baseUrl';
  static const String apiDocumentConnectTimeout = 'api.document.connectTimeout';
  static const String apiDocumentReceiveTimeout = 'api.document.receiveTimeout';
  static const String apiDocumentSendTimeout = 'api.document.sendTimeout';
  static const String apiDocumentEnabled = 'api.document.enabled';

  // Auth API properties
  static const String apiAuthBaseUrl = 'api.auth.baseUrl';
  static const String apiAuthLoginEndpoint = 'api.auth.loginEndpoint';
  static const String apiAuthRefreshTokenEndpoint =
      'api.auth.refreshTokenEndpoint';
  static const String apiAuthLogoutEndpoint = 'api.auth.logoutEndpoint';
  static const String apiAuthGoogleLoginEndpoint =
      'api.auth.googleLoginEndpoint';
  static const String apiAuthConnectTimeout = 'api.auth.connectTimeout';
  static const String apiAuthReceiveTimeout = 'api.auth.receiveTimeout';
  static const String apiAuthSendTimeout = 'api.auth.sendTimeout';
  static const String apiAuthEnabled = 'api.auth.enabled';

  // User Management API properties
  static const String apiUserBaseUrl = 'api.user.baseUrl';
  static const String apiUserRegisterEndpoint = 'api.user.registerEndpoint';
  static const String apiUserForgotPasswordEndpoint =
      'api.user.forgotPasswordEndpoint';
  static const String apiUserResetPasswordEndpoint =
      'api.user.resetPasswordEndpoint';
  static const String apiUserConnectTimeout = 'api.user.connectTimeout';
  static const String apiUserReceiveTimeout = 'api.user.receiveTimeout';
  static const String apiUserSendTimeout = 'api.user.sendTimeout';
  static const String apiUserEnabled = 'api.user.enabled';

  // Environment properties
  static const String environmentName = 'environment.name';
  static const String environmentDebugMode = 'environment.debugMode';
  static const String environmentLogLevel = 'environment.logLevel';

  // Google Sign-In properties
  static const String googleWebClientId = 'google.web.clientId';
}

/// Environment variables keys
class EnvironmentKeys {
  static const String env = 'ENV';
  static const String flutterEnv = 'FLUTTER_ENV';
  static const String defaultEnvVar = 'DEFAULT_ENV_VAR';
}
