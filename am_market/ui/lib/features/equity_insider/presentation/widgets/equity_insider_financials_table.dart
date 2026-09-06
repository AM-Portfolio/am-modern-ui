import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../../core/styles/market_theme_extension.dart';

class TakeawayItem {
  final IconData icon;
  final Color iconColor;
  final String text;

  const TakeawayItem({
    required this.icon,
    required this.iconColor,
    required this.text,
  });
}

class FinancialComparisonSection extends StatelessWidget {
  final List<Map<String, dynamic>> statements;
  final bool isQuarterly;
  final int periodCount;
  final bool showRevenue;
  final bool showPAT;
  final bool showPatMargin;

  const FinancialComparisonSection({
    super.key,
    required this.statements,
    required this.isQuarterly,
    required this.periodCount,
    required this.showRevenue,
    required this.showPAT,
    required this.showPatMargin,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;
        if (isMobile) {
          return Column(
            children: [
              _buildTableCard(context),
              const SizedBox(height: 12),
              _buildTakeawaysCard(context),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 72,
              child: _buildTableCard(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 28,
              child: _buildTakeawaysCard(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTableCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Financial Performance Summary',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              Text(
                isQuarterly ? 'Quarterly (₹ Cr)' : 'Annual (₹ Cr)',
                style: TextStyle(
                  fontSize: 10,
                  color: context.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildComparisonTable(context),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(BuildContext context) {
    final recent = statements.take(periodCount).toList();
    if (recent.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No statement data available',
            style: TextStyle(color: context.textTertiary, fontSize: 12),
          ),
        ),
      );
    }

    final periods = recent.map((s) => (s['period'] ?? '').toString()).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sticky Metric Column
        SizedBox(
          width: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tableHeaderCell(context, 'Metric', isFirst: true),
              if (showRevenue) ...[
                _tableMetricCell(context, 'Revenue'),
                _tableMetricCell(context, isQuarterly ? 'QoQ Rev %' : 'YoY Rev %', isSub: true),
              ],
              if (showPAT) ...[
                _tableMetricCell(context, 'PAT'),
                _tableMetricCell(context, isQuarterly ? 'QoQ PAT %' : 'YoY PAT %', isSub: true),
              ],
              if (showPatMargin)
                _tableMetricCell(context, 'PAT Margin %'),
              _tableMetricCell(context, 'Operating Profit'),
            ],
          ),
        ),
        // Horizontally Scrollable Period Columns
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(recent.length, (colIdx) {
                final curr = recent[colIdx];
                final prev = colIdx + 1 < recent.length ? recent[colIdx + 1] : null;

                final rev = _num(curr, 'revenue', 'totalRevenue');
                final prevRev = prev != null ? _num(prev, 'revenue', 'totalRevenue') : null;
                final revGrowth = prevRev != null && prevRev != 0 && rev != null
                    ? ((rev - prevRev) / prevRev.abs()) * 100
                    : null;

                final pat = _num(curr, 'profitAfterTax', 'netIncome');
                final prevPat = prev != null ? _num(prev, 'profitAfterTax', 'netIncome') : null;
                final patGrowth = prevPat != null && prevPat != 0 && pat != null
                    ? ((pat - prevPat) / prevPat.abs()) * 100
                    : null;

                final patMargin = rev != null && rev != 0 && pat != null
                    ? (pat / rev) * 100
                    : null;

                final opProfit = _num(curr, 'operatingProfit', 'ebit');

                return SizedBox(
                  width: 90,
                  child: Column(
                    children: [
                      _tableHeaderCell(context, _formatPeriod(periods[colIdx])),
                      if (showRevenue) ...[
                        _tableDataCell(context, rev != null ? '₹${rev.toInt()}' : '---'),
                        _tableDeltaCell(context, revGrowth),
                      ],
                      if (showPAT) ...[
                        _tableDataCell(context, pat != null ? '₹${pat.toInt()}' : '---'),
                        _tableDeltaCell(context, patGrowth),
                      ],
                      if (showPatMargin)
                        _tableDataCell(context, patMargin != null ? '${patMargin.toStringAsFixed(1)}%' : '---'),
                      _tableDataCell(context, opProfit != null ? '₹${opProfit.toInt()}' : '---'),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTakeawaysCard(BuildContext context) {
    final takeaways = _computeTakeaways(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 14, color: ModuleColors.market),
              const SizedBox(width: 6),
              Text(
                'Key Takeaways',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (takeaways.isEmpty)
            Text(
              'Financial trajectory within historical ranges.',
              style: TextStyle(color: context.textSecondary, fontSize: 11),
            )
          else
            ...takeaways.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon, size: 14, color: item.iconColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.text,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  List<TakeawayItem> _computeTakeaways(BuildContext context) {
    final list = <TakeawayItem>[];
    final recent = statements.take(2).toList();
    if (recent.length >= 2) {
      final currRev = _num(recent[0], 'revenue', 'totalRevenue');
      final prevRev = _num(recent[1], 'revenue', 'totalRevenue');
      if (currRev != null && prevRev != null && prevRev != 0) {
        final g = ((currRev - prevRev) / prevRev.abs()) * 100;
        list.add(TakeawayItem(
          icon: g >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          iconColor: g >= 0 ? context.marketTheme.positive : context.marketTheme.negative,
          text: 'Revenue ${g >= 0 ? 'grew' : 'declined'} ${g.abs().toStringAsFixed(1)}% ${isQuarterly ? 'QoQ' : 'YoY'}',
        ));
      }

      final currPat = _num(recent[0], 'profitAfterTax', 'netIncome');
      final prevPat = _num(recent[1], 'profitAfterTax', 'netIncome');
      if (currPat != null && prevPat != null && prevPat != 0) {
        final g = ((currPat - prevPat) / prevPat.abs()) * 100;
        list.add(TakeawayItem(
          icon: g >= 0 ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
          iconColor: g >= 0 ? context.marketTheme.positive : context.marketTheme.negative,
          text: 'PAT ${g >= 0 ? 'surged' : 'dropped'} ${g.abs().toStringAsFixed(1)}% in latest period',
        ));
      }
    }

    if (list.isEmpty) {
      list.add(const TakeawayItem(
        icon: Icons.info_outline_rounded,
        iconColor: ModuleColors.market,
        text: 'Review quarterly earnings reports for multi-period trajectory',
      ));
    }

    return list;
  }

  Widget _tableHeaderCell(BuildContext context, String text, {bool isFirst = false}) {
    return Container(
      height: 28,
      alignment: isFirst ? Alignment.centerLeft : Alignment.center,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: context.textTertiary,
        ),
      ),
    );
  }

  Widget _tableMetricCell(BuildContext context, String text, {bool isSub = false}) {
    return Container(
      height: 26,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSub ? FontWeight.w400 : FontWeight.w500,
          color: isSub ? context.textTertiary : context.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _tableDataCell(BuildContext context, String text) {
    return Container(
      height: 26,
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: context.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _tableDeltaCell(BuildContext context, double? growth) {
    if (growth == null) {
      return _tableDataCell(context, '---');
    }
    final isPos = growth >= 0;
    final color = isPos ? context.marketTheme.positive : context.marketTheme.negative;
    final text = '${isPos ? '+' : ''}${growth.toStringAsFixed(1)}%';

    return Container(
      height: 26,
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  double? _num(Map<String, dynamic> row, String key, [String? fallback]) {
    final v = row[key] ?? (fallback != null ? row[fallback] : null);
    if (v is num) return v.toDouble();
    if (v is String) {
      final clean = v.replaceAll(RegExp(r'[^\d.-]'), '');
      return double.tryParse(clean);
    }
    return null;
  }

  String _formatPeriod(String period) {
    final parts = period.split(' ');
    if (!isQuarterly && parts.length == 2 && parts[1].length == 4) {
      return 'FY${parts[1].substring(2)}';
    } else if (parts.length == 2 && parts[1].length == 4) {
      return '${parts[0]} ${parts[1].substring(2)}';
    }
    return period;
  }
}
