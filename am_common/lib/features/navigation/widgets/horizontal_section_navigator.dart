import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:am_design_system/am_design_system.dart';

/// Horizontal edge / fling navigator used for cross-section mobile swipe.
///
/// Automatically disabled on tablet and desktop screens to prevent gesture conflicts
/// with multi-column layouts and interactive charts.
///
/// **Direction:** finger swipe **left** → [onNextPage],
/// finger swipe **right** → [onPreviousPage] (standard PageView semantics).
class HorizontalSectionNavigator extends StatefulWidget {
  const HorizontalSectionNavigator({
    required this.child,
    this.onNextPage,
    this.onPreviousPage,
    this.enabled = true,
    this.flingVelocity = 400,
    this.dragDistance = 72,
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

  @override
  State<HorizontalSectionNavigator> createState() =>
      _HorizontalSectionNavigatorState();
}

class _HorizontalSectionNavigatorState
    extends State<HorizontalSectionNavigator> {
  bool _isNavigating = false;
  double _dragDx = 0;
  double _dragDy = 0;

  bool _isSwipeAllowed(BuildContext context) {
    if (!widget.enabled) return false;
    // Disable horizontal tab swiping on tablet and desktop (width >= 600px)
    final isTabletOrDesktop = AmBreakpoints.isTabletContext(context) ||
        AmBreakpoints.isDesktopContext(context);
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
    _dragDy = 0;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragDx += details.delta.dx;
    _dragDy += details.delta.dy;
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_isSwipeAllowed(context)) return;

    final vx = details.velocity.pixelsPerSecond.dx;
    final vy = details.velocity.pixelsPerSecond.dy;

    // Must be predominantly horizontal
    if (vx.abs() < vy.abs()) return;

    if (vx.abs() >= widget.flingVelocity ||
        _dragDx.abs() >= widget.dragDistance) {
      if (vx < 0 || _dragDx < 0) {
        _handleNavigation(isNext: true);
      } else if (vx > 0 || _dragDx > 0) {
        _handleNavigation(isNext: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSwipeAllowed(context)) {
      return widget.child;
    }

    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        PanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
          () => PanGestureRecognizer(),
          (PanGestureRecognizer instance) {
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
