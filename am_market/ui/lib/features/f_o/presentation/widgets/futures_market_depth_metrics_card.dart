import 'dart:math';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:am_market_ui/features/f_o/providers/fo_provider.dart';
import 'package:am_market_ui/features/f_o/providers/futures_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class FuturesMarketDepthMetricsCard extends ConsumerWidget {
  const FuturesMarketDepthMetricsCard({super.key});

  static String _formatNum(num n) {
    final formatter = NumberFormat('#,##,##0', 'en_IN');
    return formatter.format(n);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final marketTheme = context.marketTheme;

    final activeSymbol = ref.watch(foActiveSymbolProvider) ?? 'NIFTY';
    final selectedContract = ref.watch(selectedFutureContractProvider);
    final contracts = ref.watch(futuresContractsProvider).maybeWhen(
          data: (d) => d,
          orElse: () => <dynamic>[],
        );

    final firstContract = contracts.isNotEmpty && contracts.first is Map
        ? Map<String, dynamic>.from(contracts.first)
        : null;
    final activeContract = selectedContract ?? firstContract;

    final ltp = (activeContract?['ltp'] as num?)?.toDouble() ?? 2203.50;
    final rawVolume = (activeContract?['volume'] as num?)?.toInt() ?? 1872300;
    final rawOi = (activeContract?['oi'] as num?)?.toInt() ?? 5131200;
    final openPrice = (activeContract?['open'] as num?)?.toDouble() ?? (ltp > 0 ? ltp * 1.003 : 2210.00);
    final highPrice = (activeContract?['high'] as num?)?.toDouble() ?? (ltp > 0 ? ltp * 1.012 : 2232.60);
    final lowPrice = (activeContract?['low'] as num?)?.toDouble() ?? (ltp > 0 ? ltp * 0.992 : 2185.50);
    final closePrice = (activeContract?['close'] as num?)?.toDouble() ?? ltp;

    final avgPrice = (activeContract?['avgPrice'] as num?)?.toDouble() ?? ((highPrice + lowPrice) / 2);
    final lowerCircuit = (activeContract?['lowerCircuit'] as num?)?.toDouble() ?? (ltp * 0.90);
    final upperCircuit = (activeContract?['upperCircuit'] as num?)?.toDouble() ?? (ltp * 1.10);
    final lotSize = (activeContract?['lot_size'] as num?)?.toInt() ?? 65;

    final rawDepth = activeContract?['depth'] as Map?;
    final rawBuyList = rawDepth?['buy'] as List?;
    final rawSellList = rawDepth?['sell'] as List?;

    final List<Map<String, String>> buyOrders = [];
    final List<Map<String, String>> sellOrders = [];

    if (rawBuyList != null && rawBuyList.isNotEmpty) {
      for (final item in rawBuyList.take(5)) {
        if (item is Map) {
          final p = (item['price'] as num?)?.toDouble() ?? 0.0;
          final q = (item['quantity'] as num?)?.toInt() ?? 0;
          final o = (item['orders'] as num?)?.toInt() ?? 1;
          buyOrders.add({
            'price': p.toStringAsFixed(2),
            'qty': _formatNum(q),
            'orders': '$o',
          });
        }
      }
    }

    if (buyOrders.isEmpty) {
      final baseLtp = ltp > 0 ? ltp : 2203.50;
      for (int i = 0; i < 5; i++) {
        final stepPrice = baseLtp - (0.15 * (i + 1));
        final qty = lotSize * (75 - i * 10);
        final ordersCount = max(1, 3 - (i ~/ 2));
        buyOrders.add({
          'price': stepPrice.toStringAsFixed(2),
          'qty': _formatNum(qty),
          'orders': '$ordersCount',
        });
      }
    }

    if (rawSellList != null && rawSellList.isNotEmpty) {
      for (final item in rawSellList.take(5)) {
        if (item is Map) {
          final p = (item['price'] as num?)?.toDouble() ?? 0.0;
          final q = (item['quantity'] as num?)?.toInt() ?? 0;
          final o = (item['orders'] as num?)?.toInt() ?? 1;
          sellOrders.add({
            'price': p.toStringAsFixed(2),
            'qty': _formatNum(q),
            'orders': '$o',
          });
        }
      }
    }

    if (sellOrders.isEmpty) {
      final baseLtp = ltp > 0 ? ltp : 2203.50;
      for (int i = 0; i < 5; i++) {
        final stepPrice = baseLtp + (0.15 * (i + 1));
        final qty = lotSize * (70 - i * 9);
        final ordersCount = max(1, 3 - (i ~/ 2));
        sellOrders.add({
          'price': stepPrice.toStringAsFixed(2),
          'qty': _formatNum(qty),
          'orders': '$ordersCount',
        });
      }
    }

    final totalBuyQty = buyOrders.fold(0, (sum, o) {
      final qStr = o['qty']!.replaceAll(',', '');
      return sum + (int.tryParse(qStr) ?? 0);
    });
    final totalSellQty = sellOrders.fold(0, (sum, o) {
      final qStr = o['qty']!.replaceAll(',', '');
      return sum + (int.tryParse(qStr) ?? 0);
    });

    final metrics = [
      {'label': 'Volume', 'val': _formatNum(rawVolume)},
      {'label': 'Open', 'val': '₹${openPrice.toStringAsFixed(2)}'},
      {'label': 'High', 'val': '₹${highPrice.toStringAsFixed(2)}'},
      {'label': 'Low', 'val': '₹${lowPrice.toStringAsFixed(2)}'},
      {'label': 'Close', 'val': '₹${closePrice.toStringAsFixed(2)}'},
      {'label': 'Prev. OI', 'val': _formatNum(rawOi)},
      {'label': 'Avg Price', 'val': '₹${avgPrice.toStringAsFixed(2)}'},
      {'label': 'Lower Circuit', 'val': '₹${lowerCircuit.toStringAsFixed(2)}'},
      {'label': 'Upper Circuit', 'val': '₹${upperCircuit.toStringAsFixed(2)}'},
    ];

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
          Text('Market Depth (5 Levels)', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          // Side-by-side Buy & Sell Order Tables
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Buy Orders Column
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: marketTheme.positive.withValues(alpha: 0.15),
                      child: Center(
                        child: Text('Buy Orders', style: TextStyle(color: marketTheme.positive, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildDepthHeader('Price (₹)', 'Qty', 'Orders', colors),
                    const Divider(height: 8),
                    ...buyOrders.map((o) => _buildDepthRow(o['price']!, o['qty']!, o['orders']!, marketTheme.positive, colors)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Sell Orders Column
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: marketTheme.negative.withValues(alpha: 0.15),
                      child: Center(
                        child: Text('Sell Orders', style: TextStyle(color: marketTheme.negative, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildDepthHeader('Price (₹)', 'Qty', 'Orders', colors),
                    const Divider(height: 8),
                    ...sellOrders.map((o) => _buildDepthRow(o['price']!, o['qty']!, o['orders']!, marketTheme.negative, colors)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Total Buy & Sell Quantities
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Buy: ${_formatNum(totalBuyQty)}', style: TextStyle(color: marketTheme.positive, fontWeight: FontWeight.bold, fontSize: 10)),
              Text('Total Sell: ${_formatNum(totalSellQty)}', style: TextStyle(color: marketTheme.negative, fontWeight: FontWeight.bold, fontSize: 10)),
            ],
          ),
          const Divider(height: 20, thickness: 0.5),

          // Key Metrics Horizontal Header
          Row(
            children: [
              Text('Key Metrics', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 6),
              Tooltip(
                message: 'Trading metrics for $activeSymbol futures including high/low boundaries, circuit limits, and average traded price.',
                child: Icon(Icons.info_outline_rounded, color: colors.textSecondary, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Single-line Horizontal Key Metrics Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: metrics.map((m) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildMetricItem(m['label']!, m['val']!, colors),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepthHeader(String col1, String col2, String col3, AppColorsTheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(col1, style: TextStyle(color: colors.textSecondary, fontSize: 9, fontWeight: FontWeight.w600))),
        Expanded(child: Text(col2, style: TextStyle(color: colors.textSecondary, fontSize: 9, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
        Expanded(child: Text(col3, style: TextStyle(color: colors.textSecondary, fontSize: 9, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
      ],
    );
  }

  Widget _buildDepthRow(String price, String qty, String orders, Color priceColor, AppColorsTheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(price, style: TextStyle(color: priceColor, fontWeight: FontWeight.bold, fontSize: 10))),
          Expanded(child: Text(qty, style: TextStyle(color: colors.textPrimary, fontSize: 10), textAlign: TextAlign.center)),
          Expanded(child: Text(orders, style: TextStyle(color: colors.textSecondary, fontSize: 10), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String val, AppColorsTheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 9), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(val, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 10), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
