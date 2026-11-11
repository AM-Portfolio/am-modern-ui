import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// All Assets dropdown for holdings. Same chrome as Sector and Industry.
class CasAssetClassFilter extends StatelessWidget {
  const CasAssetClassFilter({
    required this.value,
    required this.onChanged,
    super.key,
    this.compact = false,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  /// When true, omit outer padding (embedded in AdvancedHoldingsTemplate header).
  final bool compact;

  static const options = <String, String>{
    'equity': 'Equity',
    'mutual_fund_demat': 'MF (demat)',
    'debt': 'Debt',
    'mutual_fund_folio': 'MF folios',
    'nps': 'NPS',
  };

  static const _all = 'all';
  static const _allLabel = 'All Assets';

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.portfolio;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = value ?? _all;
    final isFiltered = selected != _all;
    final triggerLabel =
        isFiltered ? (options[selected] ?? _allLabel) : _allLabel;

    final menu = SizedBox(
      height: 36,
      child: CustomDropdown<String>(
        value: selected,
        primaryColor: accent,
        isExpanded: false,
        height: 36,
        borderRadius: AppRadii.sm,
        backgroundColor: isFiltered
            ? accent.withValues(alpha: isDark ? 0.14 : 0.08)
            : (isDark ? context.glassOverlay(0.05) : context.surfaceColor),
        borderColor: isFiltered
            ? accent.withValues(alpha: 0.55)
            : context.borderColor,
        menuMaxHeight: 320,
        menuMaxWidth: 240,
        leading: Icon(
          Icons.category_outlined,
          size: 14,
          color: isFiltered ? accent : context.textTertiary,
        ),
        contentPadding: const EdgeInsets.only(left: 10, right: 6),
        selectedItemBuilder: (context, _) => Text(
          triggerLabel,
          style: TextStyle(
            fontSize: AppTypeScale.sm,
            fontWeight: isFiltered ? FontWeight.w600 : FontWeight.w500,
            color: isFiltered ? accent : context.textSecondary,
            height: 1.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        items: [
          DropdownMenuItem<String>(
            value: _all,
            child: Text(
              _allLabel,
              style: TextStyle(
                fontSize: AppTypeScale.sm,
                fontWeight: selected == _all ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          for (final entry in options.entries)
            DropdownMenuItem<String>(
              value: entry.key,
              child: Text(
                entry.value,
                style: TextStyle(
                  fontSize: AppTypeScale.sm,
                  fontWeight:
                      entry.key == selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
        ],
        onChanged: (next) {
          if (next == null) return;
          onChanged(next == _all ? null : next);
        },
      ),
    );
    if (compact) return menu;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Align(alignment: Alignment.centerLeft, child: menu),
    );
  }
}
