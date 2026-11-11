import 'package:am_market_ui/features/watchlists/data/watchlist_api_client.dart';
import 'package:am_paper_ui/data/paper_market_client.dart';
import 'package:am_paper_ui/data/watchlist_models.dart';
import 'package:am_paper_ui/presentation/widgets/watchlist/watchlist_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePaperMarketClient extends PaperMarketClient {
  final List<List<String>> enrichCalls = [];

  @override
  Future<List<WatchlistStock>> enrichQuotes(
    List<WatchlistStock> rows, {
    bool forceRefresh = false,
  }) async {
    enrichCalls.add(rows.map((r) => r.symbol).toList());
    return rows.map((r) => r.copyWith(ltp: 100.0)).toList();
  }
}

void main() {
  test('WatchlistController dynamic on-the-fly pagination & single-batch enrichment', () async {
    final client = _FakePaperMarketClient();
    final testWatchlistApi = WatchlistApiClient(
      dio: Dio(BaseOptions(baseUrl: 'https://example.com/market')),
    );
    final controller = WatchlistController(
      onSelectSymbol: (_) {},
      client: client,
      watchlistApi: testWatchlistApi,
    );

    // Populate 38 mock stocks
    controller.allRows = List.generate(
      38,
      (i) => WatchlistStock(
        symbol: 'STOCK_$i',
        name: 'Stock $i',
        exchange: 'NSE',
        ltp: 0,
        change: 0,
        changePercent: 0,
      ),
    );

    // Default page size is 15 -> (38 - 1) ~/ 15 + 1 = 3 pages
    expect(controller.pageSize, 15);
    expect(controller.pageCount, 3);
    expect(controller.pageRows.length, 15);
    expect(controller.pageRows.first.symbol, 'STOCK_0');
    expect(controller.pageRows.last.symbol, 'STOCK_14');

    // Page 1: Refresh visible quotes -> exactly 1 batch call with 15 symbols
    await controller.refreshVisibleQuotes();
    expect(client.enrichCalls.length, 1);
    expect(client.enrichCalls.first.length, 15);
    expect(client.enrichCalls.first.first, 'STOCK_0');
    expect(client.enrichCalls.first.last, 'STOCK_14');

    // Page 2: Navigate to page 1 (zero-indexed) -> exactly 15 symbols
    await controller.setPage(1);
    expect(controller.pageIndex, 1);
    expect(controller.pageRows.length, 15);
    expect(controller.pageRows.first.symbol, 'STOCK_15');
    expect(controller.pageRows.last.symbol, 'STOCK_29');
    expect(client.enrichCalls.length, 2);
    expect(client.enrichCalls[1].length, 15);

    // Page 3: Remainder page -> exactly 8 symbols detected on the fly
    await controller.setPage(2);
    expect(controller.pageIndex, 2);
    expect(controller.pageRows.length, 8);
    expect(controller.pageRows.first.symbol, 'STOCK_30');
    expect(controller.pageRows.last.symbol, 'STOCK_37');
    expect(client.enrichCalls.length, 3);
    expect(client.enrichCalls[2].length, 8);

    // Dynamic resize to 25 rows
    controller.setPageSize(25);
    expect(controller.pageSize, 25);
    expect(controller.pageIndex, 0); // resets to first page
    expect(controller.pageCount, 2); // 38 / 25 -> 2 pages
    expect(controller.pageRows.length, 25);

    // Wait for unawaited refreshVisibleQuotes
    await pumpEventQueue();
    expect(client.enrichCalls.length, 4);
    expect(client.enrichCalls[3].length, 25);
  });
}
