import 'package:flutter/material.dart';

/// A reusable card widget for displaying grouped information.
///
/// This widget provides a consistent look for displaying sections of information
/// with a title, icon, and children widgets.
class InfoCard extends StatelessWidget {
  const InfoCard({required this.title, required this.children, this.icon, this.iconColor, super.key});

  final String title;
  final List<Widget> children;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: iconColor ?? Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
}
