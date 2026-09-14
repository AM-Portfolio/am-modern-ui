import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FuturesMarketDepthMetricsCard extends ConsumerWidget {
  const FuturesMarketDepthMetricsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final marketTheme = context.marketTheme;

    final buyOrders = [
      {'price': '2,203.40', 'qty': '5,000', 'orders': '3'},
      {'price': '2,203.25', 'qty': '3,750', 'orders': '2'},
      {'price': '2,203.10', 'qty': '2,500', 'orders': '1'},
      {'price': '2,203.00', 'qty': '2,000', 'orders': '3'},
      {'price': '2,202.80', 'qty': '1,750', 'orders': '2'},
    ];

    final sellOrders = [
      {'price': '2,203.60', 'qty': '4,800', 'orders': '3'},
      {'price': '2,203.75', 'qty': '3,600', 'orders': '2'},
      {'price': '2,203.90', 'qty': '2,400', 'orders': '1'},
      {'price': '2,204.00', 'qty': '2,200', 'orders': '2'},
      {'price': '2,204.20', 'qty': '1,900', 'orders': '1'},
    ];

    final metrics = [
      {'label': 'Volume', 'val': '18,72,300'},
      {'label': 'Open', 'val': '2,210.00'},
      {'label': 'High', 'val': '2,232.60'},
      {'label': 'Low', 'val': '2,185.50'},
      {'label': 'Close', 'val': '2,205.60'},
      {'label': 'Prev. OI', 'val': '51,31,200'},
      {'label': 'Avg Price', 'val': '2,198.40'},
      {'label': 'Lower Circuit', 'val': '1,985.00'},
      {'label': 'Upper Circuit', 'val': '2,426.20'},
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
              Text('Total Buy: 21,50,000', style: TextStyle(color: marketTheme.positive, fontWeight: FontWeight.bold, fontSize: 10)),
              Text('Total Sell: 22,10,500', style: TextStyle(color: marketTheme.negative, fontWeight: FontWeight.bold, fontSize: 10)),
            ],
          ),
          const Divider(height: 20, thickness: 0.5),

          // Key Metrics Horizontal Header
          Row(
            children: [
              Text('Key Metrics', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 6),
              Tooltip(
                message: 'Trading metrics including high/low boundaries, circuit limits, and average traded price.',
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
