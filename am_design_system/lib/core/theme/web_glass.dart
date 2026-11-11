import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Solid surface on web. [BackdropFilter] copies the pixels behind it on every
/// repaint, and a blur that stays mounted locks the browser tab.
Widget webGlass({
  required Widget child,
  double sigma = 16,
  BorderRadius? clip,
}) {
  if (kIsWeb || sigma <= 0) {
    if (clip == null) return child;
    return ClipRRect(borderRadius: clip, child: child);
  }
  final blurred = BackdropFilter(
    filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
    child: child,
  );
  if (clip == null) return ClipRect(child: blurred);
  return ClipRRect(borderRadius: clip, child: blurred);
}
