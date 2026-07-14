import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Horizontal edge / fling navigator used for cross-section mobile swipe.
///
/// **Direction:** finger swipe **left** → [onNextPage],
/// finger swipe **right** → [onPreviousPage] (standard PageView semantics).
///
/// Prefers not to fight vertical scrolling: a gesture only counts when
/// horizontal movement dominates.
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

class _HorizontalSectionNavigatorState extends State<HorizontalSectionNavigator> {
  bool _isNavigating = false;
  double _dragDx = 0;
  double _dragDy = 0;

  Future<void> _handleNavigation({required bool isNext}) async {
    if (_isNavigating || !widget.enabled) return;
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
    if (!widget.enabled || _isNavigating) return;

    final vx = details.velocity.pixelsPerSecond.dx;
    final horizontalDominant = _dragDx.abs() >= _dragDy.abs();
    if (!horizontalDominant && vx.abs() < widget.flingVelocity) return;

    // Finger left → next, finger right → previous (standard PageView).
    final wentRight =
        vx > widget.flingVelocity || _dragDx > widget.dragDistance;
    final wentLeft =
        vx < -widget.flingVelocity || _dragDx < -widget.dragDistance;

    if (wentLeft) {
      _handleNavigation(isNext: true);
    } else if (wentRight) {
      _handleNavigation(isNext: false);
    }

    _dragDx = 0;
    _dragDy = 0;
  }

  /// Overscroll handoff when a child [PageView]/[TabBarView] is at an edge.
  bool _onScrollNotification(ScrollNotification notification) {
    if (!widget.enabled || _isNavigating) return false;
    if (notification.metrics.axis != Axis.horizontal) return false;
    if (notification is! OverscrollNotification) return false;

    // Standard PageView: past last page → next; past first → previous.
    if (notification.overscroll > 8) {
      _handleNavigation(isNext: true);
    } else if (notification.overscroll < -8) {
      _handleNavigation(isNext: false);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent &&
            event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()) {
          if (event.scrollDelta.dx > 0) {
            _handleNavigation(isNext: true);
          } else if (event.scrollDelta.dx < 0) {
            _handleNavigation(isNext: false);
          }
        }
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: widget.child,
        ),
      ),
    );
  }
}
