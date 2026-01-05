import 'package:flutter/material.dart';

/// Reusable multi-select chips for psychology, reasoning, etc.
class QuickSelectionChips<T> extends StatelessWidget {
  const QuickSelectionChips({
    required this.title,
    required this.availableOptions,
    required this.selectedOptions,
    required this.onSelectionChanged,
    required this.labelBuilder,
    super.key,
    this.headerIcon,
  });
  final String title;
  final List<T> availableOptions;
  final List<T> selectedOptions;
  final ValueChanged<List<T>> onSelectionChanged;
  final String Function(T) labelBuilder;
  final IconData? headerIcon;

  void _toggleOption(T option) {
    final newSelection = List<T>.from(selectedOptions);
    if (newSelection.contains(option)) {
      newSelection.remove(option);
    } else {
      newSelection.add(option);
    }
    onSelectionChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (headerIcon != null) ...[
              Icon(headerIcon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
            ],
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${selectedOptions.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableOptions.map((option) {
            final isSelected = selectedOptions.contains(option);
            return FilterChip(
              label: Text(labelBuilder(option)),
              selected: isSelected,
              onSelected: (_) => _toggleOption(option),
              showCheckmark: true,
              selectedColor: theme.colorScheme.primaryContainer,
              backgroundColor: theme.colorScheme.surface,
              side: BorderSide(
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.3),
              ),
              labelStyle: TextStyle(
                color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
