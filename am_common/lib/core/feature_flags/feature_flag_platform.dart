import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

String featureFlagPlatform() {
  if (kIsWeb) return 'web';
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'android';
    case TargetPlatform.iOS:
      return 'ios';
    default:
      return 'other';
  }
}
