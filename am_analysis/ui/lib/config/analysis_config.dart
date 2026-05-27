import 'package:am_common/am_common.dart';

/// Configuration for Analysis API client
class AnalysisConfig {
  static final AnalysisConfig _instance = AnalysisConfig._internal();
  
  factory AnalysisConfig() => _instance;
  
  AnalysisConfig._internal();
  
  /// Get the singleton instance
  static AnalysisConfig get instance => _instance;
  
  String? _baseUrl;
  
  String get baseUrl => _baseUrl ?? EnvDomains.analysis;
  
  void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}
