import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../domain/models/basket_opportunity.dart';
import '../../shared/basket_panel_styles.dart';
import '../../utils/discover_view_state.dart';
import 'discover_layout.dart';
import 'discover_match_ring.dart';

/// Full-width All baskets table. Sorting is external (Discover filter bar).
class DiscoverBasketsTable extends StatelessWidget {
  const DiscoverBasketsTable({
    super.key,
    required this.opportunities,
    required this.period,
    required this.periodColumnLabel,
    required this.onPreview,
  });

  final List<BasketOpportunity> opportunities;
  final DiscoverPerformancePeriod period;
  final String periodColumnLabel;
  final void Function(BasketOpportunity opp) onPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: context.colors.textSecondary,
    );

    final table = Material(
      color: context.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.card,
        side: BorderSide(color: context.dividerColor.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _HeaderRow(style: headerStyle, periodColumnLabel: periodColumnLabel),
          Divider(height: 1, color: context.dividerColor.withValues(alpha: 0.5)),
          for (var i = 0; i < opportunities.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: context.dividerColor.withValues(alpha: 0.35),
              ),
            _DataRow(
              opportunity: opportunities[i],
              period: period,
              onPreview: onPreview,
            ),
          ],
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width.isFinite &&
            width > 0 &&
            width < DiscoverLayout.tableMinScrollWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: DiscoverLayout.tableMinScrollWidth,
              child: table,
            ),
          );
        }
        return table;
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.style,
    required this.periodColumnLabel,
  });

  final TextStyle? style;
  final String periodColumnLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            _cell(
              DiscoverLayout.flexBasket,
              Text('Basket / ETF', style: style),
              padRight: true,
            ),
            _cell(
              DiscoverLayout.flexCategory,
              Text('Category', style: style),
              padRight: true,
            ),
            _cell(
              DiscoverLayout.flexConstituents,
              Text('Constituents', style: style),
              align: TextAlign.right,
              padRight: true,
            ),
            _cell(
              DiscoverLayout.flexMatch,
              Text('Portfolio match', style: style),
              align: TextAlign.right,
              padRight: true,
            ),
            _cell(
              DiscoverLayout.flexPerf,
              Text(periodColumnLabel, style: style),
              align: TextAlign.right,
              padRight: true,
            ),
            _cell(
              DiscoverLayout.flexRequired,
              Text('Required', style: style),
              align: TextAlign.right,
              padRight: true,
            ),
            _cell(
              DiscoverLayout.flexAction,
              Text('Action', style: style),
              align: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.opportunity,
    required this.period,
    required this.onPreview,
  });

  final BasketOpportunity opportunity;
  final DiscoverPerformancePeriod period;
  final void Function(BasketOpportunity opp) onPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ret = opportunity.returnForPeriod(period);
    final retColor = ret == null
        ? context.colors.textSecondary
        : (ret >= 0 ? context.statusSuccess : context.statusError);
    final cat = opportunity.categoryLabel?.trim();
    final initial = opportunity.etfName.isNotEmpty
        ? opportunity.etfName[0].toUpperCase()
        : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onPreview(opportunity),
        hoverColor: context.colors.surface.withValues(alpha: 0.35),
        child: SizedBox(
          height: AppComponentSizes.tableRowHeightDense,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                _cell(
                  DiscoverLayout.flexBasket,
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            ModuleColors.portfolio.withValues(alpha: 0.15),
                        child: Text(
                          initial,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: ModuleColors.portfolio,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              opportunity.etfName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              opportunity.displayTicker,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: context.colors.textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  padRight: true,
                ),
                _cell(
                  DiscoverLayout.flexCategory,
                  Text(
                    (cat != null && cat.isNotEmpty) ? cat : '—',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  padRight: true,
                ),
                _cell(
                  DiscoverLayout.flexConstituents,
                  Text(
                    opportunity.totalItems > 0
                        ? '${opportunity.totalItems}'
                        : '—',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.right,
                  ),
                  align: TextAlign.right,
                  padRight: true,
                ),
                _cell(
                  DiscoverLayout.flexMatch,
                  DiscoverMatchRing(
                    score: opportunity.matchScore,
                    size: DiscoverLayout.matchRingTable,
                    showPercentText: true,
                  ),
                  align: TextAlign.right,
                  padRight: true,
                ),
                _cell(
                  DiscoverLayout.flexPerf,
                  Text(
                    DiscoverViewState.formatReturn(ret),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: retColor,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  align: TextAlign.right,
                  padRight: true,
                ),
                _cell(
                  DiscoverLayout.flexRequired,
                  Text(
                    DiscoverViewState.formatRequiredInr(
                      opportunity.minimumInvestmentAmount,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  align: TextAlign.right,
                  padRight: true,
                ),
                _cell(
                  DiscoverLayout.flexAction,
                  Align(
                    alignment: Alignment.centerRight,
                    child: Theme(
                      data: BasketPanelStyles.accentTheme(context),
                      child: OutlinedButton(
                        onPressed: () => onPreview(opportunity),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ModuleColors.portfolio,
                          side: BorderSide(
                            color:
                                ModuleColors.portfolio.withValues(alpha: 0.45),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 0,
                          ),
                          minimumSize: const Size(
                            DiscoverLayout.actionMinWidth,
                            DiscoverLayout.ctaMinHeight,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Preview →'),
                      ),
                    ),
                  ),
                  align: TextAlign.right,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _cell(
  int flex,
  Widget child, {
  TextAlign align = TextAlign.left,
  bool padRight = false,
}) {
  final aligned = switch (align) {
    TextAlign.right => Align(alignment: Alignment.centerRight, child: child),
    TextAlign.center => Align(alignment: Alignment.center, child: child),
    _ => child,
  };
  return Expanded(
    flex: flex,
    child: Padding(
      padding: EdgeInsets.only(right: padRight ? AppSpacing.sm : 0),
      child: aligned,
    ),
  );
}
