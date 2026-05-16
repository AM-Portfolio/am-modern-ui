/// Configuration for Analysis API client
class AnalysisConfig {
  static final AnalysisConfig _instance = AnalysisConfig._internal();
  
  factory AnalysisConfig() => _instance;
  
  AnalysisConfig._internal();
  
  /// Get the singleton instance
  static AnalysisConfig get instance => _instance;
  
  /// Base URL for the Analysis API
  String _baseUrl = 'https://am.asrax.in/analysis';
  
  /// Get the current base URL
  String get baseUrl => _baseUrl;
  
  /// Set the base URL for the API
  void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
  
  factory AnalysisConfig.development() {
    final config = AnalysisConfig._instance;
    config.setBaseUrl('https://am.asrax.in/analysis');
    return config;
  }
  
  factory AnalysisConfig.staging() {
    final config = AnalysisConfig._instance;
    config.setBaseUrl('https://am-staging.munish.org');
    return config;
  }
  
  factory AnalysisConfig.production() {
    final config = AnalysisConfig._instance;
    config.setBaseUrl('https://am.asrax.in/analysis');
    return config;
  }
}
