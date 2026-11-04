import 'dtos/trade_portfolio_dto.dart';

/// Trade `GET /v1/portfolio-summary/by-owner` hides PAPER books unless asked.
String withIncludePaper(String uri) {
  final parsed = Uri.parse(uri);
  return parsed
      .replace(
        queryParameters: {
          ...parsed.queryParameters,
          'includePaper': 'true',
        },
      )
      .toString();
}

/// Books from portfolio `GET /v1/portfolios/list` (broker, email, paper).
/// `DELETED` rows and the aggregate `all` id are not trade books.
List<TradePortfolioDto> parsePortfolioServiceBooks(dynamic data) {
  final List<dynamic> items;
  if (data is List) {
    items = data;
  } else if (data is Map && data['portfolios'] is List) {
    items = data['portfolios'] as List;
  } else {
    return const [];
  }

  final books = <TradePortfolioDto>[];
  for (final raw in items) {
    if (raw is! Map) continue;
    final map = Map<String, dynamic>.from(raw);
    final kind = (map['kind'] as String?)?.toUpperCase();
    if (kind == 'DELETED') continue;
    final id = (map['portfolioId'] ?? map['id'])?.toString() ?? '';
    if (id.isEmpty || id == 'all') continue;
    final name = (map['portfolioName'] ?? map['name'])?.toString() ?? id;
    books.add(
      TradePortfolioDto(
        portfolioId: id,
        name: name,
        ownerId: map['ownerId']?.toString(),
        description: map['description']?.toString(),
      ),
    );
  }
  return books;
}

/// Trade summary rows keep their metrics. Portfolio-only books are appended.
TradePortfolioListDto mergePortfolioBooks(
  TradePortfolioListDto trade,
  List<TradePortfolioDto> books,
) {
  final seen = trade.portfolios.map((book) => book.portfolioId).toSet();
  final added = [
    for (final book in books)
      if (seen.add(book.portfolioId)) book,
  ];
  if (added.isEmpty) return trade;
  final portfolios = [...trade.portfolios, ...added];
  return TradePortfolioListDto(
    portfolios: portfolios,
    totalCount: portfolios.length,
  );
}
