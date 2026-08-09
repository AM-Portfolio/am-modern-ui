import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

class BillingToggle extends StatefulWidget {
  final bool isAnnual;
  final ValueChanged<bool> onChanged;

  const BillingToggle({
    super.key,
    required this.isAnnual,
    required this.onChanged,
  });

  @override
  State<BillingToggle> createState() => _BillingToggleState();
}

class _BillingToggleState extends State<BillingToggle> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);


    return Stack(
      clipBehavior: Clip.none, // Allow discount tag to float outside bounds
      children: [
        // Glassmorphic container wrapper
        ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 260,
              height: 50,
              decoration: BoxDecoration(
                color: context.colors.surface.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: context.colors.border.withValues(alpha: 0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Animated sliding selector indicator
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOutCubic,
                    alignment: widget.isAnnual ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 125,
                      height: 42,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.colors.premiumActionPrimary,
                            context.colors.premiumActionPrimary.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.premiumActionPrimary.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Label texts
                  Positioned.fill(
                    child: Row(
                      children: [
                        // Monthly Option
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => widget.onChanged(false),
                            child: Center(
                              child: Text(
                                'Monthly',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: !widget.isAnnual ? FontWeight.bold : FontWeight.w600,
                                  color: !widget.isAnnual ? Colors.white : context.colors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Annually Option
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => widget.onChanged(true),
                            child: Center(
                              child: Text(
                                'Annually',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: widget.isAnnual ? FontWeight.bold : FontWeight.w600,
                                  color: widget.isAnnual ? Colors.white : context.colors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Floating Discount Tag
        Positioned(
          top: -12,
          right: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.colors.promotionalHighlight, context.colors.promotionalHighlight.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: context.colors.promotionalHighlight.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'Save 20%',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
