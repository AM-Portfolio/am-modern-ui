import 'package:flutter/material.dart';

/// Centralized animation constants for consistent motion design
class AppAnimations {
  // Durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 400);

  // Curves
  static const Curve defaultCurve = Curves.easeOut;
  static const Curve bounce = Curves.elasticOut;
  static const Curve emphasize = Curves.easeInOutCubic;
  static const Curve decelerate = Curves.decelerate;
  
  // Transitions
  static Widget fadeTransition(Widget child, Animation<double> animation) {
    return FadeTransition(opacity: animation, child: child);
  }
  
  static Widget scaleTransition(Widget child, Animation<double> animation) {
    return ScaleTransition(scale: animation, child: child);
  }
  
  static Widget slideUpTransition(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}
