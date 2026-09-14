import 'package:flutter/material.dart';

import '../../../core/theme/color_extensions.dart';

/// Resolves theme-aware shimmer / skeleton fill colors.
({Color base, Color highlight}) skeletonShimmerColors(
  BuildContext context, {
  Color? accentColor,
}) {
  final colors = context.colors;
  final isDark = context.isDark;
  final accent = accentColor ?? colors.actionPrimaryBg;

  final base = Color.lerp(
        colors.scaffoldBackground,
        colors.surface,
        isDark ? 0.35 : 0.55,
      ) ??
      colors.surface;

  final highlight = Color.lerp(
        base,
        accent,
        isDark ? 0.28 : 0.18,
      ) ??
      accent.withValues(alpha: 0.35);

  return (base: base, highlight: highlight);
}

/// A shimmer loading effect widget that can be used as a skeleton loader
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  /// Optional module/brand accent used when [highlightColor] is null.
  final Color? accentColor;

  const ShimmerLoading({
    Key? key,
    required this.child,
    this.isLoading = true,
    this.baseColor,
    this.highlightColor,
    this.accentColor,
  }) : super(key: key);

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    final resolved = skeletonShimmerColors(
      context,
      accentColor: widget.accentColor,
    );
    final baseColor = widget.baseColor ?? resolved.base;
    final highlightColor = widget.highlightColor ?? resolved.highlight;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Pre-built skeleton widgets for common use cases
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? accentColor;

  const SkeletonBox({
    Key? key,
    this.width,
    this.height = 16,
    this.borderRadius,
    this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final resolved = skeletonShimmerColors(
      context,
      accentColor: accentColor,
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: resolved.base,
        borderRadius: borderRadius ?? BorderRadius.circular(4),
        border: Border.all(
          color: (accentColor ?? context.colors.actionPrimaryBg)
              .withValues(alpha: 0.12),
        ),
      ),
    );
  }
}

class SkeletonLine extends StatelessWidget {
  final double? width;
  final double height;
  final Color? accentColor;

  const SkeletonLine({
    Key? key,
    this.width,
    this.height = 16,
    this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(8),
      accentColor: accentColor,
    );
  }
}

class SkeletonAvatar extends StatelessWidget {
  final double size;
  final Color? accentColor;

  const SkeletonAvatar({
    Key? key,
    this.size = 48,
    this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
      accentColor: accentColor,
    );
  }
}
