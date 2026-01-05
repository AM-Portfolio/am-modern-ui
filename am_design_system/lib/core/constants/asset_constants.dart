/// Asset path constants
/// Note: These paths are for use with rootBundle.loadString() and should match pubspec.yaml assets
class AssetPaths {
  /// Root asset directory (as defined in pubspec.yaml)
  static const String assetsRoot = 'assets';
  
  /// Images directory
  static const String images = '$assetsRoot/images';
  
  /// Mock data directory (compatible with rootBundle.loadString)
  static const String mockData = '$assetsRoot/mock_data';
  
  /// Configuration files (compatible with rootBundle.loadString)
  static const String applicationProperties = '$assetsRoot/application.properties';
  static const String applicationDevProperties = '$assetsRoot/application-dev.properties';
  static const String applicationProdProperties = '$assetsRoot/application-prod.properties';
  static const String applicationTestProperties = '$assetsRoot/application-test.properties';
  static const String applicationStagingProperties = '$assetsRoot/application-staging.properties';
  
  /// Test data (compatible with rootBundle.loadString)
  /// Test data (compatible with rootBundle.loadString)
  static const String testUsers = '$assetsRoot/test_users.json';
  
  /// Image assets
  static const String appLogo = '$images/app_logo.png';
  static const String defaultBrokerLogo = '$images/default_broker_logo.png';
  static const String placeholderImage = '$images/placeholder.png';
  
  /// Mock data files (compatible with rootBundle.loadString)
  static const String mockPortfolioSummary = '$assetsRoot/mock_data/portfolio_summary.json';
  static const String mockPortfolioHoldings = '$assetsRoot/mock_data/portfolio_holdings.json';
  static const String mockPortfolioData = '$mockData/portfolio_data.json';
  static const String mockHoldingsData = '$mockData/holdings_data.json';
  static const String mockTransactionsData = '$mockData/transactions_data.json';
  static const String mockUserData = '$mockData/user_data.json';
  
  /// Get environment-specific properties file path
  static String getEnvironmentPropertiesPath(String environment) {
    switch (environment.toLowerCase()) {
      case 'dev':
      case 'development':
        return applicationDevProperties;
      case 'prod':
      case 'production':
        return applicationProdProperties;
      case 'test':
      case 'testing':
        return applicationTestProperties;
      case 'staging':
        return applicationStagingProperties;
      default:
        return applicationDevProperties;
    }
  }
}

/// Network and API constants
class NetworkConstants {
  /// HTTP Status Codes
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusAccepted = 202;
  static const int statusNoContent = 204;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusMethodNotAllowed = 405;
  static const int statusConflict = 409;
  static const int statusInternalServerError = 500;
  static const int statusServiceUnavailable = 503;
  
  /// Timeout values (in seconds)
  static const int connectTimeout = 30;
  static const int receiveTimeout = 60;
  static const int sendTimeout = 60;
  
  /// Retry configuration
  static const int maxRetries = 3;
  static const int retryDelay = 1000; // milliseconds
  
  /// Content Types
  static const String contentTypeJson = 'application/json';
  static const String contentTypeFormData = 'multipart/form-data';
  static const String contentTypeUrlEncoded = 'application/x-www-form-urlencoded';
  
  /// Headers
  static const String headerAuthorization = 'Authorization';
  static const String headerContentType = 'Content-Type';
  static const String headerAccept = 'Accept';
  static const String headerUserAgent = 'User-Agent';
}

/// Storage keys for local/session storage
class StorageKeys {
  /// Authentication
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String isLoggedIn = 'is_logged_in';
  
  /// User preferences
  static const String theme = 'theme';
  static const String language = 'language';
  static const String currency = 'currency';
  static const String timezone = 'timezone';
  
  /// Application state
  static const String lastSelectedPortfolio = 'last_selected_portfolio';
  static const String dashboardLayout = 'dashboard_layout';
  static const String notificationsEnabled = 'notifications_enabled';
  
  /// Cache keys
  static const String portfolioCache = 'portfolio_cache';
  static const String holdingsCache = 'holdings_cache';
  static const String transactionsCache = 'transactions_cache';
  static const String userProfileCache = 'user_profile_cache';
}