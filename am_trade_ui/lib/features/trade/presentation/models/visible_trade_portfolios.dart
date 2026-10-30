import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_list.dart';

import 'trade_portfolio_view_model.dart';

/// Trade summary rows keep their metrics. Portfolio-shell books (paper,
/// broker, email) fill anything the trade API has not returned yet, and the
/// portfolio open in the URL stays visible while those calls are in flight.
List<TradePortfolioViewModel> mergeVisibleTradePortfolios({
  required List<TradePortfolioViewModel> trade,
  List<PortfolioItem> shell = const [],
  String? selectedId,
  String? selectedName,
}) {
  final seen = <String>{};
  final out = <TradePortfolioViewModel>[];

  void add(TradePortfolioViewModel book) {
    if (book.id.isEmpty || book.id == 'all' || !seen.add(book.id)) return;
    out.add(book);
  }

  for (final book in trade) {
    add(book);
  }
  for (final book in shell) {
    add(
      TradePortfolioViewModel(
        id: book.portfolioId,
        name: book.portfolioName,
      ),
    );
  }
  if (selectedId != null &&
      selectedId.isNotEmpty &&
      !seen.contains(selectedId)) {
    add(
      TradePortfolioViewModel(
        id: selectedId,
        name: (selectedName == null || selectedName.isEmpty)
            ? 'Portfolio'
            : selectedName,
      ),
    );
  }
  return out;
}
