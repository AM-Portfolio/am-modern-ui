import 'package:flutter/material.dart';
import '../../../internal/domain/enums/metric_types.dart';
import 'filter_group.dart';

class MetricTypeFilterGroup extends FilterGroup {
  final List<MetricTypes> availableTypes;
  List<MetricTypes> selectedTypes;
  final VoidCallback onChanged;

  MetricTypeFilterGroup({
    required this.onChanged,
    required this.availableTypes,
    List<MetricTypes>? initialSelection,
  }) : selectedTypes = initialSelection ?? [];

  @override
  String get title => 'Metric Types';

  @override
  IconData get icon => Icons.category_rounded;

  @override
  bool get hasActiveFilters => selectedTypes.isNotEmpty;

  @override
  void reset() {
    selectedTypes.clear();
    onChanged();
  }

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableTypes.map<Widget>((type) {
            final isSelected = selectedTypes.contains(type);
            return FilterChip(
              label: Text(type.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  selectedTypes.add(type);
                } else {
                  selectedTypes.remove(type);
                }
                onChanged();
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
