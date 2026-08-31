import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:am_common/am_common.dart';
import 'demo_login_button_widget.dart';
import 'feature_flag_panel_widget.dart';

/// Collapsible developer section containing Demo Login and Developer Controls
/// Hidden by default to keep production UI clean
class DevSectionWidget extends StatefulWidget {
  final bool isCompact;
  
  const DevSectionWidget({
    super.key,
    this.isCompact = false,
  });

  @override
  State<DevSectionWidget> createState() => _DevSectionWidgetState();
}

class _DevSectionWidgetState extends State<DevSectionWidget> {
  bool _isExpanded = false;
  bool _isHovering = false;
  
  @override
  Widget build(BuildContext context) {
    if (!DemoLoginConfig.isDevSectionVisible) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final toggleColor = isDark
        ? Colors.white.withValues(alpha: _isHovering ? 0.9 : 0.7)
        : const Color(0xFF475569).withValues(alpha: _isHovering ? 1.0 : 0.8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toggle button
        MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: TextButton.icon(
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            icon: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 16,
              color: toggleColor,
            ),
            label: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: widget.isCompact ? 12 : 13,
                color: toggleColor,
                fontWeight: FontWeight.w500,
              ),
              child: const Text('Developer Options'),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        
        // Collapsible content with animation
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: EdgeInsets.all(widget.isCompact ? 16 : 24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? const Color(0xFF141C2D).withValues(alpha: 0.18)
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF5078FF).withValues(alpha: 0.05)
                                  : const Color(0xFF7896FF).withValues(alpha: 0.05),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Demo Login Button
                            const DemoLoginButtonWidget(),

                            if (DemoLoginConfig.isDeveloperPanelVisible) ...[
                              SizedBox(height: widget.isCompact ? 16 : 24),
                              const FeatureFlagPanelWidget(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
