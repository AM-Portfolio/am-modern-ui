import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/data/repositories/news_repository.dart';
import 'package:am_dashboard_ui/domain/models/news_models.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_model.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_widget_id.dart';
import 'package:am_dashboard_ui/presentation/providers/news_provider.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/dashboard_news_section.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/news_article_opener.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/news_feed_tab.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/news_mobile_section.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/news_story_tiles.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/news_web_section.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/news_symbol_chip.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/news_thumbnail.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/news_relative_time.dart';
import 'package:am_design_system/am_design_system.dart';
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
    newsInsightProvider.overrideWith((ref) async => news),
    priceStreamProvider.overrideWith(
      (ref) => Stream<Map<String, QuoteChange>>.value(quotes),
    ),
  ];
}

void main() {
  test('mergeWithDefaultLayout inserts news', () {
    final saved = DashboardLayoutModel(
      slots: [
        const DashboardWidgetSlot(
          id: DashboardWidgetId.summary,
          visible: true,
          order: 0,
        ),
      ],
    );
    final merged = mergeWithDefaultLayout(saved);
    expect(merged.slots.any((s) => s.id == DashboardWidgetId.news), isTrue);
  });

  test('compactDashboardSlots emits portfolios then activity then news', () {
    final merged = mergeWithDefaultLayout(const DashboardLayoutModel(slots: []));
    final compact = compactDashboardSlots(
      merged.visibleSlots,
      newsEnabled: true,
    );
    final ids = compact.map((s) => s.id).toList();
    final newsAt = ids.indexOf(DashboardWidgetId.news);
    final activityAt = ids.indexOf(DashboardWidgetId.recentActivity);
    final portfoliosAt = ids.indexOf(DashboardWidgetId.portfolioList);
    expect(portfoliosAt, lessThan(activityAt));
    expect(activityAt, lessThan(newsAt));
    expect(portfoliosAt + 1, activityAt);
    expect(activityAt + 1, newsAt);
  });

  test('compactDashboardSlots skips news when flag is off', () {
    final merged = mergeWithDefaultLayout(const DashboardLayoutModel(slots: []));
    final compact = compactDashboardSlots(
      merged.visibleSlots,
      newsEnabled: false,
    );
    expect(compact.any((s) => s.id == DashboardWidgetId.news), isFalse);
    final ids = compact.map((s) => s.id).toList();
    expect(
      ids.indexOf(DashboardWidgetId.portfolioList),
      lessThan(ids.indexOf(DashboardWidgetId.recentActivity)),
    );
  });

  test('mergeWithDefaultLayout places news before recentActivity', () {
    final saved = DashboardLayoutModel(
      slots: [
        const DashboardWidgetSlot(
          id: DashboardWidgetId.news,
          visible: true,
          order: 6,
          size: DashboardWidgetSize.full,
        ),
        const DashboardWidgetSlot(
          id: DashboardWidgetId.recentActivity,
          visible: true,
          order: 3,
          size: DashboardWidgetSize.half,
        ),
        const DashboardWidgetSlot(
          id: DashboardWidgetId.portfolioList,
          visible: true,
          order: 4,
          size: DashboardWidgetSize.half,
        ),
      ],
    );
    final merged = mergeWithDefaultLayout(saved);
    final news = merged.slots.firstWhere((s) => s.id == DashboardWidgetId.news);
    final activity = merged.slots.firstWhere(
      (s) => s.id == DashboardWidgetId.recentActivity,
    );
    final portfolios = merged.slots.firstWhere(
      (s) => s.id == DashboardWidgetId.portfolioList,
    );
    expect(news.order, 3);
    expect(news.size, DashboardWidgetSize.twoThirds);
    expect(activity.order, 4);
    expect(activity.size, DashboardWidgetSize.oneThird);
    expect(portfolios.order, 5);
    expect(news.order < activity.order, isTrue);
  });

  test('NewsRepository does not expose admin URLs', () {
    expect(NewsRepository.insightPath, '/v1/insight');
    expect(NewsRepository.insightPath.contains('admin'), isFalse);
    expect(NewsRepository.adminFeedPath, '/v1/admin/feed/start');
  });

  test('InsightNews holdings chips stay inside request symbols', () {
    final news = InsightNews.fromJson({
      'current_affairs': [
        {
          'heading': 'Nifty',
          'article_link': 'https://x/1',
          'symbols': ['RELIANCE'],
        }
      ],
      'holdings': [
        {
          'heading': 'Rel',
          'article_link': 'https://x/2',
          'symbols': ['RELIANCE'],
        }
      ],
    });
    const requested = {'RELIANCE', 'TCS'};
    for (final card in news.holdings) {
      expect(requested.containsAll(card.symbols), isTrue);
    }
  });

  test('fromJson sorts newest published_at first', () {
    final news = _sampleNews();
    expect(news.currentAffairs.first.heading.contains('JSW Steel'), isTrue);
    expect(news.currentAffairs.last.heading.contains('Older TCS'), isTrue);
  });

  test('openNewsArticle skips invalid links', () async {
    expect(await openNewsArticle(''), isFalse);
    expect(await openNewsArticle('not-a-url'), isFalse);
    var launched = false;
    final opened = await openNewsArticle(
      'https://upstox.com/news/article-199857/',
      launcher: (uri) async {
        launched = uri.host == 'upstox.com';
        return true;
      },
    );
    expect(opened, isTrue);
    expect(launched, isTrue);
  });

  test('relative time uses JUST NOW under two minutes', () {
    final now = DateTime.utc(2026, 9, 6, 10, 4);
    expect(
      formatNewsRelativeTime('2026-09-06T10:03:52.107000Z', now: now),
      'JUST NOW',
    );
    expect(
      formatNewsRelativeTime('2026-09-06T09:30:00.000Z', now: now),
      '34m ago',
    );
  });

  testWidgets('flag off hides news section and copy', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _newsOverrides(enabled: false),
        child: const MaterialApp(home: Scaffold(body: DashboardNewsSection())),
      ),
    );
    await tester.pump();
    expect(find.text('Market Intelligence'), findsNothing);
    expect(find.text('Current affairs'), findsNothing);
  });

  testWidgets('flag on shows current affairs and holdings labels', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _newsOverrides(),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: DashboardNewsSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Market Intelligence'), findsOneWidget);
    expect(find.text('Current affairs'), findsOneWidget);
    expect(find.text('Your holdings'), findsOneWidget);
  });

  testWidgets('web news shows featured heading and summary', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _newsOverrides(news: _sampleNews()),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: DashboardNewsSection()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      find.textContaining('JSW Steel reports 3% jump'),
      findsOneWidget,
    );
    expect(find.textContaining('crude steel production'), findsWidgets);
    expect(find.text('Read story'), findsOneWidget);
  });

  testWidgets('symbol chips show live quote when stream has data', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _newsOverrides(
          news: _sampleNews(),
          quotes: {
            'JSWSTEEL': QuoteChange(lastPrice: 1234.5, changePercent: 3.12),
          },
        ),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: DashboardNewsSection()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('JSWSTEEL'), findsWidgets);
    expect(find.textContaining('3.12%'), findsOneWidget);
    expect(find.textContaining('1,234.50'), findsOneWidget);
  });

  testWidgets('mobile section renders the same InsightNews fixture', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: NewsMobileSection(
            data: _sampleNews(),
            quotes: const {},
            tab: NewsFeedTab.currentAffairs,
            onTabChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('JSW Steel reports 3% jump'), findsOneWidget);
    expect(find.text('Read story'), findsOneWidget);
    expect(find.text('Current affairs'), findsOneWidget);
  });

  testWidgets('web news stacks stories in the page scroll not a nested list', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: NewsWebSection(
              data: _sampleNews(),
              quotes: const {},
              tab: NewsFeedTab.currentAffairs,
              onTabChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(ListView), findsNothing);
    expect(find.byType(NewsFeaturedStory), findsOneWidget);
    expect(find.byType(NewsCompactRow), findsOneWidget);
    expect(find.textContaining('Older TCS headline'), findsOneWidget);
  });

  testWidgets('featured web story lays out thumbnail beside copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SizedBox(
            width: 720,
            child: NewsFeaturedStory(
              card: _sampleNews().currentAffairs.first,
              quotes: const {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final inkWell = tester.widget<InkWell>(find.byType(InkWell).first);
    expect(inkWell.child, isA<LayoutBuilder>());
    expect(find.byType(NewsThumbnail), findsOneWidget);
    expect(find.text('Read story'), findsOneWidget);
  });

  testWidgets('symbol chips use dashboard module fill and border', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: NewsSymbolChip(
            symbol: 'TCS',
            quote: QuoteChange(lastPrice: 10, changePercent: -1.5),
          ),
        ),
      ),
    );
    await tester.pump();
    final chip = tester.widget<Container>(find.byType(Container).first);
    final decoration = chip.decoration! as BoxDecoration;
    expect(decoration.color, ModuleColors.dashboard.withValues(alpha: 0.14));
    final border = decoration.border! as Border;
    expect(border.top.color, ModuleColors.dashboard.withValues(alpha: 0.5));
    expect(find.textContaining('-1.50%'), findsOneWidget);
  });
}
