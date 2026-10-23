import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';
import 'package:am_market_ui/features/stock_detail/presentation/pages/stock_detail_page.dart';
import 'package:am_market_ui/shared/widgets/index_heatmap_panel.dart';
import 'package:provider/provider.dart';

/// Legacy grid used by Heatmap Explorer custom builds.
///
/// Mobile uses overflow-safe [IndexHeatmapTile] rows (no aspect-ratio squeeze).
/// Desktop keeps a wider card with optional price (never paints ₹0.00).
class HeatmapGrid extends StatelessWidget {
  final List stocks;
  final MarketProvider provider;
  final ValueChanged<String>? onSelectStock;

  const HeatmapGrid({
    super.key,
    required this.stocks,
    required this.provider,
    this.onSelectStock,
  });

  static Color _labelOn(Color background) {
    return background.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;
  }

  double _resolvedChange(dynamic stock, Map<String, dynamic>? liveData) {
    final heat = provider.heatmapValues?[stock.symbol as String];
    final livePct = (liveData?['changePercent'] as num?)?.toDouble() ??
        (liveData?['pChange'] as num?)?.toDouble();
    final stockPct = (stock.pChange as num?)?.toDouble() ?? 0.0;
    if (livePct != null && livePct.abs() > 1e-9) return livePct;
    if (heat != null && heat.abs() > 1e-9) return heat;
    return stockPct;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    return Padding(
      padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (isMobile) {
            return _buildMobileSafeRows(context, constraints);
          }
          return _buildDesktopGrid(context, constraints);
        },
      ),
    );
  }

  Widget _buildMobileSafeRows(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    int cols = (constraints.maxWidth / 110).floor().clamp(3, 6);
    return StreamBuilder<Map<String, dynamic>>(
      stream: provider.livePriceStream,
      builder: (context, snapshot) {
        final rows = <List<dynamic>>[];
        for (var i = 0; i < stocks.length; i += cols) {
          rows.add(
            stocks.sublist(i, (i + cols).clamp(0, stocks.length)),
          );
        }
        return ListView.separated(
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, r) {
            final row = rows[r];
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var c = 0; c < row.length; c++) ...[
                    if (c > 0) const SizedBox(width: 6),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final stock = row[c];
                          final live = provider.getPrice(stock.symbol);
                          final pChange = _resolvedChange(stock, live);
                          return IndexHeatmapTile(
                            symbol: stock.symbol as String,
                            value: pChange,
                            onTap: () {
                              if (onSelectStock != null) {
                                onSelectStock!(stock.symbol);
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ChangeNotifierProvider<
                                          MarketProvider>.value(
                                    value: provider,
                                    child: StockDetailPage(
                                      symbol: stock.symbol,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  // Fill remaining cells so last row stays aligned.
                  for (var c = row.length; c < cols; c++) ...[
                    const SizedBox(width: 6),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDesktopGrid(BuildContext context, BoxConstraints constraints) {
    int crossAxisCount = (constraints.maxWidth / 200).floor();
    if (crossAxisCount < 2) crossAxisCount = 2;

    return StreamBuilder<Map<String, dynamic>>(
      stream: provider.livePriceStream,
      builder: (context, snapshot) {
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 2.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: stocks.length,
          itemBuilder: (context, index) {
            final stock = stocks[index];
            final liveData = provider.getPrice(stock.symbol);

            double price = (stock.lastPrice as num?)?.toDouble() ?? 0.0;
            if (liveData != null) {
              price =
                  (liveData['lastPrice'] as num?)?.toDouble() ?? price;
            }
            final pChange = _resolvedChange(stock, liveData);
            final showPrice = price.abs() > 1e-9;

            final Color color;
            final Color onCell;
            if (pChange.abs() < 1e-9) {
              color = MarketColors.cardSurface(context);
              onCell = MarketColors.textMuted(context);
            } else {
              final isPositive = pChange > 0;
              final intensity = (pChange.abs() / 3).clamp(0.2, 1.0);
              final baseColor = isPositive
                  ? MarketColors.positive(context)
                  : MarketColors.negative(context);
              color = Color.lerp(
                    MarketColors.cardSurface(context),
                    baseColor,
                    intensity,
                  ) ??
                  baseColor;
              onCell = _labelOn(color);
            }

            return InkWell(
              onTap: () {
                if (onSelectStock != null) {
                  onSelectStock!(stock.symbol);
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChangeNotifierProvider<MarketProvider>.value(
                      value: provider,
                      child: StockDetailPage(symbol: stock.symbol),
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: MarketColors.borderDefault(context)
                        .withValues(alpha: 0.4),
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            stock.symbol as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: onCell,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${pChange > 0 ? '+' : ''}${pChange.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: onCell,
                          ),
                        ),
                      ],
                    ),
                    if (showPrice)
                      Text(
                        NumberFormat.currency(symbol: '₹', locale: 'en_IN')
                            .format(price),
                        style: TextStyle(
                          fontSize: 12,
                          color: onCell.withValues(alpha: 0.75),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
