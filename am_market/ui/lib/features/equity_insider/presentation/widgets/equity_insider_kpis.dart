import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_sdk/market/api.dart';

class EquityInsiderKpis extends StatelessWidget {
  final FundamentalRatiosResponse data;

  const EquityInsiderKpis({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Valuation & key metrics'),
        LayoutBuilder(
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
                  label: 'ROCE %',
                  value: data.roce,
                  subtitle: 'Profitability',
                  isPositive: (data.roce ?? 0) > 15,
                  isNegative: (data.roce ?? 0) < 0,
                ),
                _buildKpi(
                  context,
                  label: 'ROA %',
                  value: data.netProfitMarginPercent,
                  subtitle: 'Efficiency',
                  isPositive: ((data.netProfitMarginPercent ?? 0) > 10),
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
              ].map((child) => SizedBox(width: columns == 2 ? (constraints.maxWidth - 8) / 2 : 110, height: 95, child: child)).toList(),
            );
          },
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
    if (isPositive) valColor = const Color(0xFF00C896);
    if (isNegative) valColor = const Color(0xFFF87171);

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
