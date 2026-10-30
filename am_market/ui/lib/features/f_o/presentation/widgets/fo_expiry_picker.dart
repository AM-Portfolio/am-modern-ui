import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// One expiry selector for the option-chain toolbar and the compact mobile tab.
class FoExpiryPicker extends StatelessWidget {
  const FoExpiryPicker({
    super.key,
    required this.expiries,
    required this.activeExpiry,
    required this.onSelected,
    this.compact = false,
    this.fullWidth = false,
  });

  final List<String> expiries;
  final String activeExpiry;
  final ValueChanged<String> onSelected;
  final bool compact;
  final bool fullWidth;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String formatDate(String raw, {bool compact = false}) {
    final date = DateTime.tryParse(raw);
    if (date == null) return raw.isEmpty ? 'Expiry' : raw;
    final label = '${date.day} ${_months[date.month - 1]}';
    return compact ? label : '$label ${date.year}';
  }

  static String formatWithDays(String raw) {
    final label = formatDate(raw);
    final date = DateTime.tryParse(raw);
    if (date == null) return label;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = date.difference(today).inDays;
    return days >= 0 ? '$label ($days Days)' : label;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = expiries.contains(activeExpiry)
        ? activeExpiry
        : (expiries.isEmpty ? '' : expiries.first);

    if (compact) {
      return Semantics(
        label: selected.isEmpty
            ? 'Option Chain expiry unavailable'
            : 'Choose Option Chain expiry, ${formatDate(selected)}',
        button: true,
        child: PopupMenuButton<String>(
          enabled: expiries.isNotEmpty,
          tooltip: selected.isEmpty
              ? 'Expiry unavailable'
              : 'Expiry: ${formatDate(selected)}',
          onSelected: onSelected,
          itemBuilder: (context) => [
            for (final expiry in expiries)
              PopupMenuItem<String>(
                value: expiry,
                child: Row(
                  children: [
                    Expanded(child: Text(formatWithDays(expiry))),
                    if (expiry == selected)
                      Icon(Icons.check, size: 16, color: ModuleColors.market),
                  ],
                ),
              ),
          ],
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: ModuleColors.market),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: ModuleColors.market),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    selected.isEmpty
                        ? 'Expiry'
                        : formatDate(selected, compact: true),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final dropdown = expiries.isEmpty
        ? Text('Expiry unavailable',
            style: TextStyle(color: colors.textSecondary))
        : DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selected,
              isExpanded: fullWidth,
              isDense: true,
              dropdownColor: colors.surface,
              icon: Icon(Icons.calendar_today,
                  size: 13, color: ModuleColors.market),
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              onChanged: (value) {
                if (value != null) onSelected(value);
              },
              items: [
                for (final expiry in expiries)
                  DropdownMenuItem<String>(
                    value: expiry,
                    child: Text(formatWithDays(expiry)),
                  ),
              ],
            ),
          );

    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: ModuleColors.market.withValues(alpha: 0.5)),
      ),
      child: dropdown,
    );
  }
}
