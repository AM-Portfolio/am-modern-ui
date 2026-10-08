import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_market_ui/features/stock_detail/presentation/pages/stock_detail_page.dart';
import 'package:am_market_common/models/market_data.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';

enum MarketWatchSource { indian, global }

/// Resolves LTP / change / % with live override, falling back to batch fields
/// when the live stream has no quote (e.g. weekend / market closed).
({double ltp, double change, double pChange}) resolveWatchQuote({
  required double batchLtp,
  required double batchChange,
  required double batchPChange,
  Map<String, dynamic>? live,
}) {
  var ltp = batchLtp;
  var change = batchChange;
  var pChange = batchPChange;

  if (live != null) {
    final liveLtp = (live['lastPrice'] as num?)?.toDouble();
    final liveChange = (live['change'] as num?)?.toDouble();
    final livePChange = (live['changePercent'] as num?)?.toDouble() ??
        (live['pChange'] as num?)?.toDouble();
    if (liveLtp != null && liveLtp > 0) ltp = liveLtp;
    if (liveChange != null) change = liveChange;
    if (livePChange != null) pChange = livePChange;
  }

  return (ltp: ltp, change: change, pChange: pChange);
}

class ConstituentsTable extends StatelessWidget {
  const ConstituentsTable({
    super.key,
    this.source = MarketWatchSource.indian,
  });

  final MarketWatchSource source;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketProvider>();

    if (source == MarketWatchSource.global) {
      return _GlobalIndicesWatch(provider: provider);
    }

    final data = provider.currentIndexData;
    if (data == null || data.stocks.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(color: MarketColors.textMuted(context)),
        ),
      );
    }

    return StreamBuilder<Map<String, dynamic>>(
      stream: provider.livePriceStream,
      builder: (context, snapshot) {
        return SortableTable<StockData>(
          items: data.stocks,
          onItemTap: (stock) => _navigateToDetail(context, stock.symbol),
          columns: [
            SortableColumn<StockData>(
              title: '#',
              builder: (stock) {
                final i = data.stocks.indexOf(stock) + 1;
                return Text(
                  '$i',
                  style: TextStyle(
                    color: MarketColors.textMuted(context),
                    fontSize: 12,
                  ),
                );
              },
              sortBy: (stock) => data.stocks.indexOf(stock),
            ),
            SortableColumn<StockData>(
              title: 'Symbol',
              builder: (stock) => Text(
                stock.symbol,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: MarketColors.textPrimary(context),
                ),
              ),
              sortBy: (stock) => stock.symbol,
            ),
            SortableColumn<StockData>(
              title: 'LTP',
              builder: (stock) {
                final q = resolveWatchQuote(
                  batchLtp: stock.lastPrice,
                  batchChange: stock.change,
                  batchPChange: stock.pChange,
                  live: provider.getPrice(stock.symbol),
                );
                final hasLive = provider.getPrice(stock.symbol) != null;
                return Text(
                  q.ltp.toStringAsFixed(2),
                  style: TextStyle(
                    fontWeight: hasLive ? FontWeight.bold : FontWeight.normal,
                    color: hasLive
                        ? context.statusInfo
                        : MarketColors.textPrimary(context),
                  ),
                );
              },
              sortBy: (stock) => stock.lastPrice,
              textAlign: TextAlign.end,
            ),
            SortableColumn<StockData>(
              title: 'Chg',
              builder: (stock) {
                final q = resolveWatchQuote(
                  batchLtp: stock.lastPrice,
                  batchChange: stock.change,
                  batchPChange: stock.pChange,
                  live: provider.getPrice(stock.symbol),
                );
                final isPositive = q.change >= 0;
                return Text(
                  '${isPositive ? '+' : ''}${q.change.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isPositive
                        ? MarketColors.positive(context)
                        : MarketColors.negative(context),
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
              sortBy: (stock) => stock.change,
              textAlign: TextAlign.end,
            ),
            SortableColumn<StockData>(
              title: 'Chg %',
              builder: (stock) {
                final q = resolveWatchQuote(
                  batchLtp: stock.lastPrice,
                  batchChange: stock.change,
                  batchPChange: stock.pChange,
                  live: provider.getPrice(stock.symbol),
                );
                final isPositive = q.pChange >= 0;
                return Text(
                  '${isPositive ? '+' : ''}${q.pChange.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isPositive
                        ? MarketColors.positive(context)
                        : MarketColors.negative(context),
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
              sortBy: (stock) => stock.pChange,
              textAlign: TextAlign.end,
            ),
            SortableColumn<StockData>(
              title: 'Trend',
              builder: (stock) {
                final q = resolveWatchQuote(
                  batchLtp: stock.lastPrice,
                  batchChange: stock.change,
                  batchPChange: stock.pChange,
                  live: provider.getPrice(stock.symbol),
                );
                final isPositive = q.pChange >= 0;
                return Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: isPositive
                      ? MarketColors.positive(context)
                      : MarketColors.negative(context),
                );
              },
              sortBy: (stock) => stock.pChange,
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  void _navigateToDetail(BuildContext context, String symbol) {
    final provider = context.read<MarketProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider<MarketProvider>.value(
          value: provider,
          child: StockDetailPage(symbol: symbol),
        ),
      ),
    );
  }
}

class _GlobalIndicesWatch extends StatelessWidget {
  const _GlobalIndicesWatch({required this.provider});

  final MarketProvider provider;

  @override
  Widget build(BuildContext context) {
    final indices = provider.globalIndicesData;
    if (indices.isEmpty) {
      return Center(
        child: Text(
          'No global indices available',
          style: TextStyle(color: MarketColors.textMuted(context)),
        ),
      );
    }

    return StreamBuilder<Map<String, dynamic>>(
      stream: provider.livePriceStream,
      builder: (context, snapshot) {
        return SortableTable<StockIndicesMarketData>(
          items: indices,
          columns: [
            SortableColumn<StockIndicesMarketData>(
              title: '#',
              builder: (item) {
                final i = indices.indexOf(item) + 1;
                return Text(
                  '$i',
                  style: TextStyle(
                    color: MarketColors.textMuted(context),
                    fontSize: 12,
                  ),
                );
              },
              sortBy: (item) => indices.indexOf(item),
            ),
            SortableColumn<StockIndicesMarketData>(
              title: 'Symbol',
              builder: (item) => Text(
                item.indexSymbol,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: MarketColors.textPrimary(context),
                ),
              ),
              sortBy: (item) => item.indexSymbol,
            ),
            SortableColumn<StockIndicesMarketData>(
              title: 'LTP',
              builder: (item) {
                final q = resolveWatchQuote(
                  batchLtp: item.lastPrice,
                  batchChange: item.change,
                  batchPChange: item.pChange,
                  live: provider.getPrice(item.indexSymbol),
                );
                return Text(
                  q.ltp.toStringAsFixed(2),
                  style: TextStyle(color: MarketColors.textPrimary(context)),
                );
              },
              sortBy: (item) => item.lastPrice,
              textAlign: TextAlign.end,
            ),
            SortableColumn<StockIndicesMarketData>(
              title: 'Chg',
              builder: (item) {
                final q = resolveWatchQuote(
                  batchLtp: item.lastPrice,
                  batchChange: item.change,
                  batchPChange: item.pChange,
                  live: provider.getPrice(item.indexSymbol),
                );
                final isPositive = q.change >= 0;
                return Text(
                  '${isPositive ? '+' : ''}${q.change.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isPositive
                        ? MarketColors.positive(context)
                        : MarketColors.negative(context),
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
              sortBy: (item) => item.change,
              textAlign: TextAlign.end,
            ),
            SortableColumn<StockIndicesMarketData>(
              title: 'Chg %',
              builder: (item) {
                final q = resolveWatchQuote(
                  batchLtp: item.lastPrice,
                  batchChange: item.change,
                  batchPChange: item.pChange,
                  live: provider.getPrice(item.indexSymbol),
                );
                final isPositive = q.pChange >= 0;
                return Text(
                  '${isPositive ? '+' : ''}${q.pChange.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isPositive
                        ? MarketColors.positive(context)
                        : MarketColors.negative(context),
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
              sortBy: (item) => item.pChange,
              textAlign: TextAlign.end,
            ),
            SortableColumn<StockIndicesMarketData>(
              title: 'Trend',
              builder: (item) {
                final isPositive = item.pChange >= 0;
                return Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: isPositive
                      ? MarketColors.positive(context)
                      : MarketColors.negative(context),
                );
              },
              sortBy: (item) => item.pChange,
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}
