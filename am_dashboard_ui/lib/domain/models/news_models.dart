class NewsCard {
  const NewsCard({
    required this.heading,
    required this.articleLink,
    this.summary = '',
    this.thumbnail,
    this.publishedAt,
    this.symbols = const [],
  });

  factory NewsCard.fromJson(Map<String, dynamic> json) {
    return NewsCard(
      heading: json['heading'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      thumbnail: json['thumbnail'] as String?,
      articleLink: json['article_link'] as String? ?? '',
      publishedAt: json['published_at'] as String?,
      symbols: (json['symbols'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  final String heading;
  final String summary;
  final String? thumbnail;
  final String articleLink;
  final String? publishedAt;
  final List<String> symbols;

  DateTime? get publishedAtDate => parseNewsPublishedAt(publishedAt);
}

class InsightNews {
  const InsightNews({
    this.currentAffairs = const [],
    this.holdings = const [],
  });

  factory InsightNews.fromJson(Map<String, dynamic> json) {
    List<NewsCard> parse(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      return sortNewsNewestFirst(
        raw
            .whereType<Map>()
            .map((e) => NewsCard.fromJson(Map<String, dynamic>.from(e))),
      );
    }

    return InsightNews(
      currentAffairs: parse('current_affairs'),
      holdings: parse('holdings'),
    );
  }

  final List<NewsCard> currentAffairs;
  final List<NewsCard> holdings;
}

DateTime? parseNewsPublishedAt(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

int compareNewsByPublishedAtDesc(NewsCard a, NewsCard b) {
  final aTime = parseNewsPublishedAt(a.publishedAt);
  final bTime = parseNewsPublishedAt(b.publishedAt);
  if (aTime == null && bTime == null) return 0;
  if (aTime == null) return 1;
  if (bTime == null) return -1;
  return bTime.compareTo(aTime);
}

List<NewsCard> sortNewsNewestFirst(Iterable<NewsCard> cards) {
  final list = List<NewsCard>.from(cards);
  list.sort(compareNewsByPublishedAtDesc);
  return list;
}

const newsIndexSymbols = {
  'NIFTY50',
  'NIFTY',
  'SENSEX',
  'BANKNIFTY',
  'FINNIFTY',
  'MIDCPNIFTY',
};

bool isNewsIndexSymbol(String symbol) {
  final key = symbol.trim().toUpperCase().replaceAll(' ', '');
  return newsIndexSymbols.contains(key);
}

List<String> uniqueNewsSymbols(InsightNews news, {int cap = 40}) {
  final seen = <String>{};
  final out = <String>[];
  for (final card in [...news.currentAffairs, ...news.holdings]) {
    for (final raw in card.symbols) {
      final symbol = raw.trim().toUpperCase();
      if (symbol.isEmpty || !seen.add(symbol)) continue;
      out.add(symbol);
      if (out.length >= cap) return out;
    }
  }
  return out;
}
