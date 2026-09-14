import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:am_market_ui/features/f_o/providers/fo_provider.dart';
import 'package:am_market_ui/features/f_o/providers/futures_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FuturesSelectedContractCard extends ConsumerWidget {
  const FuturesSelectedContractCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final marketTheme = context.marketTheme;
    final activeSymbol = ref.watch(foActiveSymbolProvider) ?? 'TCS';
    final selectedContract = ref.watch(selectedFutureContractProvider);

    final tradingSymbol = selectedContract != null
        ? (selectedContract['trading_symbol'] ?? selectedContract['tradingSymbol'] ?? '$activeSymbol FUT 24 SEP 26').toString()
        : '$activeSymbol FUT 24 SEP 26';

    final expiryStr = (selectedContract?['expiry'] ?? '24 Sep 2026').toString();
    final ltp = (selectedContract?['ltp'] as num?)?.toDouble() ?? 2203.50;
    final change = (selectedContract?['change'] as num?)?.toDouble() ?? -2.10;
    final pChange = (selectedContract?['pChange'] as num?)?.toDouble() ?? -0.10;
    final isPositive = change >= 0;
    final deltaColor = isPositive ? marketTheme.positive : marketTheme.negative;
    final lotSize = (selectedContract?['lot_size'] as num?)?.toInt() ?? 65;

    final isIndex = tradingSymbol.contains('FUTIDX') ||
        tradingSymbol.startsWith('NIFTY') ||
        tradingSymbol.startsWith('BANKNIFTY') ||
        tradingSymbol.startsWith('FINNIFTY') ||
        tradingSymbol.startsWith('MIDCPNIFTY');

    final instType = isIndex ? 'FUTIDX' : 'FUTSTK';
    final instDesc = isIndex ? 'Instrument Type: Index Futures Contract' : 'Instrument Type: Stock Futures Contract';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.5),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selected Contract', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  tradingSymbol,
                  style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              _buildReadOnlyBadge(instType, ModuleColors.market, instDesc),
              const SizedBox(width: 6),
              _buildReadOnlyBadge('NSE_FO', colors.textSecondary, 'Exchange Segment: National Stock Exchange F&O'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$activeSymbol Futures - NSE Segment',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),

          // Price Readout
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹${ltp.toStringAsFixed(2)}',
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 24),
              ),
              const SizedBox(width: 10),
              Icon(isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: deltaColor, size: 20),
              Text(
                '${change.toStringAsFixed(2)} (${pChange.toStringAsFixed(2)}%)',
                style: TextStyle(color: deltaColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('14 Sep 2026, 03:30 PM', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          const SizedBox(height: 14),

          // Expiry & Lot Size Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expiry', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(expiryStr, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Lot Size', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text('$lotSize', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyBadge(String label, Color color, String tooltipText) {
    return Tooltip(
      message: tooltipText,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 10),
        ),
      ),
    );
  }
}
