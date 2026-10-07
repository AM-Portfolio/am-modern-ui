import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';
import 'package:am_market_ui/features/stock_detail/presentation/pages/stock_detail_page.dart';
import 'package:provider/provider.dart';

class HeatmapGrid extends StatelessWidget {
  final List stocks;
  final MarketProvider provider;

  const HeatmapGrid({
    super.key,
    required this.stocks,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final onCell = context.colors.actionPrimaryFg;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
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

                  double price = stock.lastPrice;
                  double pChange = stock.pChange;

                  if (liveData != null) {
                    price =
                        (liveData['lastPrice'] as num?)?.toDouble() ?? price;
                    pChange = (liveData['changePercent'] as num?)?.toDouble() ??
                        pChange;
                  }

                  final isPositive = pChange >= 0;
                  final intensity = (pChange.abs() / 3).clamp(0.2, 1.0);
                  final baseColor = isPositive
                      ? MarketColors.positive(context)
                      : MarketColors.negative(context);
                  final color = Color.lerp(
                        MarketColors.cardSurface(context),
                        baseColor,
                        intensity,
                      ) ??
                      baseColor;

                  return InkWell(
                    onTap: () {
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
                                  stock.symbol,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: onCell,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${isPositive ? '+' : ''}${pChange.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: onCell,
                                ),
                              ),
                            ],
                          ),
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
        },
      ),
    );
  }
}
