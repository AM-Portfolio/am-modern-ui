import 'package:flutter/material.dart';

/// A collection of animated widgets for the login screen
class AnimatedLoginElements {
  /// Creates a fade-in animation for a widget
  static Widget fadeInAnimation({
    required Widget child,
    required int delay,
    Duration duration = const Duration(milliseconds: 500),
  }) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: duration,
    curve: Curves.easeOut,
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: child,
      ),
    ),
    child: child,
  );

  /// Creates a scale animation for a widget
  static Widget scaleAnimation({
    required Widget child,
    required int delay,
    Duration duration = const Duration(milliseconds: 400),
  }) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.8, end: 1.0),
    duration: duration,
    curve: Curves.easeOut,
    builder: (context, value, child) =>
        Transform.scale(scale: value, child: child),
    child: child,
  );

  /// Creates a slide-in animation for a widget
  static Widget slideInAnimation({
    required Widget child,
    required int delay,
    Duration duration = const Duration(milliseconds: 600),
    Offset beginOffset = const Offset(0.0, 30.0),
  }) => TweenAnimationBuilder<Offset>(
    tween: Tween(begin: beginOffset, end: Offset.zero),
    duration: duration,
    curve: Curves.easeOutCubic,
    builder: (context, value, child) =>
        Transform.translate(offset: value, child: child),
    child: child,
  );

  /// Creates a staggered animation container for multiple children
  static Widget staggeredAnimations({
    required List<Widget> children,
    required int baseDelay,
    required int staggerDelay,
    required AnimationType type,
  }) {
    final animatedChildren = <Widget>[];

    for (var i = 0; i < children.length; i++) {
      final delay = baseDelay + (i * staggerDelay);

      switch (type) {
        case AnimationType.fadeIn:
          animatedChildren.add(
            fadeInAnimation(child: children[i], delay: delay),
          );
          break;
        case AnimationType.scale:
          animatedChildren.add(
            scaleAnimation(child: children[i], delay: delay),
          );
          break;
        case AnimationType.slideIn:
          animatedChildren.add(
            slideInAnimation(child: children[i], delay: delay),
          );
          break;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: animatedChildren,
    );
  }

  /// Creates a pulse animation for a widget (useful for buttons or attention-grabbing elements)
  static Widget pulseAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
  }) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 1.0, end: 1.05),
    duration: duration,
    curve: Curves.easeInOut,
    builder: (context, value, child) =>
        Transform.scale(scale: value, child: child),
    onEnd: () {},
    child: child,
  );

  /// Creates a shimmer loading effect
  static Widget shimmerEffect({
    required Widget child,
    required Color baseColor,
    required Color highlightColor,
    Duration duration = const Duration(milliseconds: 1500),
  }) => TweenAnimationBuilder<double>(
    tween: Tween(begin: -1.0, end: 2.0),
    duration: duration,
    curve: Curves.easeInOut,
    builder: (context, value, child) => ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: [baseColor, highlightColor, baseColor],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment(-1.0 + value, -1.0),
        end: Alignment(1.0 + value, 1.0),
      ).createShader(bounds),
      child: child,
    ),
    onEnd: () {},
    child: child,
  );
}

/// Animation types for staggered animations
enum AnimationType { fadeIn, scale, slideIn }
