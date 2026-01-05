
import 'package:flutter/material.dart';

import 'package:am_design_system/core/config/design_system_provider.dart';
import 'package:am_design_system/core/theme/app_glassmorphism.dart';
import 'package:am_design_system/core/theme/app_glassmorphism_v2.dart';
import 'package:am_design_system/core/utils/conditional_mouse_region.dart';






/// Glassmorphic card component with shadow and border
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final double borderWidth;
  final double blur;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;
  final double? borderRadius; // Nullable to allow config default
  // V2 Props
  final String? colorScheme; // 'primary', 'accent', 'success', etc.
  final bool isGlowing;

  const GlassCard({
    Key? key,
    required this.child,
    this.padding,
    this.borderColor,
    this.borderWidth = 1.0,
    this.blur = 10.0,
    this.gradientColors,
    this.onTap,
    this.borderRadius,
    this.colorScheme,
    this.isGlowing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get Design Config
    final config = DesignSystemProvider.of(context);
    final effectiveRadius = borderRadius ?? config.defaultRadius;

    // Determine decoration based on props
    BoxDecoration decoration;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (colorScheme != null) {
      // Use V2 Style
      decoration = AppGlassmorphismV2.colorCodedGlassCard(
        colorScheme: colorScheme!,
        borderWidth: borderWidth,
        borderRadius: effectiveRadius,
        isGlowing: isGlowing,
        isDark: isDark,
      );
    } else if (gradientColors != null) {
      // Use Gradient Style
      decoration = AppGlassmorphism.glassCard(
        gradientColors: gradientColors,
        borderColor: borderColor,
        borderWidth: borderWidth,
        blur: blur,
        borderRadius: effectiveRadius,
      );
    } else {
      // Default Glass Style
      decoration = AppGlassmorphism.glassCard(
        borderColor: borderColor,
        borderWidth: borderWidth,
        blur: blur,
        borderRadius: effectiveRadius,
      );
    }

    // Wrap with gradient painter if colorScheme is present for that nice border effect
    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: decoration,
      child: child,
    );

    if (colorScheme != null) {
      content = CustomPaint(
        painter: GradientBorderPainter(
          colors: AppGlassmorphismV2.colorSchemes[colorScheme!]!,
          borderWidth: borderWidth,
          borderRadius: effectiveRadius,
        ),
        child: content,
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: content,
      );
    }

    return content;
  }
}

/// Metric card (V2 enhanced)
class MetricCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? accentColor; // Maintain backward compat
  final String? colorScheme; // V2 Prop
  final VoidCallback? onTap;
  final double elevation;
  final Widget? trailing;

  const MetricCard({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor,
    this.colorScheme,
    this.onTap,
    this.elevation = 8.0,
    this.trailing,
  }) : super(key: key);

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine effective color scheme
    Color effectiveColor;
    List<Color> borderColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (widget.colorScheme != null) {
      borderColors = AppGlassmorphismV2.colorSchemes[widget.colorScheme!]!;
      effectiveColor = borderColors.first;
    } else if (widget.accentColor != null) {
      effectiveColor = widget.accentColor!;
      borderColors = [effectiveColor, effectiveColor.withOpacity(0.6)];
    } else {
      effectiveColor = AppGlassmorphismV2.colorSchemes['primary']![0];
      borderColors = AppGlassmorphismV2.colorSchemes['primary']!;
    }

    return ConditionalMouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: GestureDetector(
          onTap: widget.onTap,
          child: CustomPaint(
            painter: GradientBorderPainter(
              colors: borderColors,
              borderWidth: 1.5,
              borderRadius: 20,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: AppGlassmorphismV2.gradientBorderCard(
                borderColors: borderColors,
                borderRadius: 20,
                isGlowing: _isHovered, // Glow on hover
                isDark: isDark,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: AppGlassmorphismV2.iconGlassContainer(
                          color: effectiveColor,
                          size: 36,
                          isDark: isDark,
                        ),
                        child: Icon(
                          widget.icon,
                          color: effectiveColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          widget.value,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      if (widget.trailing != null) widget.trailing!,
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated gradient card (Maintained for compatibility)
class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> gradientColors;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double borderRadius;

  const GradientCard({
    Key? key,
    required this.child,
    required this.gradientColors,
    this.padding,
    this.onTap,
    this.borderRadius = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      gradientColors: gradientColors,
      padding: padding,
      onTap: onTap,
      borderRadius: borderRadius,
      child: child,
    );
  }
}
