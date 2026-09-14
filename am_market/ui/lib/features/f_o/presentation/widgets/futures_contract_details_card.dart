import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/f_o/providers/fo_provider.dart';
import 'package:am_market_ui/features/f_o/providers/futures_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FuturesContractDetailsCard extends ConsumerWidget {
  const FuturesContractDetailsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final activeSymbol = ref.watch(foActiveSymbolProvider) ?? 'TCS';
    final selectedContract = ref.watch(selectedFutureContractProvider);

    final tradingSymbol = selectedContract != null
        ? (selectedContract['trading_symbol'] ?? selectedContract['tradingSymbol'] ?? '$activeSymbol FUT 24 SEP 26').toString()
        : '$activeSymbol FUT 24 SEP 26';

    final expiryStr = (selectedContract?['expiry'] ?? '24 Sep 2026').toString();
    final lotSize = (selectedContract?['lot_size'] as num?)?.toInt() ?? 65;
    final exchange = (selectedContract?['exchange'] ?? 'NSE_FO').toString();

    final isIndex = tradingSymbol.contains('FUTIDX') ||
        tradingSymbol.startsWith('NIFTY') ||
        tradingSymbol.startsWith('BANKNIFTY') ||
        tradingSymbol.startsWith('FINNIFTY') ||
        tradingSymbol.startsWith('MIDCPNIFTY');

    final instType = (selectedContract?['instrument_type'] ?? (isIndex ? 'FUTIDX' : 'FUTSTK')).toString();

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
          Row(
            children: [
              Text('Contract Details', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 6),
              Tooltip(
                message: 'Specifications for the active derivative contract including trading symbol, exchange, expiry date, and lot size multiplier.',
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ModuleColors.market.withValues(alpha: 0.6)),
                ),
                textStyle: TextStyle(color: colors.textPrimary, fontSize: 12),
                child: Icon(Icons.info_outline_rounded, color: colors.textSecondary, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildRow('Trading Symbol', tradingSymbol, colors),
          const Divider(height: 16, thickness: 0.5),
          _buildRow('Instrument Type', instType, colors),
          const Divider(height: 16, thickness: 0.5),
          _buildRow('Exchange', exchange, colors),
          const Divider(height: 16, thickness: 0.5),
          _buildRow('Expiry', expiryStr, colors),
          const Divider(height: 16, thickness: 0.5),
          _buildRow('Lot Size', '$lotSize', colors),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, AppColorsTheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
