import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../domain/models/basket_catalog.dart';
import '../../../domain/models/basket_opportunity.dart';
import '../../utils/discover_view_state.dart';

typedef DiscoverThemeSelect = void Function({String? query, String? themeId});

/// Single compact toolbar: themes | period + sort + Clear.
class DiscoverFilterBar extends StatelessWidget {
  const DiscoverFilterBar({
    super.key,
    required this.themes,
    required this.defaultQuery,
    required this.selectedThemeId,
    required this.discoverState,
    required this.onThemeSelect,
    required this.onPeriodChanged,
    required this.onSortChanged,
    required this.onClearAll,
  });

  final List<BasketTheme> themes;
  final String defaultQuery;
  final String? selectedThemeId;
  final DiscoverViewState discoverState;
  final DiscoverThemeSelect onThemeSelect;
  final ValueChanged<DiscoverPerformancePeriod> onPeriodChanged;
  final ValueChanged<DiscoverSortMode> onSortChanged;
  final VoidCallback onClearAll;

  static String periodShort(DiscoverPerformancePeriod p) => switch (p) {
        DiscoverPerformancePeriod.oneY => '1Y',
        DiscoverPerformancePeriod.threeY => '3Y',
        DiscoverPerformancePeriod.fiveY => '5Y',
        DiscoverPerformancePeriod.all => 'All',
      };

  /// Trailing cluster width estimate for period chips + sort + clear.
  static const double _periodChipsTrailing = 236;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showPeriodChips =
              constraints.maxWidth >= AmBreakpoints.mobile + 80 &&
                  constraints.maxWidth >= _periodChipsTrailing + 180;

          return Row(
            children: [
              Expanded(
                child: _ThemeOverflowRow(
                  themes: themes,
                  selectedThemeId: selectedThemeId,
                  defaultQuery: defaultQuery,
                  onThemeSelect: onThemeSelect,
                  chipStyle: chipStyle,
                  trailingReserve: 0,
                ),
              ),
              if (showPeriodChips)
                _PeriodChips(
                  discoverState: discoverState,
                  onPeriodChanged: onPeriodChanged,
                )
              else
                _PeriodMenu(
                  discoverState: discoverState,
                  onPeriodChanged: onPeriodChanged,
                ),
              _SortMenu(
                discoverState: discoverState,
                onSortChanged: onSortChanged,
              ),
              _ClearButton(onClearAll: onClearAll),
            ],
          );
        },
      ),
    );
  }
}

class _PeriodChips extends StatelessWidget {
  const _PeriodChips({
    required this.discoverState,
    required this.onPeriodChanged,
  });

  final DiscoverViewState discoverState;
  final ValueChanged<DiscoverPerformancePeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final p in DiscoverPerformancePeriod.values) ...[
          if (p != DiscoverPerformancePeriod.values.first)
            const SizedBox(width: AppSpacing.xs),
          AmToggleChip(
            label: DiscoverFilterBar.periodShort(p),
            selected: discoverState.period == p,
            compact: true,
            accentColor: ModuleColors.portfolio,
            onTap: () => onPeriodChanged(p),
          ),
        ],
      ],
    );
  }
}

class _PeriodMenu extends StatelessWidget {
  const _PeriodMenu({
    required this.discoverState,
    required this.onPeriodChanged,
  });

  final DiscoverViewState discoverState;
  final ValueChanged<DiscoverPerformancePeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: _GlobalStyleDropdown<DiscoverPerformancePeriod>(
        width: 52,
        value: discoverState.period,
        items: [
          for (final p in DiscoverPerformancePeriod.values)
            p.toSimpleDropdownItem(
              text: DiscoverFilterBar.periodShort(p),
              fontSize: 12,
            ),
        ],
        onChanged: (p) {
          if (p != null) onPeriodChanged(p);
        },
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({
    required this.discoverState,
    required this.onSortChanged,
  });

  final DiscoverViewState discoverState;
  final ValueChanged<DiscoverSortMode> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: _GlobalStyleDropdown<DiscoverSortMode>(
        width: 128,
        value: discoverState.sort,
        items: [
          DiscoverSortMode.matchDesc.toSimpleDropdownItem(
            text: 'Recommended',
            fontSize: 12,
          ),
          DiscoverSortMode.returnDesc.toSimpleDropdownItem(
            text: 'Return',
            fontSize: 12,
          ),
          DiscoverSortMode.requiredAsc.toSimpleDropdownItem(
            text: 'Required ₹',
            fontSize: 12,
          ),
        ],
        onChanged: (mode) {
          if (mode != null) onSortChanged(mode);
        },
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onClearAll});

  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onClearAll,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Clear',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ThemeOverflowRow extends StatelessWidget {
  const _ThemeOverflowRow({
    required this.themes,
    required this.selectedThemeId,
    required this.defaultQuery,
    required this.onThemeSelect,
    required this.chipStyle,
    this.trailingReserve = 0,
  });

  final List<BasketTheme> themes;
  final String? selectedThemeId;
  final String defaultQuery;
  final DiscoverThemeSelect onThemeSelect;
  final TextStyle? chipStyle;
  final double trailingReserve;

  double _chipWidth(String label) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: chipStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width + AppSpacing.sm * 2 + AppSpacing.xs * 2 + 4;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final budget =
            (constraints.maxWidth - trailingReserve).clamp(80.0, 9999.0);
        const moreWidth = 40.0 + AppSpacing.sm;
        final topPicksWidth = _chipWidth('Top picks') + AppSpacing.sm;
        var used = topPicksWidth;
        final visible = <BasketTheme>[];
        final overflow = <BasketTheme>[];

        for (var i = 0; i < themes.length; i++) {
          final t = themes[i];
          final w = _chipWidth(t.label) + AppSpacing.sm;
          final remaining = themes.length - i - 1;
          final reserveMore = remaining > 0 ? moreWidth : 0.0;
          if (used + w + reserveMore <= budget) {
            visible.add(t);
            used += w;
          } else {
            overflow.addAll(themes.sublist(i));
            break;
          }
        }

        if (selectedThemeId != null) {
          final inOverflow =
              overflow.indexWhere((t) => t.id == selectedThemeId);
          if (inOverflow >= 0 && visible.isNotEmpty) {
            final selected = overflow.removeAt(inOverflow);
            overflow.insert(0, visible.removeLast());
            visible.add(selected);
          }
        }

        Widget chip({
          required String label,
          required bool selected,
          required VoidCallback onTap,
        }) {
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: AmToggleChip(
              label: label,
              selected: selected,
              compact: true,
              accentColor: ModuleColors.portfolio,
              onTap: onTap,
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              chip(
                label: 'Top picks',
                selected: selectedThemeId == null,
                onTap: () =>
                    onThemeSelect(query: defaultQuery, themeId: null),
              ),
              for (final t in visible)
                chip(
                  label: t.label,
                  selected: selectedThemeId == t.id,
                  onTap: () {
                    if (selectedThemeId == t.id) {
                      onThemeSelect(query: defaultQuery, themeId: null);
                    } else {
                      onThemeSelect(query: t.query, themeId: t.id);
                    }
                  },
                ),
              if (overflow.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: _GlobalStyleDropdown<BasketTheme>(
                    width: 40,
                    icon: Icons.more_horiz,
                    items: [
                      for (final t in overflow)
                        t.toSimpleDropdownItem(
                          text: t.label,
                          fontSize: 12,
                        ),
                    ],
                    onChanged: (t) {
                      if (t != null) {
                        onThemeSelect(query: t.query, themeId: t.id);
                      }
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Compact overlay dropdown matching [MobileTimeFrameDropdown].
class _GlobalStyleDropdown<T> extends StatelessWidget {
  const _GlobalStyleDropdown({
    required this.width,
    required this.items,
    required this.onChanged,
    this.value,
    this.hint,
    this.icon,
  });

  final double width;
  final T? value;
  final String? hint;
  final IconData? icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: width,
      child: CustomDropdown<T>(
        value: value,
        hint: hint,
        icon: icon,
        height: 36,
        isExpanded: true,
        fontSize: 12,
        iconSize: icon == Icons.more_horiz ? 18 : 16,
        borderRadius: 10,
        menuMaxHeight: MobileTimeFrameDropdown.menuMaxHeightForThreeItems,
        menuMaxWidth: width < 120 ? 160 : width,
        primaryColor: ModuleColors.portfolio,
        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : null,
        borderColor: isDark ? Colors.white.withValues(alpha: 0.1) : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: icon == Icons.more_horiz ? 4 : 6,
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
