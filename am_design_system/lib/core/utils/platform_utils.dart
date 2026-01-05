import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Helper class for platform detection and platform-specific behavior
class PlatformUtils {
  /// Check if the app is running on web
  static bool get isWeb => kIsWeb;
  
  /// Check if the app is running on iOS
  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  
  /// Check if the app is running on Android
  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  
  /// Check if the app is running on mobile (iOS or Android)
  static bool get isMobile => isIOS || isAndroid;
  
  /// Get the current platform as a string
  static String get platformName {
    if (isWeb) return 'web';
    if (isIOS) return 'ios';
    if (isAndroid) return 'android';
    return 'other';
  }
}
