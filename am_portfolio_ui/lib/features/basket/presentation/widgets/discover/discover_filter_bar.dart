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
  static const double _periodChipsTrailing = 268;

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
                compact: !showPeriodChips,
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
    final periodLabel = DiscoverFilterBar.periodShort(discoverState.period);
    return PopupMenuButton<DiscoverPerformancePeriod>(
      tooltip: 'Performance period',
      initialValue: discoverState.period,
      onSelected: onPeriodChanged,
      itemBuilder: (context) => [
        for (final p in DiscoverPerformancePeriod.values)
          PopupMenuItem(
            value: p,
            child: Text(DiscoverFilterBar.periodShort(p)),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            periodLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: ModuleColors.portfolio,
                  fontWeight: FontWeight.w700,
                ),
          ),
          Icon(
            Icons.arrow_drop_down,
            color: ModuleColors.portfolio,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({
    required this.discoverState,
    required this.onSortChanged,
    required this.compact,
  });

  final DiscoverViewState discoverState;
  final ValueChanged<DiscoverSortMode> onSortChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DiscoverSortMode>(
      tooltip: 'Sort',
      initialValue: discoverState.sort,
      onSelected: onSortChanged,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: DiscoverSortMode.matchDesc,
          child: Text('Recommended'),
        ),
        PopupMenuItem(
          value: DiscoverSortMode.returnDesc,
          child: Text('Return (high → low)'),
        ),
        PopupMenuItem(
          value: DiscoverSortMode.requiredAsc,
          child: Text('Required ₹ (low → high)'),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tune, color: ModuleColors.portfolio, size: 16),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              discoverState.sortMenuLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: ModuleColors.portfolio,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          Icon(Icons.arrow_drop_down, color: ModuleColors.portfolio, size: 18),
        ],
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
        final moreWidth = _chipWidth('More ▾') + AppSpacing.sm;
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
                PopupMenuButton<BasketTheme>(
                  tooltip: 'More themes',
                  onSelected: (t) =>
                      onThemeSelect(query: t.query, themeId: t.id),
                  itemBuilder: (context) => [
                    for (final t in overflow)
                      PopupMenuItem(
                        value: t,
                        child: Text(
                          t.label,
                          style: TextStyle(
                            fontWeight: selectedThemeId == t.id
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selectedThemeId == t.id
                                ? ModuleColors.portfolio
                                : null,
                          ),
                        ),
                      ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: IgnorePointer(
                      child: AmToggleChip(
                        label: 'More ▾',
                        selected:
                            overflow.any((t) => t.id == selectedThemeId),
                        compact: true,
                        accentColor: ModuleColors.portfolio,
                        onTap: () {},
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
