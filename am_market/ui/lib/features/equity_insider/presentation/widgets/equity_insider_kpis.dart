import '../../../../core/styles/market_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../providers/equity_insider_provider.dart';

class _KpiMetric {
  final String label;
  final double? value;
  final String subtitle;
  final bool isPositive;
  final bool isNegative;

  const _KpiMetric({
    required this.label,
    required this.value,
    required this.subtitle,
    this.isPositive = false,
    this.isNegative = false,
  });
}

class EquityInsiderKpis extends ConsumerWidget {
  final String symbol;

  const EquityInsiderKpis({super.key, required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(fundamentalRatiosProvider(symbol));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Valuation & key metrics'),
        asyncData.when(
          data: (data) {
            if (data == null) {
              return Text(
                'No ratios available',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 13,
                ),
              );
            }

            final isBank = data.casa != null || data.nim != null || data.netNpa != null;

            // Build candidate list of metrics in logical priority order
            final List<_KpiMetric> candidates = [
              _KpiMetric(
                label: 'P/E',
                value: data.peRatio,
                subtitle: 'Valuation',
              ),
              _KpiMetric(
                label: 'P/B',
                value: data.pbRatio,
                subtitle: 'Valuation',
              ),
              _KpiMetric(
                label: 'ROE %',
                value: data.roe,
                subtitle: 'Profitability',
                isPositive: (data.roe ?? 0) > 15,
                isNegative: (data.roe ?? 0) < 0,
              ),
              _KpiMetric(
                label: 'ROA %',
                value: data.roa,
                subtitle: 'Efficiency',
                isPositive: (data.roa ?? 0) > 1,
                isNegative: (data.roa ?? 0) < 0,
              ),
              if (isBank) ...[
                _KpiMetric(
                  label: 'NIM %',
                  value: data.nim,
                  subtitle: 'Profitability',
                  isPositive: (data.nim ?? 0) > 3,
                ),
                _KpiMetric(
                  label: 'Net NPA %',
                  value: data.netNpa,
                  subtitle: 'Asset Quality',
                  isNegative: (data.netNpa ?? 0) > 1,
                  isPositive: (data.netNpa ?? 0) < 0.5,
                ),
                _KpiMetric(
                  label: 'CASA %',
                  value: data.casa,
                  subtitle: 'Liquidity',
                  isPositive: (data.casa ?? 0) > 40,
                ),
              ] else ...[
                _KpiMetric(
                  label: 'ROCE %',
                  value: data.roce,
                  subtitle: 'Profitability',
                  isPositive: (data.roce ?? 0) > 15,
                  isNegative: (data.roce ?? 0) < 0,
                ),
                _KpiMetric(
                  label: 'EV/EBITDA',
                  value: data.evEbitda,
                  subtitle: 'Valuation',
                ),
                _KpiMetric(
                  label: 'Quick Ratio',
                  value: data.quickRatio,
                  subtitle: 'Liquidity',
                  isPositive: (data.quickRatio ?? 0) >= 1.0,
                  isNegative: (data.quickRatio ?? 0) < 0.7,
                ),
              ],
              _KpiMetric(
                label: 'Dividend Yield %',
                value: data.dividendYield,
                subtitle: 'Yield',
                isPositive: (data.dividendYield ?? 0) > 1.5,
              ),
              _KpiMetric(
                label: 'Debt / Equity',
                value: data.debtToEquity,
                subtitle: 'Leverage',
                isNegative: (data.debtToEquity ?? 0) > 2.0,
                isPositive: (data.debtToEquity ?? 0) < 0.5,
              ),
              _KpiMetric(
                label: 'Current Ratio',
                value: data.currentRatio,
                subtitle: 'Liquidity',
                isPositive: (data.currentRatio ?? 0) >= 1.2,
                isNegative: (data.currentRatio ?? 0) < 0.9,
              ),
            ];

            // Robust filtering: Only display metrics that have valid, populated numeric values (Zero Dashes)
            final validMetrics = candidates.where((m) => m.value != null && m.value!.isFinite).toList();

            if (validMetrics.isEmpty) {
              return Text(
                'No populated valuation metrics for this security',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 13,
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final double totalWidth = constraints.maxWidth;
                int cols = 7;
                if (totalWidth < 380) {
                  cols = 2;
                } else if (totalWidth < 650) {
                  cols = 3;
                } else if (totalWidth < 900) {
                  cols = 4;
                }

                const double spacing = 8.0;
                final double itemWidth = (totalWidth - (spacing * (cols - 1))) / cols;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: validMetrics.map((metric) {
                    return SizedBox(
                      width: itemWidth.clamp(100.0, 200.0),
                      height: 95,
                      child: _buildKpi(
                        context,
                        label: metric.label,
                        value: metric.value!,
                        subtitle: metric.subtitle,
                        isPositive: metric.isPositive,
                        isNegative: metric.isNegative,
                      ),
                    );
                  }).toList(),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text(
            'Failed to load KPIs: $e',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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

  Widget _buildKpi(
    BuildContext context, {
    required String label,
    required double value,
    required String subtitle,
    bool isPositive = false,
    bool isNegative = false,
  }) {
    Color valColor = context.textPrimary;
    if (isPositive) valColor = context.marketTheme.positive;
    if (isNegative) valColor = context.marketTheme.negative;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              color: context.textTertiary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: valColor,
            ),
          ),
          const Spacer(),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
