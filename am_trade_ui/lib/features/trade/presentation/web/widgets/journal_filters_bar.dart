import 'package:flutter/material.dart';

import 'journal/models/journal_mood_options.dart';

class JournalFiltersBar extends StatelessWidget {
  const JournalFiltersBar({
    required this.selectedMoodFilter,
    required this.selectedSentimentFilter,
    required this.selectedTagFilters,
    required this.selectedYear,
    required this.selectedMonth,
    required this.showLast20,
    required this.filterLogic,
    required this.showAdvancedFilters,
    required this.onMoodChanged,
    required this.onSentimentChanged,
    required this.onTagChanged,
    required this.onYearChanged,
    required this.onMonthChanged,
    required this.onShowLast20Changed,
    required this.onFilterLogicChanged,
    required this.onToggleAdvancedFilters,
    required this.onClearFilters,
    super.key,
  });

  final String? selectedMoodFilter;
  final String? selectedSentimentFilter;
  final Set<String> selectedTagFilters;
  final int? selectedYear;
  final int? selectedMonth;
  final bool showLast20;
  final String filterLogic; // 'AND' or 'OR'
  final bool showAdvancedFilters;
  final void Function(String?) onMoodChanged;
  final void Function(String?) onSentimentChanged;
  final void Function(String, bool) onTagChanged;
  final void Function(int?) onYearChanged;
  final void Function(int?) onMonthChanged;
  final void Function(bool) onShowLast20Changed;
  final void Function(String) onFilterLogicChanged;
  final VoidCallback onToggleAdvancedFilters;
  final VoidCallback onClearFilters;

  bool get _hasActiveFilters =>
      selectedMoodFilter != null ||
      selectedSentimentFilter != null ||
      selectedTagFilters.isNotEmpty ||
      selectedYear != null ||
      selectedMonth != null ||
      showLast20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 10),
          _buildTimePeriodFilters(),
          const SizedBox(height: 10),
          _buildMoodAndSentimentRow(theme),
          if (showAdvancedFilters) ...[
            const SizedBox(height: 8),
            _buildFilterCategory(theme, 'Tags', _buildTagChips(theme)),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          Text('Filters', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'AND',
                label: Text('AND', style: TextStyle(fontSize: 11)),
              ),
              ButtonSegment(
                value: 'OR',
                label: Text('OR', style: TextStyle(fontSize: 11)),
              ),
            ],
            selected: {filterLogic},
            onSelectionChanged: (newSelection) => onFilterLogicChanged(newSelection.first),
            style: ButtonStyle(
              textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 10)),
              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
            ),
          ),
        ],
      ),
      Row(
        children: [
          TextButton.icon(
            onPressed: onToggleAdvancedFilters,
            icon: Icon(showAdvancedFilters ? Icons.expand_less : Icons.expand_more, size: 14),
            label: Text(showAdvancedFilters ? 'Less' : 'More', style: const TextStyle(fontSize: 11)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4)),
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.clear_all, size: 14),
              label: const Text('Clear', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4)),
            ),
          ],
        ],
      ),
    ],
  );

  Widget _buildTimePeriodFilters() => Row(
    children: [
      Expanded(
        flex: 2,
        child: _buildDropdownFilter(
          label: 'Year',
          value: selectedYear?.toString(),
          items: _getAvailableYears(),
          onChanged: (value) => onYearChanged(value != null ? int.parse(value) : null),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 2,
        child: _buildDropdownFilter(
          label: 'Month',
          value: selectedMonth?.toString(),
          items: {
            '1': 'Jan',
            '2': 'Feb',
            '3': 'Mar',
            '4': 'Apr',
            '5': 'May',
            '6': 'Jun',
            '7': 'Jul',
            '8': 'Aug',
            '9': 'Sep',
            '10': 'Oct',
            '11': 'Nov',
            '12': 'Dec',
          },
          onChanged: (value) => onMonthChanged(value != null ? int.parse(value) : null),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 3,
        child: FilterChip(
          selected: showLast20,
          label: const Text('Last 20 Entries', style: TextStyle(fontSize: 11)),
          onSelected: onShowLast20Changed,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
    ],
  );

  Widget _buildMoodAndSentimentRow(ThemeData theme) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: _buildFilterCategory(theme, 'Mood', _buildMoodChips(theme))),
      const SizedBox(width: 12),
      Expanded(child: _buildFilterCategory(theme, 'Market Sentiment', _buildSentimentChips(theme))),
    ],
  );

  Widget _buildFilterCategory(ThemeData theme, String title, List<Widget> chips) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 6),
      Wrap(spacing: 4, runSpacing: 4, children: chips),
    ],
  );

  List<Widget> _buildMoodChips(ThemeData theme) => JournalMoodOptions.moods.entries.map((entry) {
    final isSelected = selectedMoodFilter == entry.key;
    return FilterChip(
      selected: isSelected,
      label: Text('${entry.value['emoji']} ${entry.value['label']}', style: const TextStyle(fontSize: 11)),
      onSelected: (selected) => onMoodChanged(selected ? entry.key : null),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      backgroundColor: isSelected ? (entry.value['color'] as Color).withOpacity(0.15) : null,
      selectedColor: (entry.value['color'] as Color).withOpacity(0.2),
      checkmarkColor: entry.value['color'] as Color,
      side: BorderSide(
        color: isSelected ? entry.value['color'] as Color : theme.dividerColor,
        width: isSelected ? 1.5 : 1,
      ),
    );
  }).toList();

  List<Widget> _buildSentimentChips(ThemeData theme) => JournalMoodOptions.sentiments.entries.map((entry) {
    final isSelected = selectedSentimentFilter == entry.key;
    return FilterChip(
      selected: isSelected,
      avatar: Icon(
        entry.value['icon'] as IconData,
        size: 12,
        color: isSelected ? entry.value['color'] as Color : theme.colorScheme.onSurfaceVariant,
      ),
      label: Text(entry.value['label'] as String, style: const TextStyle(fontSize: 11)),
      onSelected: (selected) => onSentimentChanged(selected ? entry.key : null),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      backgroundColor: isSelected ? (entry.value['color'] as Color).withOpacity(0.15) : null,
      selectedColor: (entry.value['color'] as Color).withOpacity(0.2),
      checkmarkColor: entry.value['color'] as Color,
      side: BorderSide(
        color: isSelected ? entry.value['color'] as Color : theme.dividerColor,
        width: isSelected ? 1.5 : 1,
      ),
    );
  }).toList();

  List<Widget> _buildTagChips(ThemeData theme) => JournalMoodOptions.tags.map((tagData) {
    final tag = tagData['label'] as String;
    final isSelected = selectedTagFilters.contains(tag);
    return FilterChip(
      selected: isSelected,
      label: Text(tag, style: const TextStyle(fontSize: 10)),
      onSelected: (selected) => onTagChanged(tag, selected),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      backgroundColor: isSelected ? (tagData['color'] as Color).withOpacity(0.15) : null,
      selectedColor: (tagData['color'] as Color).withOpacity(0.2),
      checkmarkColor: tagData['color'] as Color,
      side: BorderSide(color: isSelected ? tagData['color'] as Color : theme.dividerColor, width: isSelected ? 1.5 : 1),
    );
  }).toList();

  Widget _buildDropdownFilter({
    required String label,
    required String? value,
    required Map<String, String> items,
    required void Function(String?) onChanged,
  }) => Builder(
    builder: (context) {
      final theme = Theme.of(context);
      return DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          isDense: true,
        ),
        items: [
          DropdownMenuItem<String>(
            child: Text('All', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ),
          ...items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
        ],
        onChanged: onChanged,
      );
    },
  );

  Map<String, String> _getAvailableYears() {
    final currentYear = DateTime.now().year;
    final years = <String, String>{};
    for (var i = currentYear; i >= currentYear - 10; i--) {
      years[i.toString()] = i.toString();
    }
    return years;
  }
}
