import 'package:flutter/material.dart';

/// Callbacks for moving to the adjacent bottom-nav module.
///
/// Modules keep their own sub-page swipe; at the first/last sub-page they call
/// [goNextModule] / [goPreviousModule] so navigation stays continuous.
class CrossSectionNavController {
  CrossSectionNavController({
    required this.goNextModule,
    required this.goPreviousModule,
  });

  /// Advance to the next primary module (e.g. Dashboard → Portfolio).
  final VoidCallback goNextModule;

  /// Go back to the previous primary module (e.g. Portfolio → Dashboard).
  final VoidCallback goPreviousModule;
}

/// Provides [CrossSectionNavController] down the tree from [AppShell].
class CrossSectionNavScope extends InheritedWidget {
  const CrossSectionNavScope({
    required this.controller,
    required super.child,
    super.key,
  });

  final CrossSectionNavController controller;

  static CrossSectionNavController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CrossSectionNavScope>()
        ?.controller;
  }

  static CrossSectionNavController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'CrossSectionNavScope not found in context');
    return controller!;
  }

  @override
  bool updateShouldNotify(CrossSectionNavScope oldWidget) =>
      controller != oldWidget.controller;
}
