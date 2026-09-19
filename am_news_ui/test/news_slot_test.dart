import 'package:am_common/am_common.dart';
import 'package:am_news_ui/am_news_ui.dart';
import 'package:am_news_ui/presentation/widgets/news_article_opener.dart';
import 'package:am_news_ui/presentation/widgets/news_relative_time.dart';
import 'package:am_news_ui/presentation/widgets/news_symbol_chip.dart';
import 'package:am_news_ui/presentation/widgets/news_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

InsightNews _sampleNews() {
  return InsightNews.fromJson({
    'current_affairs': [
      {
        'heading': 'Older TCS headline',
        'summary': 'Older summary',
        'article_link': 'https://example.com/old',
        'published_at': '2026-09-05T08:00:00.000Z',
        'symbols': ['TCS'],
      },
      {
        'heading':
            'JSW Steel reports 3% jump in crude steel production to 24.65 lakh tonnes in Aug; key details to know',
        'summary':
            'JSW Steel’s crude steel production in its Indian operations rose 4% YoY.',
        'thumbnail': 'https://example.com/jsw.webp',
        'article_link':
            'https://upstox.com/news/market-news/stocks/jsw-steel/article-199857/',
        'published_at': '2026-09-06T10:03:52.107000Z',
        'symbols': ['JSWSTEEL'],
      },
    ],
    'holdings': [
      {
        'heading': 'Rel',
        'article_link': 'https://example.com/rel',
        'symbols': ['RELIANCE'],
      },
    ],
  });
}

_newsOverrides({
  InsightNews news = const InsightNews(),
  Map<String, QuoteChange> quotes = const {},
  bool enabled = true,
}) {
  return [
    newsUiEnabledProvider.overrideWith((ref) => enabled),
    newsUiSurfaceEnabledProvider(NewsUiSurface.dashboard)
        .overrideWith((ref) => enabled),
    newsInsightProvider.overrideWith((ref) async => news),
    priceStreamProvider.overrideWith(
      (ref) => Stream<Map<String, QuoteChange>>.value(quotes),
    ),
  ];
}

void main() {
  test('NewsRepository does not expose admin in insight path', () {
    expect(NewsRepository.insightPath, '/v1/insight');
    expect(NewsRepository.insightPath.contains('admin'), isFalse);
  });

  test('InsightNews sorts current affairs newest first', () {
    final news = _sampleNews();
    expect(news.currentAffairs.first.heading.contains('JSW Steel'), isTrue);
    expect(news.currentAffairs.last.heading.contains('Older TCS'), isTrue);
  });

  test('newsSymbolsProviderKey normalizes', () {
    expect(newsSymbolsProviderKey(['tcs', 'TCS', ' RELIANCE ']), 'RELIANCE,TCS');
    expect(newsSymbolsProviderKey([]), isEmpty);
  });

  test('filterHoldingsNewsForSymbols ignores current affairs', () {
    final news = _sampleNews();
    final cards = filterHoldingsNewsForSymbols(news, ['RELIANCE']);
    expect(cards, hasLength(1));
    expect(cards.first.heading, 'Rel');

    final unrelated = filterHoldingsNewsForSymbols(news, ['DELTACORP']);
    expect(unrelated, isEmpty);

    // BEL-style affairs must not appear for an unrelated book.
    final belOnly = InsightNews.fromJson({
      'current_affairs': [
        {
          'heading': 'Bharat Electronics orders',
          'article_link': 'https://example.com/bel',
          'symbols': ['BEL'],
        },
      ],
      'holdings': <Map<String, dynamic>>[],
    });
    expect(filterHoldingsNewsForSymbols(belOnly, ['IRCTC', 'PNB']), isEmpty);
  });

  testWidgets('holdings section does not show current-affairs fallback',
      (tester) async {
    final belOnly = InsightNews.fromJson({
      'current_affairs': [
        {
          'heading': 'Bharat Electronics orders',
          'article_link': 'https://example.com/bel',
          'symbols': ['BEL'],
        },
      ],
      'holdings': <Map<String, dynamic>>[],
    });
    final key = newsSymbolsProviderKey(['IRCTC']);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          newsUiEnabledProvider.overrideWith((ref) => true),
          newsUiSurfaceEnabledProvider(NewsUiSurface.tradeHoldings)
              .overrideWith((ref) => true),
          newsInsightForSymbolsProvider(key).overrideWith((ref) async => belOnly),
          priceStreamProvider.overrideWith(
            (ref) => Stream<Map<String, QuoteChange>>.value(const {}),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HoldingsNewsSection(
                symbols: ['IRCTC'],
                surface: NewsUiSurface.tradeHoldings,
                embedInScroll: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Bharat Electronics'), findsNothing);
    expect(find.textContaining('No recent news for these symbols'), findsOneWidget);
  });

  testWidgets('flag off hides dashboard news section', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _newsOverrides(enabled: false),
        child: const MaterialApp(home: Scaffold(body: DashboardNewsSection())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Current affairs'), findsNothing);
    expect(find.textContaining('Your holdings'), findsNothing);
  });

  testWidgets('symbol section hidden when symbol empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          newsUiEnabledProvider.overrideWith((ref) => true),
          newsUiSurfaceEnabledProvider(NewsUiSurface.equityInsider)
              .overrideWith((ref) => true),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SymbolNewsSection(
              symbol: '',
              surface: NewsUiSurface.equityInsider,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('News'), findsNothing);
  });

  testWidgets('web news shows featured heading', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _newsOverrides(news: _sampleNews()),
        child: const MaterialApp(
          home: Scaffold(body: DashboardNewsSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('JSW Steel'), findsWidgets);
  });

  test('relative time helper', () {
    expect(
      formatNewsRelativeTime('2026-09-06T10:03:52.107000Z'),
      isNotEmpty,
    );
  });

  test('openNewsArticle tolerates empty', () {
    expect(() => openNewsArticle(''), returnsNormally);
  });

  testWidgets('NewsThumbnail builds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NewsThumbnail(url: null, width: 40, height: 40),
        ),
      ),
    );
    expect(find.byType(NewsThumbnail), findsOneWidget);
  });

  testWidgets('NewsSymbolChip builds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NewsSymbolChip(symbol: 'TCS'),
        ),
      ),
    );
    expect(find.text('TCS'), findsOneWidget);
  });
}
