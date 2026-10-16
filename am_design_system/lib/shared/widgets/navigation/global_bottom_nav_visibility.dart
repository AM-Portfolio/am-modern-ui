import 'package:flutter/foundation.dart';

/// Shared visibility factor for the floating global bottom nav (0 = hidden, 1 = shown).
///
/// [AppShell] drives this from its bottom-nav [AnimationController] so overlays
/// like basket sticky action bars can slide with the company nav.
abstract final class GlobalBottomNavVisibility {
  GlobalBottomNavVisibility._();

  /// Curved visibility factor matching the shell slide/fade animation.
  static final ValueNotifier<double> factor = ValueNotifier<double>(1.0);

  /// When true, AppShell skips tap-to-reveal on the next chrome pointer up/cancel.
  /// Set by AI chat composer so focus/send do not flash the bottom nav.
  static bool suppressChromeTapReveal = false;

  /// Bumped to request an immediate bottom-nav hide (AppShell listens).
  static final ValueNotifier<int> hideRequests = ValueNotifier<int>(0);

  /// Nested count of full-screen overlays (bottom sheets / dialogs) that must
  /// keep the floating company nav hidden until dismissed.
  static int _modalLocks = 0;

  /// True while any [pushModalLock] has not yet been matched by [popModalLock].
  static bool get isModalLocked => _modalLocks > 0;

  static void requestHide() => hideRequests.value++;

  /// Hide the nav and block tap/scroll reveal until [popModalLock].
  static void pushModalLock() {
    _modalLocks++;
    suppressChromeTapReveal = true;
    requestHide();
  }

  /// Release one [pushModalLock]. Safe to call from `finally`.
  static void popModalLock() {
    if (_modalLocks > 0) _modalLocks--;
    if (_modalLocks == 0) {
      suppressChromeTapReveal = false;
    }
  }

  static void setFactor(double value) {
    final next = value.clamp(0.0, 1.0);
    if (factor.value == next) return;
    factor.value = next;
  }
}
