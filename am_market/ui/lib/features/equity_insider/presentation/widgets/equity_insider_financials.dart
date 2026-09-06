import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_sdk/market/api.dart';
import '../../../../core/styles/market_theme_extension.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/equity_insider_provider.dart';
import 'equity_insider_financials_table.dart';
import 'equity_insider_financials_charts.dart';

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
  final int _periodCount = 4;
  bool _showRevenue = true;
  bool _showPAT = true;
  bool _showPatMargin = false;

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

            final annualStatements = _maps(data.incomeStatement);
            final quarterlyStatements = _maps(data.quarterlyIncomeStatement);
            final statements = _isQuarterly && quarterlyStatements.isNotEmpty
                ? quarterlyStatements
                : annualStatements;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildControlBar(context),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 650;
                    if (isMobile) {
                      return Column(
                        children: [
                          _buildRevenueChart(context, statements),
                          const SizedBox(height: 12),
                          _buildBalanceSheetChart(context, data),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: _buildRevenueChart(context, statements)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildBalanceSheetChart(context, data)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                FinancialComparisonSection(
                  statements: statements,
                  balanceSheets: _maps(data.balanceSheet),
                  isQuarterly: _isQuarterly,
                  periodCount: _periodCount,
                  showRevenue: _showRevenue,
                  showPAT: _showPAT,
                  showPatMargin: _showPatMargin,
                ),
              ],
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

  Widget _buildControlBar(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildToggleCapsule(
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
          const SizedBox(width: 14),
          _buildMetricToggle(
            context: context,
            label: 'Rev',
            isActive: _showRevenue,
            onTap: () => setState(() => _showRevenue = !_showRevenue),
          ),
          const SizedBox(width: 6),
          _buildMetricToggle(
            context: context,
            label: 'PAT',
            isActive: _showPAT,
            onTap: () => setState(() => _showPAT = !_showPAT),
          ),
          const SizedBox(width: 6),
          _buildMetricToggle(
            context: context,
            label: 'Margin %',
            isActive: _showPatMargin,
            onTap: () => setState(() => _showPatMargin = !_showPatMargin),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricToggle({
    required BuildContext context,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: isActive ? ModuleColors.market : Colors.transparent,
              border: Border.all(
                color: isActive ? ModuleColors.market : context.textSecondary.withValues(alpha: 0.5),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            child: isActive
                ? const Icon(Icons.check, size: 10, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Performance',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Track key financial metrics and compare across multiple quarters or years.',
            style: TextStyle(
              fontSize: 11,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(BuildContext context, List<Map<String, dynamic>> statements) {
    final recent = statements.take(_periodCount).toList().reversed.toList();
    final Color revColor = ModuleColors.market;
    final Color patColor = context.marketTheme.positive;

    return FinancialChartCard(
      title: 'Revenue & PAT (₹ Cr)',
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
                  height: 140,
                  child: FinancialBarChartWidget(
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
                const SizedBox(height: 10),
                FinancialChartLegend(
                  items: [
                    FinancialLegendItem(color: revColor, label: 'Revenue'),
                    FinancialLegendItem(color: patColor, label: 'PAT'),
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

    final Color assetsColor = context.marketTheme.chartPurple;
    final Color equityColor = ModuleColors.market;

    return FinancialChartCard(
      title: 'Balance sheet (₹ Cr)',
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
                  height: 140,
                  child: FinancialBarChartWidget(
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
                const SizedBox(height: 10),
                FinancialChartLegend(
                  items: [
                    FinancialLegendItem(color: assetsColor, label: 'Total Assets'),
                    FinancialLegendItem(color: equityColor, label: 'Equity'),
                  ],
                ),
              ],
            ),
    );
  }

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
        border: Border.all(color: context.borderColor),
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
    final color = isSelected
        ? Colors.white
        : context.textSecondary;
    final bgColor = isSelected
        ? ModuleColors.market
        : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
