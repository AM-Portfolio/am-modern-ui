import 'package:flutter/material.dart';

class PillSelector<T> extends StatelessWidget {
  const PillSelector({
    required this.items,
    required this.selectedItem,
    required this.onSelectionChanged,
    required this.itemDisplayText,
    super.key,
    this.itemIcon,
    this.primaryColor,
  });
  final List<T> items;
  final T selectedItem;
  final ValueChanged<T> onSelectionChanged;
  final String Function(T) itemDisplayText;
  final IconData Function(T)? itemIcon;
  final Color? primaryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = primaryColor ?? theme.colorScheme.primary;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          items.map((item) {
            final isSelected = item == selectedItem;
            return InkWell(
              onTap: () => onSelectionChanged(item),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : theme.dividerColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (itemIcon != null) ...[
                      Icon(
                        itemIcon!(item),
                        size: 16,
                        color: isSelected ? Colors.white : theme.iconTheme.color,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      itemDisplayText(item),
                      style: TextStyle(
                        color:
                            isSelected
                                ? Colors.white
                                : theme.textTheme.bodyMedium?.color,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}
