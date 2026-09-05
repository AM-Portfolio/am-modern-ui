import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_sdk/market/api.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/styles/market_theme_extension.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/equity_insider_provider.dart';

class EquityInsiderFinancials extends ConsumerStatefulWidget {
  final String symbol;

  const EquityInsiderFinancials({super.key, required this.symbol});

  @override
  ConsumerState<EquityInsiderFinancials> createState() =>
      _EquityInsiderFinancialsState();
}

class _EquityInsiderFinancialsState
    extends ConsumerState<EquityInsiderFinancials> {
  bool _isQuarterly = false;

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(fundamentalFinancialsProvider(widget.symbol));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Financial performance'),
        asyncData.when(
          data: (data) {
            if (data == null) return const Text('No financials data available');

            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;
                if (isMobile) {
                  return Column(
                    children: [
                      _buildRevenueChart(context, data),
                      const SizedBox(height: 16),
                      _buildBalanceSheetChart(context, data),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: _buildRevenueChart(context, data)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildBalanceSheetChart(context, data)),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text(
            'Error loading financials: $e',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
              color: context.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: context.borderColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(BuildContext context, FundamentalRatiosResponse data) {
    final annualStatements = _maps(data.incomeStatement);
    final quarterlyStatements = _maps(data.quarterlyIncomeStatement);

    final statements = _isQuarterly && quarterlyStatements.isNotEmpty
        ? quarterlyStatements
        : annualStatements;

    // Usually API returns latest first, take 4 and reverse for chronological
    final recent = statements.take(4).toList().reversed.toList();

    final Color revColor = context.marketTheme.chartBlue; // Revenue
    final Color patColor = context.marketTheme.positive; // PAT

    return _ChartCard(
      title: 'Revenue & PAT (₹ Cr)',
      headerRight: _buildToggleCapsule(
        context: context,
        firstLabel: 'Annual',
        secondLabel: 'Quarterly',
        isSecondSelected: _isQuarterly,
        onFirstTap: () {
          if (_isQuarterly) setState(() => _isQuarterly = false);
        },
        onSecondTap: () {
          if (!_isQuarterly) setState(() => _isQuarterly = true);
        },
      ),
      child: statements.isEmpty
          ? Center(
              child: Text(
                _isQuarterly
                    ? 'No quarterly statement data'
                    : 'No income statement data',
                style: TextStyle(color: context.textTertiary, fontSize: 12),
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: 180,
                  child: _BarChartWidget(
                    dataList: recent,
                    label1Key: 'revenue',
                    label1Fallback: 'totalRevenue',
                    label2Key: 'profitAfterTax',
                    label2Fallback: 'netIncome',
                    color1: revColor,
                    color2: patColor,
                    name1: 'Revenue',
                    name2: 'PAT',
                    isQuarterly: _isQuarterly,
                  ),
                ),
                const SizedBox(height: 12),
                _ChartLegend(
                  items: [
                    _LegendItem(color: revColor, label: 'Revenue'),
                    _LegendItem(color: patColor, label: 'PAT'),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildBalanceSheetChart(
      BuildContext context, FundamentalRatiosResponse data) {
    final balance = _maps(data.balanceSheet);
    final recent = balance.take(3).toList().reversed.toList();

    final Color assetsColor = context.marketTheme.chartPurple; // Assets
    final Color equityColor = context.marketTheme.chartBlue; // Equity

    return _ChartCard(
      title: 'Balance sheet (₹ Cr)',
      headerRight: Text(
        'Annual',
        style: TextStyle(
          fontSize: 10,
          color: context.marketTheme.chartBlue,
        ),
      ),
      child: balance.isEmpty
          ? Center(
              child: Text(
                'No balance sheet data',
                style: TextStyle(color: context.textTertiary, fontSize: 12),
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: 180,
                  child: _BarChartWidget(
                    dataList: recent,
                    label1Key: 'totalAssets',
                    label2Key: 'equityCapital',
                    label2Fallback: 'totalEquity',
                    color1: assetsColor,
                    color2: equityColor,
                    name1: 'Total Assets',
                    name2: 'Equity',
                    isQuarterly: false,
                  ),
                ),
                const SizedBox(height: 12),
                _ChartLegend(
                  items: [
                    _LegendItem(color: assetsColor, label: 'Total Assets'),
                    _LegendItem(color: equityColor, label: 'Equity'),
                  ],
                ),
              ],
            ),
    );
  }

  /// Reusable capsule toggle styled exactly like the chart's % vs 123 unit toggle
  Widget _buildToggleCapsule({
    required BuildContext context,
    required String firstLabel,
    required String secondLabel,
    required bool isSecondSelected,
    required VoidCallback onFirstTap,
    required VoidCallback onSecondTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCapsuleSegment(
            context: context,
            label: firstLabel,
            isSelected: !isSecondSelected,
            onTap: onFirstTap,
          ),
          _buildCapsuleSegment(
            context: context,
            label: secondLabel,
            isSelected: isSecondSelected,
            onTap: onSecondTap,
          ),
        ],
      ),
    );
  }

  Widget _buildCapsuleSegment({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected
        ? const Color(0xFF00D1FF)
        : (isDark ? Colors.white70 : Colors.black87);
    final bgColor = isSelected
        ? const Color(0xFF00D1FF).withValues(alpha: 0.15)
        : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _maps(List<dynamic>? raw) {
    if (raw == null) return const [];
    return [
      for (final e in raw)
        if (e is Map) e.map((k, v) => MapEntry(k.toString(), v)),
    ];
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget headerRight;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.headerRight,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: context.textSecondary,
                ),
              ),
              headerRight,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _BarChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> dataList;
  final String label1Key;
  final String? label1Fallback;
  final String label2Key;
  final String? label2Fallback;
  final Color color1;
  final Color color2;
  final String name1;
  final String name2;
  final bool isQuarterly;

  const _BarChartWidget({
    required this.dataList,
    required this.label1Key,
    this.label1Fallback,
    required this.label2Key,
    this.label2Fallback,
    required this.color1,
    required this.color2,
    required this.name1,
    required this.name2,
    this.isQuarterly = false,
  });

  double _val(Map<String, dynamic> row, String key, [String? fallback]) {
    final v = row[key] ?? (fallback != null ? row[fallback] : null);
    if (v is num) return v.toDouble();
    if (v is String) {
      final clean = v.replaceAll(RegExp(r'[^\d.-]'), '');
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final barGroups = <BarChartGroupData>[];
    double maxY = 0;

    for (int i = 0; i < dataList.length; i++) {
      final row = dataList[i];
      final val1 = _val(row, label1Key, label1Fallback);
      final val2 = _val(row, label2Key, label2Fallback);

      if (val1 > maxY) maxY = val1;
      if (val2 > maxY) maxY = val2;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val1,
              color: color1.withValues(alpha: 0.9),
              width: 8,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(2),
              ),
            ),
            BarChartRodData(
              toY: val2,
              color: color2.withValues(alpha: 0.9),
              width: 8,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(2),
              ),
            ),
          ],
        ),
      );
    }

    // Add a little padding to the top
    maxY = maxY * 1.15;
    if (maxY == 0) maxY = 100;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        barGroups: barGroups,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => context.cardColor,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final row = dataList[group.x];
              final period = (row['period'] ?? '').toString();
              final val = rod.toY.toInt();
              final String seriesName = rodIndex == 0 ? name1 : name2;
              return BarTooltipItem(
                '$period\n$seriesName: ₹$val Cr',
                TextStyle(
                  color: context.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= dataList.length) return const SizedBox();
                final String period =
                    (dataList[value.toInt()]['period'] ?? '').toString();
                final parts = period.split(' ');
                String shortPeriod = period;
                if (!isQuarterly && parts.length == 2 && parts[1].length == 4) {
                  shortPeriod = 'FY${parts[1].substring(2)}';
                } else if (parts.length == 2 && parts[1].length == 4) {
                  // E.g. Mar 2026 -> Mar 26, Jun 2026 -> Jun 26
                  shortPeriod = '${parts[0]} ${parts[1].substring(2)}';
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    shortPeriod,
                    style: TextStyle(color: context.textSecondary, fontSize: 9),
                  ),
                );
              },
              reservedSize: 24,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value == maxY) return const SizedBox();
                String text = value.toInt().toString();
                if (value >= 1000) {
                  text = '${(value / 1000).round()}K';
                }
                return Text(
                  text,
                  style: TextStyle(color: context.textTertiary, fontSize: 9),
                  textAlign: TextAlign.right,
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: context.borderColor.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final List<_LegendItem> items;

  const _ChartLegend({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.map((e) {
        return Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: e.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                e.label,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LegendItem {
  final Color color;
  final String label;
  _LegendItem({required this.color, required this.label});
}
