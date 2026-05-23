import 'package:am_common/am_common.dart';

/// Configuration for Analysis API client
class AnalysisConfig {
  static final AnalysisConfig _instance = AnalysisConfig._internal();
  
  factory AnalysisConfig() => _instance;
  
  AnalysisConfig._internal();
  
  /// Get the singleton instance
  static AnalysisConfig get instance => _instance;
  
  /// Base URL for the Analysis API
  String get baseUrl => EnvDomains.analysis;
}
