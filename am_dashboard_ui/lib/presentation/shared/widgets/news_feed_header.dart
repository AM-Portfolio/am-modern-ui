import 'package:am_dashboard_ui/presentation/shared/widgets/news_feed_tab.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

class NewsFeedHeader extends StatelessWidget {
  const NewsFeedHeader({
    super.key,
    required this.tab,
    required this.onTabChanged,
  });

  final NewsFeedTab tab;
  final ValueChanged<NewsFeedTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Market Intelligence',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: ModuleColors.dashboard,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final item in NewsFeedTab.values)
              _NewsTabChip(
                label: item.label,
                selected: tab == item,
                onTap: () => onTabChanged(item),
              ),
          ],
        ),
      ],
    );
  }
}

class _NewsTabChip extends StatelessWidget {
  const _NewsTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.dashboard;
    return Material(
      color: selected ? accent.withValues(alpha: 0.14) : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
              fontFamily: 'Inter',
              color: selected ? accent : context.colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
