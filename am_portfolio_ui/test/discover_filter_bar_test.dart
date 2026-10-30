import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/basket_catalog.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/basket_opportunity.dart';
import 'package:am_portfolio_ui/features/basket/presentation/utils/discover_view_state.dart';
import 'package:am_portfolio_ui/features/basket/presentation/widgets/discover/discover_filter_bar.dart';
import 'package:am_portfolio_ui/features/basket/presentation/widgets/discover/discover_section_headers.dart';

void main() {
  testWidgets('mobile filter bar uses global dropdowns instead of popup menus',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var period = DiscoverPerformancePeriod.oneY;
    var sort = DiscoverSortMode.matchDesc;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiscoverFilterBar(
            themes: const [
              BasketTheme(id: 'it', label: 'IT', query: 'IT'),
              BasketTheme(id: 'bank', label: 'Banks', query: 'BANK'),
              BasketTheme(id: 'pharma', label: 'Pharma', query: 'PHARMA'),
              BasketTheme(id: 'auto', label: 'Auto', query: 'AUTO'),
              BasketTheme(id: 'fmcg', label: 'FMCG', query: 'FMCG'),
            ],
            defaultQuery: 'NIFTYBEES',
            selectedThemeId: null,
            discoverState: DiscoverViewState(period: period, sort: sort),
            onThemeSelect: ({query, themeId}) {},
            onPeriodChanged: (p) => period = p,
            onSortChanged: (s) => sort = s,
            onClearAll: () {},
          ),
        ),
      ),
    );

    expect(find.byType(PopupMenuButton<DiscoverPerformancePeriod>), findsNothing);
    expect(find.byType(PopupMenuButton<DiscoverSortMode>), findsNothing);
    expect(find.byType(PopupMenuButton<BasketTheme>), findsNothing);
    expect(
      find.byType(CustomDropdown<DiscoverPerformancePeriod>),
      findsOneWidget,
    );
    expect(find.byType(CustomDropdown<DiscoverSortMode>), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    final periodBox = tester.getRect(
      find.byType(CustomDropdown<DiscoverPerformancePeriod>),
    );
    expect(periodBox.width, lessThanOrEqualTo(56));

    await tester.tap(find.text('1Y'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5Y').last);
    await tester.pumpAndSettle();
    expect(period, DiscoverPerformancePeriod.fiveY);
  });

  testWidgets('Recommended stays one line at 390', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(
          extensions: const <ThemeExtension<dynamic>>[AppColorsTheme.dark],
        ),
        home: Scaffold(
          body: DiscoverFilterBar(
            themes: const [
              BasketTheme(id: 'it', label: 'IT', query: 'IT'),
              BasketTheme(id: 'bank', label: 'Banks', query: 'BANK'),
            ],
            defaultQuery: 'NIFTYBEES',
            selectedThemeId: null,
            discoverState: const DiscoverViewState(),
            onThemeSelect: ({query, themeId}) {},
            onPeriodChanged: (_) {},
            onSortChanged: (_) {},
            onClearAll: () {},
          ),
        ),
      ),
    );

    final rect = tester.getRect(find.text('Recommended'));
    expect(rect.height, lessThan(24));
  });

  testWidgets('count and View all do not overlap at 390', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(
          extensions: const <ThemeExtension<dynamic>>[AppColorsTheme.dark],
        ),
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: DiscoverBasketsMetaRow(
              count: 9,
              onViewAll: () {},
            ),
          ),
        ),
      ),
    );

    final count = tester.getRect(find.byKey(const Key('discover-baskets-count')));
    final viewAll = tester.getRect(find.byKey(const Key('discover-view-all')));
    expect(count.overlaps(viewAll), isFalse);
    expect(count.top, lessThan(viewAll.bottom));
    expect(
      tester.renderObject<RenderParagraph>(find.text('9 baskets'))
          .didExceedMaxLines,
      isFalse,
    );
  });
}
