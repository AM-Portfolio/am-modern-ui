import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_list.dart';
import 'package:am_trade_ui/features/trade/internal/data/dtos/trade_portfolio_dto.dart';
import 'package:am_trade_ui/features/trade/internal/data/portfolio_book_merge.dart';
import 'package:am_trade_ui/features/trade/presentation/models/visible_trade_portfolios.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('trade portfolio book merge', () {
    test('includePaper is set on the by-owner uri', () {
      expect(
        withIncludePaper(
          'https://am-dev.asrax.in/trade/v1/portfolio-summary/by-owner',
        ),
        'https://am-dev.asrax.in/trade/v1/portfolio-summary/by-owner?includePaper=true',
      );
    });

    test('portfolio list keeps broker, email, and paper and drops deleted', () {
      final books = parsePortfolioServiceBooks([
        {
          'portfolioId': 'broker-1',
          'portfolioName': 'MCP-UC-A-Broker',
          'kind': 'BROKER',
        },
        {
          'id': 'email-1',
          'name': 'MCP-UC-B-Email',
          'kind': 'EMAIL',
        },
        {
          'portfolioId': 'paper-1',
          'portfolioName': 'Paper OMS test',
          'kind': 'PAPER',
        },
        {
          'portfolioId': 'gone',
          'portfolioName': 'Removed',
          'kind': 'DELETED',
        },
        {'portfolioId': 'all', 'portfolioName': 'All Portfolios'},
      ]);

      expect(books.map((book) => book.portfolioId), ['broker-1', 'email-1', 'paper-1']);
      expect(books.map((book) => book.name), [
        'MCP-UC-A-Broker',
        'MCP-UC-B-Email',
        'Paper OMS test',
      ]);
    });

    test('trade metrics win when the same id is on both lists', () {
      const trade = TradePortfolioListDto(
        portfolios: [
          TradePortfolioDto(
            portfolioId: 'paper-1',
            name: 'Paper OMS test',
            totalTrades: 1,
            netProfitLoss: 11.8,
          ),
        ],
      );
      final merged = mergePortfolioBooks(trade, [
        const TradePortfolioDto(portfolioId: 'paper-1', name: 'Paper'),
        const TradePortfolioDto(
          portfolioId: 'broker-1',
          name: 'MCP-UC-A-Broker',
        ),
      ]);

      expect(merged.portfolios, hasLength(2));
      expect(merged.portfolios.first.totalTrades, 1);
      expect(merged.portfolios.first.name, 'Paper OMS test');
      expect(merged.portfolios.last.portfolioId, 'broker-1');
      expect(merged.totalCount, 2);
    });
  });

  group('visible trade portfolios', () {
    test('shell paper book and the open url stay visible before trade rows', () {
      final visible = mergeVisibleTradePortfolios(
        trade: const [],
        shell: const [
          PortfolioItem(
            portfolioId: 'c9311ca1-c8b3-419f-9382-749a39d292b1',
            portfolioName: 'Paper',
          ),
          PortfolioItem(
            portfolioId: 'broker-1',
            portfolioName: 'MCP-UC-A-Broker',
          ),
        ],
        selectedId: 'c9311ca1-c8b3-419f-9382-749a39d292b1',
        selectedName: 'Paper',
      );

      expect(visible.map((book) => book.id), [
        'c9311ca1-c8b3-419f-9382-749a39d292b1',
        'broker-1',
      ]);
      expect(visible.first.name, 'Paper');
    });
  });
}
