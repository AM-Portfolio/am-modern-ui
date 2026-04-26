import 'package:flutter/foundation.dart';

enum Environment { development, preprod, production }

class EnvironmentConfig {
  // Default to production initially, can be changed at runtime
  static Environment _environment = Environment.production;

  // Listeners for environment changes
  static final List<Function(Environment)> _listeners = [];

  // Get current environment
  static Environment get environment => _environment;

  // Set environment with notification to listeners
  static set environment(Environment env) {
    if (_environment != env) {
      _environment = env;
      debugPrint('Environment changed to: ${env.toString().split('.').last}');
      debugPrint('API URL: $apiBaseUrl');
      _notifyListeners();
    }
  }

  // Add listener for environment changes
  static void addListener(Function(Environment) listener) {
    _listeners.add(listener);
  }

  // Remove listener
  static void removeListener(Function(Environment) listener) {
    _listeners.remove(listener);
  }

  // Notify all listeners of environment change
  static void _notifyListeners() {
    for (final listener in _listeners) {
      listener(_environment);
    }
  }

  // API URLs
  static String get apiBaseUrl {
    switch (environment) {
      case Environment.development:
        return 'https://am.asrax.in'; // Production API
      case Environment.preprod:
        return 'https://am.asrax.in'; // Production API
      case Environment.production:
        return 'https://am.asrax.in'; // Production API
    }
  }

  // Feature flags
  static bool get enableDebugFeatures {
    switch (environment) {
      case Environment.development:
        return true;
      case Environment.preprod:
        return true;
      case Environment.production:
        return false;
    }
  }

  // Environment-specific settings
  static Map<String, dynamic> get settings {
    switch (environment) {
      case Environment.development:
        return {
          'appTitle': '[DEV] AM Investment',
          'analyticsEnabled': false,
          'refreshInterval': 30, // seconds
          'useMockData': false,
        };
      case Environment.preprod:
        return {
          'appTitle': '[PREPROD] AM Investment',
          'analyticsEnabled': false,
          'refreshInterval': 60, // seconds
          'useMockData': false,
        };
      case Environment.production:
        return {
          'appTitle': 'AM Investment',
          'analyticsEnabled': true,
          'refreshInterval': 300, // seconds
          'useMockData': false,
        };
    }
  }

  // Initialize environment based on build arguments
  static void setEnvironment(String env) {
    switch (env.toLowerCase()) {
      case 'development':
        environment = Environment.development;
        break;
      case 'preprod':
        environment = Environment.preprod;
        break;
      case 'production':
      default:
        environment = Environment.production;
        break;
    }

    debugPrint('Environment set to: ${environment.toString().split('.').last}');
    debugPrint('API URL: $apiBaseUrl');
  }
}
