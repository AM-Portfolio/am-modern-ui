import 'package:flutter/material.dart';

/// Base template widget for filter panels
/// This serves as a base class for both regular filters and favorite filters
class TradeFilterTemplate extends StatelessWidget {
  const TradeFilterTemplate({
    required this.child,
    super.key,
    this.title = 'Filters',
    this.icon = Icons.tune_rounded,
    this.onExpanded,
  });

  final Widget child;
  final String title;
  final IconData icon;
  final VoidCallback? onExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}
