import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/f_o/providers/fo_provider.dart';
import 'package:am_market_ui/features/f_o/providers/futures_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class FuturesContractDetailsCard extends ConsumerWidget {
  const FuturesContractDetailsCard({
    this.mobileInformationLayout = false,
    super.key,
  });

  /// When true, renders mockup "Contract Information" 2-col grid (mobile stack).
  final bool mobileInformationLayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final activeSymbol = ref.watch(foActiveSymbolProvider) ?? 'NIFTY';
    final selectedContract = ref.watch(selectedFutureContractProvider);

    final tradingSymbol = selectedContract != null
        ? (selectedContract['trading_symbol'] ??
                selectedContract['tradingSymbol'] ??
                '$activeSymbol FUT')
            .toString()
        : '$activeSymbol FUT';

    final expiryStr = _formatExpiry(selectedContract);
    final lotSize = (selectedContract?['lot_size'] as num?)?.toInt() ?? 65;
    final exchange = (selectedContract?['exchange'] ?? 'NSE_FO').toString();
    final tickSize = (selectedContract?['tick_size'] as num?)?.toDouble() ??
        (selectedContract?['tickSize'] as num?)?.toDouble() ??
        0.05;
    final ltp = (selectedContract?['ltp'] as num?)?.toDouble() ?? 0.0;
    final contractValue = ltp > 0 ? ltp * lotSize : 0.0;

    final isIndex = tradingSymbol.contains('FUTIDX') ||
        tradingSymbol.startsWith('NIFTY') ||
        tradingSymbol.startsWith('BANKNIFTY') ||
        tradingSymbol.startsWith('FINNIFTY') ||
        tradingSymbol.startsWith('MIDCPNIFTY');

    final underlying = isIndex
        ? (activeSymbol == 'NIFTY' ? 'NIFTY 50' : activeSymbol)
        : activeSymbol;

    final instType = (selectedContract?['instrument_type'] ??
            (isIndex ? 'FUTIDX' : 'FUTSTK'))
        .toString();

    if (mobileInformationLayout) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.5),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contract Information',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _kv('Underlying', underlying, colors)),
                Expanded(child: _kv('Exchange', exchange, colors)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _kv('Lot Size', '$lotSize', colors)),
                Expanded(
                  child: _kv('Tick Size', tickSize.toStringAsFixed(2), colors),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _kv(
                    'Contract Value',
                    contractValue > 0
                        ? '₹${NumberFormat('#,##,##0').format(contractValue.round())}'
                        : '—',
                    colors,
                  ),
                ),
                Expanded(
                  child: _kv('Expiry (Current)', expiryStr, colors),
                ),
              ],
            ),
          ],
        ),
      );
    }

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
              Text(
                'Contract Details',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message:
                    'Specifications for the active derivative contract including trading symbol, exchange, expiry date, and lot size multiplier.',
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ModuleColors.market.withValues(alpha: 0.6),
                  ),
                ),
                textStyle: TextStyle(color: colors.textPrimary, fontSize: 12),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: colors.textSecondary,
                  size: 16,
                ),
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

  static String _formatExpiry(Map<String, dynamic>? selectedContract) {
    if (selectedContract == null) return '—';
    final display = selectedContract['expiry_display'];
    if (display != null && display.toString().isNotEmpty) {
      return display.toString();
    }
    final raw = selectedContract['expiry_ms'] ?? selectedContract['expiry'];
    if (raw is num && raw > 0) {
      return DateFormat('d MMM yyyy')
          .format(DateTime.fromMillisecondsSinceEpoch(raw.toInt()));
    }
    return raw?.toString() ?? '—';
  }

  Widget _kv(String label, String value, AppColorsTheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, AppColorsTheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
