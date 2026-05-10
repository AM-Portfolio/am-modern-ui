/// Feature flags for controlling app behavior and development features
class FeatureFlags {
  factory FeatureFlags() => _instance;
  FeatureFlags._internal();
  // API Configuration
  bool useRealGoogleAuth = false;
  bool useRealBackendAPI = false;
  bool useRealEmailService = false;

  // Development Features
  bool enableMockDelays = true;
  bool enableErrorSimulation = false;
  bool enableDebugLogging = true;
  bool showDeveloperPanel = true;

  // Performance Settings
  int mockApiDelayMs = 1500;
  int tokenRefreshIntervalMin = 5;
  int sessionTimeoutMin = 30;

  // Error Simulation
  double networkErrorRate = 0.0; // 0.0 to 1.0 (0% to 100%)
  double serverErrorRate = 0.0;
  double authErrorRate = 0.0;

  // Singleton pattern
  static final FeatureFlags _instance = FeatureFlags._internal();

  /// Reset all flags to default values
  void resetToDefaults() {
    useRealGoogleAuth = false;
    useRealBackendAPI = false;
    useRealEmailService = false;
    enableMockDelays = true;
    enableErrorSimulation = false;
    enableDebugLogging = true;
    showDeveloperPanel = true;
    mockApiDelayMs = 1500;
    tokenRefreshIntervalMin = 5;
    sessionTimeoutMin = 30;
    networkErrorRate = 0.0;
    serverErrorRate = 0.0;
    authErrorRate = 0.0;
  }

  /// Export current configuration as a map
  Map<String, dynamic> toJson() => {
    'useRealGoogleAuth': useRealGoogleAuth,
    'useRealBackendAPI': useRealBackendAPI,
    'useRealEmailService': useRealEmailService,
    'enableMockDelays': enableMockDelays,
    'enableErrorSimulation': enableErrorSimulation,
    'enableDebugLogging': enableDebugLogging,
    'showDeveloperPanel': showDeveloperPanel,
    'mockApiDelayMs': mockApiDelayMs,
    'tokenRefreshIntervalMin': tokenRefreshIntervalMin,
    'sessionTimeoutMin': sessionTimeoutMin,
    'networkErrorRate': networkErrorRate,
    'serverErrorRate': serverErrorRate,
    'authErrorRate': authErrorRate,
  };

  /// Import configuration from a map
  void fromJson(Map<String, dynamic> json) {
    useRealGoogleAuth = json['useRealGoogleAuth'] ?? false;
    useRealBackendAPI = json['useRealBackendAPI'] ?? false;
    useRealEmailService = json['useRealEmailService'] ?? false;
    enableMockDelays = json['enableMockDelays'] ?? true;
    enableErrorSimulation = json['enableErrorSimulation'] ?? false;
    enableDebugLogging = json['enableDebugLogging'] ?? true;
    showDeveloperPanel = json['showDeveloperPanel'] ?? true;
    mockApiDelayMs = json['mockApiDelayMs'] ?? 1500;
    tokenRefreshIntervalMin = json['tokenRefreshIntervalMin'] ?? 5;
    sessionTimeoutMin = json['sessionTimeoutMin'] ?? 30;
    networkErrorRate = json['networkErrorRate'] ?? 0.0;
    serverErrorRate = json['serverErrorRate'] ?? 0.0;
    authErrorRate = json['authErrorRate'] ?? 0.0;
  }
}
