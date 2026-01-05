
import 'package:flutter/material.dart';

import 'package:am_design_system/core/theme/app_glassmorphism.dart';
import 'package:am_design_system/core/theme/app_glassmorphism_v2.dart';
import 'package:am_design_system/core/utils/conditional_mouse_region.dart';





/// Premium architecture card matching reference image style
class ArchitectureCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<String> features;
  final String? badge;
  final String colorScheme; // 'primary', 'accent', 'success', 'info', 'neutral'
  final VoidCallback? onTap;

  const ArchitectureCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.features,
    this.badge,
    this.colorScheme = 'primary',
    this.onTap,
  }) : super(key: key);

  @override
  State<ArchitectureCard> createState() => _ArchitectureCardState();
}

class _ArchitectureCardState extends State<ArchitectureCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _accentColor {
    final colors = AppGlassmorphismV2.colorSchemes[widget.colorScheme] ?? 
                   AppGlassmorphismV2.colorSchemes['primary']!;
    return colors[0];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: CustomPaint(
                painter: GradientBorderPainter(
                  colors: AppGlassmorphismV2.colorSchemes[widget.colorScheme]!,
                  borderWidth: 2.5,
                  borderRadius: 20,
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppGlassmorphismV2.gradientBorderCard(
                    borderColors: AppGlassmorphismV2.colorSchemes[widget.colorScheme]!,
                    borderRadius: 20,
                    isGlowing: true,
                    isDark: isDark,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon and Title Row
                      Row(
                        children: [
                          // Icon container
                          Container(
                            width: 56,
                            height: 56,
                            decoration: AppGlassmorphismV2.iconGlassContainer(
                              color: _accentColor,
                              isDark: isDark,
                            ),
                            child: Icon(
                              widget.icon,
                              color: _accentColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Title
                          Expanded(
                            child: Text(
                              widget.title,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Features list
                      ...widget.features.map((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: _accentColor.withOpacity(0.7),
                                size: 16,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: TextStyle(
                                    color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87.withOpacity(0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )).toList(),

                      // Badge (like "220 lines" in reference)
                      if (widget.badge != null) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: AppGlassmorphismV2.glassPill(
                              color: _accentColor,
                              isDark: isDark,
                            ),
                            child: Text(
                              widget.badge!,
                              style: TextStyle(
                                color: _accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Simple info card with icon (like top layer cards in reference)
class InfoLayerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String colorScheme;

  const InfoLayerCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.colorScheme = 'primary',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = AppGlassmorphismV2.colorSchemes[colorScheme]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return CustomPaint(
      painter: GradientBorderPainter(
        colors: colors,
        borderWidth: 2.0,
        borderRadius: 16,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppGlassmorphismV2.gradientBorderCard(
          borderColors: colors,
          borderRadius: 16,
          isDark: isDark,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: AppGlassmorphismV2.iconGlassContainer(
                color: colors[0],
                isDark: isDark,
              ),
              child: Icon(icon, color: colors[0], size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white.withOpacity(0.7) : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
