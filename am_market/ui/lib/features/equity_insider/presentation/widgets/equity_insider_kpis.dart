import '../../../../core/styles/market_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../providers/equity_insider_provider.dart';

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
            if (data == null) return const Text('No ratios available');
            
            final isBank = data.casa != null || data.nim != null || data.netNpa != null;
            
            return LayoutBuilder(
              builder: (context, constraints) {
                int columns = 7;
                if (constraints.maxWidth < 600) {
                  columns = 4;
                }
                if (constraints.maxWidth < 350) {
                  columns = 2;
                }

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildKpi(
                      context,
                      label: 'P/E',
                      value: data.peRatio,
                      subtitle: 'Valuation',
                    ),
                    _buildKpi(
                      context,
                      label: 'P/B',
                      value: data.pbRatio,
                      subtitle: 'Valuation',
                    ),
                    _buildKpi(
                      context,
                      label: 'ROE %',
                      value: data.roe,
                      subtitle: 'Profitability',
                      isPositive: (data.roe ?? 0) > 15,
                      isNegative: (data.roe ?? 0) < 0,
                    ),
                    _buildKpi(
                      context,
                      label: 'ROA %',
                      value: data.netProfitMarginPercent,
                      subtitle: 'Efficiency',
                      isPositive: ((data.netProfitMarginPercent ?? 0) > 1),
                    ),
                    if (isBank) ...[
                      _buildKpi(
                        context,
                        label: 'NIM %',
                        value: data.nim,
                        subtitle: 'Profitability',
                        isPositive: (data.nim ?? 0) > 3,
                      ),
                      _buildKpi(
                        context,
                        label: 'Net NPA %',
                        value: data.netNpa,
                        subtitle: 'Asset Quality',
                        isNegative: (data.netNpa ?? 0) > 1,
                        isPositive: (data.netNpa ?? 0) < 0.5,
                      ),
                      _buildKpi(
                        context,
                        label: 'CASA %',
                        value: data.casa,
                        subtitle: 'Liquidity',
                        isPositive: (data.casa ?? 0) > 40,
                      ),
                    ] else ...[
                      _buildKpi(
                        context,
                        label: 'ROCE %',
                        value: data.roce,
                        subtitle: 'Profitability',
                        isPositive: (data.roce ?? 0) > 15,
                        isNegative: (data.roce ?? 0) < 0,
                      ),
                      _buildKpi(
                        context,
                        label: 'EV/EBITDA',
                        value: data.evEbitda,
                        subtitle: 'Valuation',
                      ),
                      _buildKpi(
                        context,
                        label: 'Quick Ratio',
                        value: data.quickRatio,
                        subtitle: 'Liquidity',
                        isPositive: (data.quickRatio ?? 0) >= 1.0,
                        isNegative: (data.quickRatio ?? 0) < 0.7,
                      ),
                    ],
                  ].map((child) => SizedBox(width: columns == 2 ? (constraints.maxWidth - 8) / 2 : 110, height: 95, child: child)).toList(),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text('Failed to load KPIs: $e', style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
    required double? value,
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
            value != null ? value.toStringAsFixed(2) : '—',
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
