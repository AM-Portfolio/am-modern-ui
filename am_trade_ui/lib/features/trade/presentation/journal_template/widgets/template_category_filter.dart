import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import '../../../internal/domain/enums/journal_template_category.dart';

/// Playbooks category rail — theme tokens; counts on the right; selected chevron.
class TemplateCategoryFilter extends StatelessWidget {
  const TemplateCategoryFilter({
    required this.selectedCategory,
    required this.onCategorySelected,
    this.categoryCounts = const {},
    this.totalCount = 0,
    this.isHorizontal = false,
    super.key,
  });

  final JournalTemplateCategory? selectedCategory;
  final ValueChanged<JournalTemplateCategory?> onCategorySelected;
  final Map<JournalTemplateCategory, int> categoryCounts;
  final int totalCount;
  final bool isHorizontal;

  static final Map<JournalTemplateCategory, IconData> _categoryIcons = {
    JournalTemplateCategory.dailyCheckin: Icons.check_circle_outline,
    JournalTemplateCategory.preMarket: Icons.wb_sunny_outlined,
    JournalTemplateCategory.postMarket: Icons.nightlight_outlined,
    JournalTemplateCategory.tradeRecap: Icons.assessment_outlined,
    JournalTemplateCategory.weeklyReview: Icons.calendar_view_week,
    JournalTemplateCategory.monthlyReview: Icons.calendar_month,
    JournalTemplateCategory.quarterlyReview: Icons.calendar_today,
    JournalTemplateCategory.custom: Icons.edit_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (isHorizontal) {
      return Container(
        height: 56,
        color: colors.cardSurface,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [
            _chip(
              context,
              label: 'All ($totalCount)',
              icon: Icons.apps,
              isSelected: selectedCategory == null,
              onTap: () => onCategorySelected(null),
            ),
            const SizedBox(width: 8),
            ...JournalTemplateCategory.values.map((category) {
              final count = categoryCounts[category] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _chip(
                  context,
                  label: '${category.displayName} ($count)',
                  icon: _categoryIcons[category] ?? Icons.folder_outlined,
                  isSelected: selectedCategory == category,
                  onTap: () => onCategorySelected(category),
                ),
              );
            }),
          ],
        ),
      );
    }

    return Container(
      width: 208,
      decoration: BoxDecoration(
        color: colors.cardSurface,
        border: Border(
          right: BorderSide(color: colors.border.withValues(alpha: 0.45)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Playbooks',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                  ),
                ),
                Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: colors.textSecondary.withValues(alpha: 0.65),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _railItem(
              context,
              label: 'All Templates',
              count: totalCount,
              icon: Icons.apps,
              isSelected: selectedCategory == null,
              onTap: () => onCategorySelected(null),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Divider(
              height: 1,
              color: colors.border.withValues(alpha: 0.4),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
              children: JournalTemplateCategory.values.map((category) {
                return _railItem(
                  context,
                  label: category.displayName,
                  count: categoryCounts[category] ?? 0,
                  icon: _categoryIcons[category] ?? Icons.folder_outlined,
                  isSelected: selectedCategory == category,
                  onTap: () => onCategorySelected(category),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : ModuleColors.trade,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      backgroundColor:
          isSelected ? ModuleColors.trade : Theme.of(context).colorScheme.surface,
      side: BorderSide(
        color: isSelected
            ? Colors.transparent
            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
      ),
      onPressed: onTap,
    );
  }

  Widget _railItem(
    BuildContext context, {
    required String label,
    required int count,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected
            ? ModuleColors.trade.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? ModuleColors.trade : colors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? ModuleColors.trade
                              : colors.textPrimary,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '($count)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? ModuleColors.trade
                            : colors.textSecondary,
                      ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: ModuleColors.trade,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
