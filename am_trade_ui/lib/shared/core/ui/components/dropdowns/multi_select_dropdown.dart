import 'package:flutter/material.dart';

/// A reusable multi-select dropdown widget.
///
/// Allows selecting multiple values from a dropdown list.
class MultiSelectDropdown<T> extends StatefulWidget {
  const MultiSelectDropdown({
    required this.items,
    required this.onSelectionChanged,
    this.selectedItems = const [],
    this.label,
    this.hint,
    super.key,
  });

  final List<T> items;
  final List<T> selectedItems;
  final ValueChanged<List<T>> onSelectionChanged;
  final String? label;
  final String? hint;

  @override
  State<MultiSelectDropdown<T>> createState() => _MultiSelectDropdownState<T>();
}

class _MultiSelectDropdownState<T> extends State<MultiSelectDropdown<T>> {
  late List<T> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ExpansionTile(
            title: Text(
              _selectedItems.isEmpty
                  ? (widget.hint ?? 'Select items')
                  : '${_selectedItems.length} selected',
            ),
            children: widget.items.map((item) {
              final isSelected = _selectedItems.contains(item);
              return CheckboxListTile(
                title: Text(item.toString()),
                value: isSelected,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedItems.add(item);
                    } else {
                      _selectedItems.remove(item);
                    }
                  });
                  widget.onSelectionChanged(List.from(_selectedItems));
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
