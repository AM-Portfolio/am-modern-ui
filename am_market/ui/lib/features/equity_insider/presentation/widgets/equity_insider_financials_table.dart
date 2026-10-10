import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../../core/styles/market_theme_extension.dart';

class _TakeawayMetric {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String valueText;
  final String? deltaText;
  final bool isPositive;

  const _TakeawayMetric({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.valueText,
    this.deltaText,
    required this.isPositive,
  });
}

class FinancialComparisonSection extends StatelessWidget {
  final List<Map<String, dynamic>> statements;
  final List<Map<String, dynamic>> balanceSheets;
  final bool isQuarterly;
  final int periodCount;
  final bool showRevenue;
  final bool showPAT;
  final bool showPatMargin;
  final bool tableOnly;
  final bool balanceOnly;
  final bool takeawaysOnly;
  /// Chart-bottom strip: tighter padding + readable column widths.
  final bool dense;
  /// When set, only these balance-sheet row labels are shown.
  final Set<String>? balanceVisibleLabels;

  const FinancialComparisonSection({
    super.key,
    required this.statements,
    this.balanceSheets = const [],
    required this.isQuarterly,
    required this.periodCount,
    required this.showRevenue,
    required this.showPAT,
    required this.showPatMargin,
    this.tableOnly = false,
    this.balanceOnly = false,
    this.takeawaysOnly = false,
    this.dense = false,
    this.balanceVisibleLabels,
  });

  @override
  Widget build(BuildContext context) {
    if (takeawaysOnly) {
      return _buildTakeawaysCard(context);
    }
    if (balanceOnly) {
      return _buildBalanceSheetCard(context);
    }
    if (tableOnly) {
      return _buildTableCard(context);
    }

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
              flex: 64,
              child: _buildTableCard(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 36,
              child: _buildTakeawaysCard(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTableCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(dense ? 8 : 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dense ? 'Performance Summary' : 'Financial Performance Summary',
                  style: TextStyle(
                    fontSize: dense ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
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
          SizedBox(height: dense ? 6 : 10),
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
        // Period columns always expand evenly — no right-side dead space.
        Expanded(
          child: Row(
            children: List.generate(recent.length, (colIdx) {
              final curr = recent[colIdx];
              final prev =
                  colIdx + 1 < recent.length ? recent[colIdx + 1] : null;

              final rev = _num(curr, 'revenue', 'totalRevenue');
              final prevRev =
                  prev != null ? _num(prev, 'revenue', 'totalRevenue') : null;
              final revGrowth = prevRev != null && prevRev != 0 && rev != null
                  ? ((rev - prevRev) / prevRev.abs()) * 100
                  : null;

              final pat = _num(curr, 'profitAfterTax', 'netIncome');
              final prevPat =
                  prev != null ? _num(prev, 'profitAfterTax', 'netIncome') : null;
              final patGrowth = prevPat != null && prevPat != 0 && pat != null
                  ? ((pat - prevPat) / prevPat.abs()) * 100
                  : null;

              final patMargin = rev != null && rev != 0 && pat != null
                  ? (pat / rev) * 100
                  : null;

              final opProfit = _num(curr, 'operatingProfit', 'ebit') ??
                  _num(curr, 'operatingIncome') ??
                  (rev != null && _num(curr, 'totalExpenses') != null
                      ? (rev - _num(curr, 'totalExpenses')!)
                      : null);

              return Expanded(
                child: Column(
                  children: [
                    _tableHeaderCell(context, _formatPeriod(periods[colIdx])),
                    if (showRevenue) ...[
                      _tableDataCell(
                          context, rev != null ? '₹${rev.toInt()}' : '---'),
                      _tableDeltaCell(context, revGrowth),
                    ],
                    if (showPAT) ...[
                      _tableDataCell(
                          context, pat != null ? '₹${pat.toInt()}' : '---'),
                      _tableDeltaCell(context, patGrowth),
                    ],
                    if (showPatMargin)
                      _tableDataCell(
                        context,
                        patMargin != null
                            ? '${patMargin.toStringAsFixed(1)}%'
                            : '---',
                      ),
                    _tableDataCell(
                      context,
                      opProfit != null ? '₹${opProfit.toInt()}' : '---',
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// Balance sheet periods × key line items (not income statement leftovers).
  Widget _buildBalanceSheetCard(BuildContext context) {
    final recent = balanceSheets.take(periodCount).toList();
    if (recent.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          border: Border.all(color: context.borderColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'No balance sheet data available',
          style: TextStyle(color: context.textTertiary, fontSize: 12),
        ),
      );
    }

    final periods =
        recent.map((s) => _formatPeriod((s['period'] ?? '').toString())).toList();

    const rows = <(String label, List<String> keys)>[
      ('Total Assets', ['totalAssets']),
      ('Equity', ['equityCapital', 'totalEquity', 'shareholdersEquity']),
      ('Total Liabilities', ['totalLiabilities', 'totalLiab']),
      ('Total Debt', ['totalDebt', 'borrowings', 'longTermDebt']),
      ('Current Assets', ['currentAssets']),
      ('Current Liabilities', ['currentLiabilities']),
      ('Cash', ['cashAndEquivalents', 'cash', 'cashAndBank']),
    ];

    final visibleRows = rows.where((row) {
      if (balanceVisibleLabels != null &&
          !balanceVisibleLabels!.contains(row.$1)) {
        return false;
      }
      return recent.any((sheet) {
        for (final k in row.$2) {
          if (_num(sheet, k) != null) return true;
        }
        return false;
      });
    }).toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(dense ? 8 : 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dense ? 'Balance Sheet' : 'Balance Sheet Summary',
                  style: TextStyle(
                    fontSize: dense ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ),
              Text(
                isQuarterly ? 'Quarterly (₹ Cr)' : 'Annual (₹ Cr)',
                style: TextStyle(fontSize: 10, color: context.textTertiary),
              ),
            ],
          ),
          SizedBox(height: dense ? 6 : 10),
          if (visibleRows.isEmpty)
            Text(
              'No populated balance sheet metrics',
              style: TextStyle(color: context.textTertiary, fontSize: 12),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: dense ? 120 : 130,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tableHeaderCell(context, 'Metric', isFirst: true),
                      ...visibleRows.map(
                        (r) => _tableMetricCell(context, r.$1),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: List.generate(recent.length, (colIdx) {
                      final sheet = recent[colIdx];
                      final prev = colIdx + 1 < recent.length
                          ? recent[colIdx + 1]
                          : null;
                      return Expanded(
                        child: Column(
                          children: [
                            _tableHeaderCell(context, periods[colIdx]),
                            ...visibleRows.map((row) {
                              final val = _numFromKeys(sheet, row.$2);
                              final prevVal = prev != null
                                  ? _numFromKeys(prev, row.$2)
                                  : null;
                              if (val == null) {
                                return _tableDataCell(context, '—');
                              }
                              double? growth;
                              if (prevVal != null && prevVal != 0) {
                                growth =
                                    ((val - prevVal) / prevVal.abs()) * 100;
                              }
                              if (growth == null) {
                                return _tableDataCell(
                                  context,
                                  '₹${val.toInt()}',
                                );
                              }
                              final isPos = growth >= 0;
                              return Container(
                                height: 26,
                                alignment: Alignment.center,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '₹${val.toInt()} ',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: context.textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              '${isPos ? '+' : ''}${growth.toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: isPos
                                                ? context.marketTheme.positive
                                                : context.marketTheme.negative,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  double? _numFromKeys(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = _num(map, k);
      if (v != null) return v;
    }
    return null;
  }

  Widget _buildTakeawaysCard(BuildContext context) {
    final periodLabel = statements.isNotEmpty
        ? _formatPeriod((statements.first['period'] ?? '').toString())
        : (isQuarterly ? 'Quarterly' : 'Annual');

    final metrics = _computeKeyTakeawayMetrics(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 14,
        vertical: dense ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: ModuleColors.market),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Key Takeaways ($periodLabel)',
                  style: TextStyle(
                    fontSize: dense ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: dense ? 8 : 12),
          if (metrics.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Financial trajectory within historical ranges.',
                style: TextStyle(color: context.textSecondary, fontSize: 11),
              ),
            )
          else if (dense)
            _buildTakeawayGrid(context, metrics)
          else
            ...metrics.map((m) => _buildTakeawayRow(context, m)),
        ],
      ),
    );
  }

  /// Dense takeaways: equal-width cards that fill every row (no orphan gaps).
  Widget _buildTakeawayGrid(
    BuildContext context,
    List<_TakeawayMetric> metrics,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Prefer even grids so the last row is never half-empty.
        int cols;
        if (width < 340) {
          cols = 1;
        } else if (width < 640) {
          cols = 2;
        } else if (metrics.length <= 4) {
          cols = metrics.length; // one full row
        } else {
          cols = 4;
        }
        cols = cols.clamp(1, metrics.isEmpty ? 1 : metrics.length);

        final rows = <Widget>[];
        for (var i = 0; i < metrics.length; i += cols) {
          final chunk = metrics.skip(i).take(cols).toList();
          rows.add(
            Padding(
              padding: EdgeInsets.only(bottom: i + cols < metrics.length ? 8 : 0),
              child: Row(
                children: [
                  for (var j = 0; j < chunk.length; j++) ...[
                    if (j > 0) const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 78,
                        child: _buildTakeawayTile(context, chunk[j]),
                      ),
                    ),
                  ],
                  // Pad incomplete last row so columns stay aligned.
                  for (var j = chunk.length; j < cols; j++) ...[
                    const SizedBox(width: 8),
                    const Expanded(child: SizedBox(height: 78)),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }

  Widget _buildTakeawayTile(BuildContext context, _TakeawayMetric metric) {
    final deltaColor = metric.isPositive
        ? context.marketTheme.positive
        : context.marketTheme.negative;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: context.textPrimary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: metric.iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(metric.icon, size: 12, color: metric.iconColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  metric.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            metric.valueText,
            style: TextStyle(
              fontSize: 13,
              color: context.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (metric.deltaText != null) ...[
            const SizedBox(height: 2),
            Text(
              metric.deltaText!,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: deltaColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTakeawayRow(BuildContext context, _TakeawayMetric metric) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: metric.iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(metric.icon, size: 12, color: metric.iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              metric.label,
              style: TextStyle(
                fontSize: 11,
                color: context.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              metric.valueText,
              style: TextStyle(
                fontSize: 11,
                color: context.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (metric.deltaText != null) ...[
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  metric.isPositive
                      ? Icons.arrow_drop_up_rounded
                      : Icons.arrow_drop_down_rounded,
                  size: 14,
                  color: metric.isPositive
                      ? context.marketTheme.positive
                      : context.marketTheme.negative,
                ),
                Text(
                  metric.deltaText!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: metric.isPositive
                        ? context.marketTheme.positive
                        : context.marketTheme.negative,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<_TakeawayMetric> _computeKeyTakeawayMetrics(BuildContext context) {
    final list = <_TakeawayMetric>[];
    final recent = statements.take(2).toList();
    final periodTag = isQuarterly ? 'QoQ' : 'YoY';

    // 1. Revenue
    if (recent.isNotEmpty) {
      final currRev = _num(recent[0], 'revenue', 'totalRevenue');
      final prevRev = recent.length > 1 ? _num(recent[1], 'revenue', 'totalRevenue') : null;
      if (currRev != null) {
        double? delta;
        if (prevRev != null && prevRev != 0) {
          delta = ((currRev - prevRev) / prevRev.abs()) * 100;
        }
        list.add(_TakeawayMetric(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: context.marketTheme.positive,
          label: 'Revenue',
          valueText: '₹ ${NumberFormat('#,##,##0', 'en_IN').format(currRev.toInt())} Cr',
          deltaText: delta != null ? '${delta.abs().toStringAsFixed(1)}% $periodTag' : null,
          isPositive: (delta ?? 0) >= 0,
        ));
      }

      // 2. PAT
      final currPat = _num(recent[0], 'profitAfterTax', 'netIncome');
      final prevPat = recent.length > 1 ? _num(recent[1], 'profitAfterTax', 'netIncome') : null;
      if (currPat != null) {
        double? delta;
        if (prevPat != null && prevPat != 0) {
          delta = ((currPat - prevPat) / prevPat.abs()) * 100;
        }
        list.add(_TakeawayMetric(
          icon: Icons.payments_rounded,
          iconColor: ModuleColors.market,
          label: 'PAT',
          valueText: '₹ ${NumberFormat('#,##,##0', 'en_IN').format(currPat.toInt())} Cr',
          deltaText: delta != null ? '${delta.abs().toStringAsFixed(1)}% $periodTag' : null,
          isPositive: (delta ?? 0) >= 0,
        ));

        // 3. PAT Margin
        if (currRev != null && currRev != 0) {
          final currMargin = (currPat / currRev) * 100;
          double? marginPp;
          if (prevRev != null && prevRev != 0 && prevPat != null) {
            final prevMargin = (prevPat / prevRev) * 100;
            marginPp = currMargin - prevMargin;
          }
          list.add(_TakeawayMetric(
            icon: Icons.pie_chart_outline_rounded,
            iconColor: context.marketTheme.chartPurple,
            label: 'PAT Margin',
            valueText: '${currMargin.toStringAsFixed(1)}%',
            deltaText: marginPp != null ? '${marginPp.abs().toStringAsFixed(1)} pp $periodTag' : null,
            isPositive: (marginPp ?? 0) >= 0,
          ));
        }
      }
    }

    // 4 & 5. Balance Sheet: Total Assets & Equity
    final recentBal = balanceSheets.take(2).toList();
    if (recentBal.isNotEmpty) {
      final currAssets = _num(recentBal[0], 'totalAssets');
      final prevAssets = recentBal.length > 1 ? _num(recentBal[1], 'totalAssets') : null;
      if (currAssets != null) {
        double? assetDelta;
        if (prevAssets != null && prevAssets != 0) {
          assetDelta = ((currAssets - prevAssets) / prevAssets.abs()) * 100;
        }
        list.add(_TakeawayMetric(
          icon: Icons.domain_rounded,
          iconColor: Colors.indigoAccent,
          label: 'Total Assets',
          valueText: '₹ ${NumberFormat('#,##,##0', 'en_IN').format(currAssets.toInt())} Cr',
          deltaText: assetDelta != null ? '${assetDelta.abs().toStringAsFixed(1)}% YoY' : null,
          isPositive: (assetDelta ?? 0) >= 0,
        ));
      }

      final currEquity = _num(recentBal[0], 'equityCapital', 'totalEquity');
      final prevEquity = recentBal.length > 1 ? _num(recentBal[1], 'equityCapital', 'totalEquity') : null;
      if (currEquity != null) {
        double? equityDelta;
        if (prevEquity != null && prevEquity != 0) {
          equityDelta = ((currEquity - prevEquity) / prevEquity.abs()) * 100;
        }
        list.add(_TakeawayMetric(
          icon: Icons.layers_rounded,
          iconColor: Colors.cyanAccent,
          label: 'Equity',
          valueText: '₹ ${NumberFormat('#,##,##0', 'en_IN').format(currEquity.toInt())} Cr',
          deltaText: equityDelta != null ? '${equityDelta.abs().toStringAsFixed(1)}% YoY' : null,
          isPositive: (equityDelta ?? 0) >= 0,
        ));
      }
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
    var v = row[key] ?? (fallback != null ? row[fallback] : null);
    if (v == null && row['lineItems'] is Map) {
      final lineItems = row['lineItems'] as Map;
      v = lineItems[key] ?? (fallback != null ? lineItems[fallback] : null);
      if (v == null) {
        // Match common Title Case variations
        for (final entry in lineItems.entries) {
          final k = entry.key.toString().replaceAll(RegExp(r'[\s_-]'), '').toLowerCase();
          final target1 = key.replaceAll(RegExp(r'[\s_-]'), '').toLowerCase();
          final target2 = fallback?.replaceAll(RegExp(r'[\s_-]'), '').toLowerCase();
          if (k == target1 || (target2 != null && k == target2)) {
            v = entry.value;
            break;
          }
        }
      }
    }
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
