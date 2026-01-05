import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A conditional MouseRegion that only works on non-web platforms
/// This fixes Flutter Web MouseRegion assertions while preserving hover functionality on desktop
class ConditionalMouseRegion extends StatelessWidget {
  const ConditionalMouseRegion({
    super.key,
    required this.child,
    this.onEnter,
    this.onExit,
    this.onHover,
    this.cursor = MouseCursor.defer,
    this.opaque = true,
    this.hitTestBehavior,
  });

  final Widget child;
  final void Function(PointerEnterEvent)? onEnter;
  final void Function(PointerExitEvent)? onExit;
  final void Function(PointerHoverEvent)? onHover;
  final MouseCursor cursor;
  final bool opaque;
  final HitTestBehavior? hitTestBehavior;

  @override
  Widget build(BuildContext context) {
    // On web, MouseRegion works fine in modern Flutter versions.
    // Proceed to use MouseRegion.
    
    return MouseRegion(
      onEnter: onEnter,
      onExit: onExit,
      onHover: onHover,
      cursor: cursor,
      opaque: opaque,
      hitTestBehavior: hitTestBehavior,
      child: child,
    );
  }
}
