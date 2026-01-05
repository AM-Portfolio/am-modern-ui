import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:am_design_system/core/contracts/design_contract.dart';
/// A standardized shell for Filter Panels.
/// 
/// Handles the outer container styling (Glassmorphism/Card) and the header layout.
/// Content is injected via [child] or [children].
class AmFilterPanel extends StatelessWidget {
  const AmFilterPanel({
    super.key,
    required this.child,
    this.headerActions,
    this.title = 'Filters',
    this.subtitle,
    this.activeFilterCount,
    this.isExpanded = false,
    this.onExpandToggle,
    this.overrideContract,
  });

  final Widget child;
  final List<Widget>? headerActions;
  final String title;
  final String? subtitle;
  final int? activeFilterCount;
  final bool isExpanded;
  final VoidCallback? onExpandToggle;
  
  final ContainerStyleOverride? overrideContract;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Standard Styles
    final decoration = BoxDecoration(
      color: overrideContract?.backgroundColor ?? (isDark ? theme.cardColor : Colors.white),
      borderRadius: overrideContract?.borderRadius ?? BorderRadius.circular(12),
      border: overrideContract?.border ?? Border.all(color: theme.dividerColor.withOpacity(0.5)),
      boxShadow: overrideContract?.boxShadow ?? [
        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
      ],
    );

    return Container(
      decoration: decoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onExpandToggle,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primaryColor.withOpacity(0.05), theme.primaryColor.withOpacity(0.02)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    // Icon & Title
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.tune_rounded, color: theme.primaryColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                letterSpacing: 0.2,
                              ),
                            ),
                            if (activeFilterCount != null && activeFilterCount! > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$activeFilterCount active',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 11),
                          ),
                      ],
                    ),
                    const Spacer(),
                    // Actions
                    if (headerActions != null) ...headerActions!,
                    const SizedBox(width: 8),
                    // Expand Toggle
                    if (onExpandToggle != null)
                      RotationTransition(
                        turns: const AlwaysStoppedAnimation(0), // TODO: Animate this
                        child: Icon(
                          isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          size: 20, 
                          color: theme.hintColor
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Body
          AnimatedSize(
            duration: 250.ms,
            curve: Curves.easeInOut,
            child: isExpanded
                ? Container(
                    padding: const EdgeInsets.all(8),
                    child: child,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
