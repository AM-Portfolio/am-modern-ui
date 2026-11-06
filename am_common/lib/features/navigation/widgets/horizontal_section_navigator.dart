import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:am_design_system/am_design_system.dart';

/// Pure gate for whether a horizontal drag should change section/module.
///
/// Exposed for unit tests. Returns `true` for next, `false` for previous,
/// or `null` when the gesture is too small / ambiguous.
bool? horizontalSectionNavDecision({
  required double dragDx,
  required double velocityDx,
  required double flingVelocity,
  required double dragDistance,
  required double minDragForAnyNav,
}) {
  if (dragDx.abs() < minDragForAnyNav) return null;

  final isFling = velocityDx.abs() >= flingVelocity;
  final isLongDrag = dragDx.abs() >= dragDistance;
  if (!isFling && !isLongDrag) return null;

  // Prefer fling direction when strong enough; otherwise use drag direction.
  if (isFling) {
    if (velocityDx < 0) return true; // left → next
    if (velocityDx > 0) return false; // right → previous
  }
  if (dragDx < 0) return true;
  if (dragDx > 0) return false;
  return null;
}

/// Horizontal edge / fling navigator used for cross-section mobile swipe.
///
/// Automatically disabled on tablet and desktop screens to prevent gesture conflicts
/// with multi-column layouts and interactive charts.
///
/// **Direction:** finger swipe **left** → [onNextPage],
/// finger swipe **right** → [onPreviousPage] (standard PageView semantics).
///
/// Uses [HorizontalDragGestureRecognizer] so vertical scroll / pull-to-refresh
/// on child pages is never treated as section navigation.
class HorizontalSectionNavigator extends StatefulWidget {
  const HorizontalSectionNavigator({
    required this.child,
    this.onNextPage,
    this.onPreviousPage,
    this.enabled = true,
    this.flingVelocity = 900,
    this.dragDistance = 140,
    this.minDragForAnyNav = 48,
    super.key,
  });

  final Widget child;
  final VoidCallback? onNextPage;
  final VoidCallback? onPreviousPage;
  final bool enabled;

  /// Min |velocity.dx| to treat as a fling (logical px/s).
  final double flingVelocity;

  /// Min horizontal drag distance when velocity is low.
  final double dragDistance;

  /// Absolute minimum drag before any navigation (blocks micro-jitter flings).
  final double minDragForAnyNav;

  @override
  State<HorizontalSectionNavigator> createState() =>
      _HorizontalSectionNavigatorState();
}

class _HorizontalSectionNavigatorState extends State<HorizontalSectionNavigator> {
  bool _isNavigating = false;
  double _dragDx = 0;

  bool _isSwipeAllowed(BuildContext context) {
    if (!widget.enabled) return false;
    // Disable horizontal tab swiping on tablet and desktop (width >= 600px)
    final isTabletOrDesktop =
        AmBreakpoints.isTabletContext(context) || AmBreakpoints.isDesktopContext(context);
    return !isTabletOrDesktop;
  }

  Future<void> _handleNavigation({required bool isNext}) async {
    if (_isNavigating || !_isSwipeAllowed(context)) return;
    if (isNext && widget.onNextPage == null) return;
    if (!isNext && widget.onPreviousPage == null) return;

    _isNavigating = true;
    HapticFeedback.selectionClick();
    if (isNext) {
      widget.onNextPage?.call();
    } else {
      widget.onPreviousPage?.call();
    }
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (mounted) _isNavigating = false;
  }

  void _onDragStart(DragStartDetails details) {
    _dragDx = 0;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragDx += details.delta.dx;
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_isSwipeAllowed(context)) return;

    final decision = horizontalSectionNavDecision(
      dragDx: _dragDx,
      velocityDx: details.velocity.pixelsPerSecond.dx,
      flingVelocity: widget.flingVelocity,
      dragDistance: widget.dragDistance,
      minDragForAnyNav: widget.minDragForAnyNav,
    );
    if (decision == null) return;
    _handleNavigation(isNext: decision);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSwipeAllowed(context)) {
      return widget.child;
    }

    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        HorizontalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
          () => HorizontalDragGestureRecognizer(),
          (HorizontalDragGestureRecognizer instance) {
            instance
              ..onStart = _onDragStart
              ..onUpdate = _onDragUpdate
              ..onEnd = _onDragEnd;
          },
        ),
      },
      child: widget.child,
    );
  }
}
