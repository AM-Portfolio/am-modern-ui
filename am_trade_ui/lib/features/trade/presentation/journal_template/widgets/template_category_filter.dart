import 'package:flutter/material.dart';
import '../../../../internal/domain/enums/journal_template_category.dart';

/// Animated category filter sidebar
class TemplateCategoryFilter extends StatefulWidget {
  const TemplateCategoryFilter({
    required this.selectedCategory,
    required this.onCategorySelected,
    super.key,
  });

  final JournalTemplateCategory? selectedCategory;
  final Function(JournalTemplateCategory?) onCategorySelected;

  @override
  State<TemplateCategoryFilter> createState() => _TemplateCategoryFilterState();
}

class _TemplateCategoryFilterState extends State<TemplateCategoryFilter> {
  final Map<JournalTemplateCategory, IconData> _categoryIcons = {
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
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Categories',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          _buildCategoryItem(
            context,
            label: 'All Templates',
            icon: Icons.apps,
            isSelected: widget.selectedCategory == null,
            onTap: () => widget.onCategorySelected(null),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: JournalTemplateCategory.values.map((category) {
                return _buildCategoryItem(
                  context,
                  label: category.displayName,
                  icon: _categoryIcons[category] ?? Icons.folder_outlined,
                  isSelected: widget.selectedCategory == category,
                  onTap: () => widget.onCategorySelected(category),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.transparent,
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              value,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color.lerp(
                Colors.transparent,
                Theme.of(context).colorScheme.primary.withOpacity(0.3),
                value,
              )!,
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
