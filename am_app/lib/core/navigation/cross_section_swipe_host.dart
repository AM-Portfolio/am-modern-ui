import 'package:am_common/am_common.dart';
import 'package:flutter/material.dart';

/// Shell-level horizontal swipe host. Wire once in [AppShell]; all routes inherit it.
///
/// Thresholds are intentionally high so a light left/right jiggle does not
/// change bottom-nav modules / routes.
class CrossSectionSwipeHost extends StatelessWidget {
  const CrossSectionSwipeHost({
    required this.child,
    this.onNext,
    this.onPrevious,
    super.key,
  });

  final Widget child;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  @override
  Widget build(BuildContext context) {
    final scope = CrossSectionNavScope.maybeOf(context);
    return HorizontalSectionNavigator(
      // Explicit shell bar: deliberate swipe before goNext/PreviousModule.
      flingVelocity: 900,
      dragDistance: 140,
      minDragForAnyNav: 48,
      onNextPage: onNext ?? scope?.goNextModule,
      onPreviousPage: onPrevious ?? scope?.goPreviousModule,
      child: child,
    );
  }
}
