import 'package:flutter/foundation.dart';

/// Shared visibility factor for the floating global bottom nav (0 = hidden, 1 = shown).
///
/// [AppShell] drives this from its bottom-nav [AnimationController] so overlays
/// like basket sticky action bars can slide with the company nav.
abstract final class GlobalBottomNavVisibility {
  GlobalBottomNavVisibility._();

  /// Curved visibility factor matching the shell slide/fade animation.
  static final ValueNotifier<double> factor = ValueNotifier<double>(1.0);

  static void setFactor(double value) {
    final next = value.clamp(0.0, 1.0);
    if (factor.value == next) return;
    factor.value = next;
  }
}
