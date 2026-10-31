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
    final activeExchange = ref.watch(selectedExchangeProvider);
    final asyncData = ref.watch(fundamentalUnifiedProvider(
      EquityFundamentalQuery(symbol: symbol, exchange: activeExchange),
    ));

    return LayoutBuilder(
      builder: (context, outer) {
        final fill = outer.maxHeight.isFinite && outer.maxHeight > 0;
        final metricsBody = asyncData.when(
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

            double? yoyRevGrowth;
            double? yoyProfitGrowth;

            if (data.incomeStatement != null && data.incomeStatement!.length >= 2) {
              try {
                final curr = data.incomeStatement![0];
                final prev = data.incomeStatement![1];

                final currRev = (curr['revenue'] as num?)?.toDouble() ?? (curr['totalRevenue'] as num?)?.toDouble();
                final prevRev = (prev['revenue'] as num?)?.toDouble() ?? (prev['totalRevenue'] as num?)?.toDouble();
                if (currRev != null && prevRev != null && prevRev != 0) {
                  yoyRevGrowth = ((currRev - prevRev) / prevRev.abs()) * 100;
                }

                final currNet = (curr['netIncome'] as num?)?.toDouble() ?? (curr['netProfit'] as num?)?.toDouble();
                final prevNet = (prev['netIncome'] as num?)?.toDouble() ?? (prev['netProfit'] as num?)?.toDouble();
                if (currNet != null && prevNet != null && prevNet != 0) {
                  yoyProfitGrowth = ((currNet - prevNet) / prevNet.abs()) * 100;
                }
              } catch (_) {}
            }

            // Build candidate list of metrics in logical priority order
            final List<_KpiMetric> candidates = [
              if (yoyRevGrowth != null)
                _KpiMetric(
                  label: 'YoY Rev',
                  value: yoyRevGrowth,
                  subtitle: 'Growth',
                  isPositive: yoyRevGrowth > 0,
                  isNegative: yoyRevGrowth < 0,
                ),
              if (yoyProfitGrowth != null)
                _KpiMetric(
                  label: 'YoY PAT',
                  value: yoyProfitGrowth,
                  subtitle: 'Growth',
                  isPositive: yoyProfitGrowth > 0,
                  isNegative: yoyProfitGrowth < 0,
                ),
              if (data.operatingMarginPercent != null)
                _KpiMetric(
                  label: 'OPM %',
                  value: data.operatingMarginPercent,
                  subtitle: 'Profitability',
                  isPositive: data.operatingMarginPercent! > 15,
                  isNegative: data.operatingMarginPercent! < 5,
                ),
              if (data.netProfitMarginPercent != null)
                _KpiMetric(
                  label: 'NPM %',
                  value: data.netProfitMarginPercent,
                  subtitle: 'Profitability',
                  isPositive: data.netProfitMarginPercent! > 10,
                  isNegative: data.netProfitMarginPercent! < 0,
                ),
              if (data.cfoPat != null)
                _KpiMetric(
                  label: 'CFO / PAT',
                  value: data.cfoPat,
                  subtitle: 'Cash Quality',
                  isPositive: data.cfoPat! >= 1.0,
                  isNegative: data.cfoPat! < 0.5,
                ),
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

            final mobileMetrics = _mobileFixedMetrics(
              yoyRevGrowth: yoyRevGrowth,
              operatingMarginPercent: data.operatingMarginPercent,
              peRatio: data.peRatio,
              roe: data.roe,
              roa: data.roa,
              pbRatio: data.pbRatio,
            );

            // Robust filtering: Only display metrics that have valid, populated numeric values (Zero Dashes)
            final validMetrics = candidates.where((m) => m.value != null && m.value!.isFinite).toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobileShell = MediaQuery.sizeOf(context).width < 800;
                if (isMobileShell) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                      mainAxisExtent: 81,
                    ),
                    itemCount: mobileMetrics.length,
                    itemBuilder: (context, i) {
                      final metric = mobileMetrics[i];
                      return _buildMobileKpiCell(
                        context,
                        label: metric.label,
                        value: metric.value,
                        subtitle: metric.subtitle,
                        isPositive: metric.isPositive,
                        isNegative: metric.isNegative,
                      );
                    },
                  );
                }

                if (validMetrics.isEmpty) {
                  return Text(
                    'No populated valuation metrics for this security',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13,
                    ),
                  );
                }

                final metrics = validMetrics.take(12).toList();
                const cols = 4;
                const spacing = AppSpacing.sm;
                final rows = (metrics.length / cols).ceil().clamp(1, 4);
                final bounded = fill &&
                    constraints.maxHeight.isFinite &&
                    constraints.maxHeight > 0;
                final extent = bounded
                    ? ((constraints.maxHeight - spacing * (rows - 1)) / rows)
                        .clamp(72.0, 200.0)
                    : 90.0;
                return GridView.builder(
                  shrinkWrap: !bounded,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    mainAxisExtent: extent,
                  ),
                  itemCount: metrics.length,
                  itemBuilder: (context, i) {
                    final metric = metrics[i];
                    return _buildKpi(
                      context,
                      label: metric.label,
                      value: metric.value!,
                      subtitle: metric.subtitle,
                      isPositive: metric.isPositive,
                      isNegative: metric.isNegative,
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text(
            'Failed to load KPIs: $e',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              'Valuation & Key Metrics',
              activeExchange,
            ),
            if (fill) Expanded(child: metricsBody) else metricsBody,
          ],
        );
      },
    );
  }

  List<_KpiMetric> _mobileFixedMetrics({
    required double? yoyRevGrowth,
    required double? operatingMarginPercent,
    required double? peRatio,
    required double? roe,
    required double? roa,
    required double? pbRatio,
  }) {
    return [
      _KpiMetric(
        label: 'YoY Rev',
        value: yoyRevGrowth,
        subtitle: 'Growth',
        isPositive: (yoyRevGrowth ?? 0) > 0,
        isNegative: (yoyRevGrowth ?? 0) < 0,
      ),
      _KpiMetric(
        label: 'OPM %',
        value: operatingMarginPercent,
        subtitle: 'Profitability',
        isPositive: (operatingMarginPercent ?? 0) > 15,
        isNegative: (operatingMarginPercent ?? 0) < 5,
      ),
      _KpiMetric(
        label: 'P/E',
        value: peRatio,
        subtitle: 'Valuation',
      ),
      _KpiMetric(
        label: 'ROE %',
        value: roe,
        subtitle: 'Profitability',
        isPositive: (roe ?? 0) > 15,
        isNegative: (roe ?? 0) < 0,
      ),
      _KpiMetric(
        label: 'ROA %',
        value: roa,
        subtitle: 'Profitability',
        isPositive: (roa ?? 0) > 1,
        isNegative: (roa ?? 0) < 0,
      ),
      _KpiMetric(
        label: 'P/B',
        value: pbRatio,
        subtitle: 'Valuation',
      ),
    ];
  }

  Widget _buildSectionHeader(BuildContext context, String title, String exchange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (exchange == 'BSE' ? context.colors.statusWarning : context.marketTheme.chartBlue).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  exchange,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: exchange == 'BSE' ? context.colors.statusWarning : context.marketTheme.chartBlue,
                  ),
                ),
              ),
            ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileKpiCell(
    BuildContext context, {
    required String label,
    required double? value,
    required String subtitle,
    bool isPositive = false,
    bool isNegative = false,
  }) {
    Color valColor = context.textPrimary;
    if (value != null && value.isFinite) {
      if (isPositive) valColor = context.marketTheme.positive;
      if (isNegative) valColor = context.marketTheme.negative;
    }

    final valueText = value != null && value.isFinite ? value.toStringAsFixed(2) : '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: context.textTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  valueText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: valColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: ModuleColors.market,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: context.textTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value.toStringAsFixed(2),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: valColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: ModuleColors.market,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
