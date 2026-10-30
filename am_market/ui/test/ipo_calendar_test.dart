import 'package:am_market_ui/features/ipo/models/ipo_calendar_models.dart';
import 'package:am_market_ui/features/ipo/providers/ipo_calendar_providers.dart';
import 'package:am_market_ui/features/ipo/widgets/calendar/ipo_calendar_overlay.dart';
import 'package:am_market_ui/features/ipo/widgets/calendar/ipo_date_popover.dart';
import 'package:am_market_ui/features/ipo/widgets/calendar/ipo_month_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IPO Calendar Models & Parsing', () {
    test('parses IpoCalendarMonthDto correctly', () {
      final json = {
        'year': 2026,
        'month': 10,
        'dataFreshness': 'FRESH',
        'lastSuccessfulSyncAt': '2026-10-27T10:00:00Z',
        'entries': [
          {
            'id': 'ipo-1',
            'companyName': 'Alpha Tech IPO',
            'status': 'LISTED',
            'listingDate': '2026-10-05',
            'listingPrice': 150.5,
            'listingExchange': 'BSE,NSE',
          },
          {
            'id': 'ipo-2',
            'companyName': 'Beta Biotech IPO',
            'status': 'UPCOMING',
            'listingDate': '2026-10-28',
            'listingPrice': null,
            'listingExchange': null,
          },
          {
            'id': 'ipo-3',
            'companyName': 'Gamma Power IPO',
            'status': 'UPCOMING',
            'listingDate': '2026-10-28',
            'listingPrice': null,
            'listingExchange': 'NSE',
          },
        ],
      };

      final dto = IpoCalendarMonthDto.fromJson(json);
      expect(dto.year, equals(2026));
      expect(dto.month, equals(10));
      expect(dto.dataFreshness, equals(IpoCalendarDataFreshness.fresh));
      expect(dto.lastSuccessfulSyncAt, equals('2026-10-27T10:00:00Z'));
      expect(dto.entries.length, equals(3));

      // Test grouping by date
      final byDate = dto.entriesByDate;
      expect(byDate.keys.length, equals(2));
      expect(byDate['2026-10-05']?.length, equals(1));
      expect(byDate['2026-10-28']?.length, equals(2));

      // Test sorted event dates
      expect(dto.sortedEventDates, equals(['2026-10-05', '2026-10-28']));
    });

    test('handles empty entries and UNAVAILABLE freshness', () {
      final json = {
        'year': 2026,
        'month': 11,
        'dataFreshness': 'UNAVAILABLE',
        'entries': [],
      };

      final dto = IpoCalendarMonthDto.fromJson(json);
      expect(dto.year, equals(2026));
      expect(dto.month, equals(11));
      expect(dto.dataFreshness, equals(IpoCalendarDataFreshness.unavailable));
      expect(dto.entries, isEmpty);
      expect(dto.entriesByDate, isEmpty);
      expect(dto.sortedEventDates, isEmpty);
    });
  });

  group('IPO Calendar UI Notifier State', () {
    test('initial state and toggle / open / close', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(ipoCalendarUiProvider.notifier);
      expect(container.read(ipoCalendarUiProvider).isOpen, isFalse);

      notifier.open();
      expect(container.read(ipoCalendarUiProvider).isOpen, isTrue);
      expect(container.read(ipoCalendarUiProvider).activeMonthIndex, equals(0));

      notifier.toggle();
      expect(container.read(ipoCalendarUiProvider).isOpen, isFalse);

      notifier.toggle();
      expect(container.read(ipoCalendarUiProvider).isOpen, isTrue);

      notifier.close();
      expect(container.read(ipoCalendarUiProvider).isOpen, isFalse);
    });

    test('switches month index and date selection', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(ipoCalendarUiProvider.notifier);
      notifier.open();

      // Switch to next month
      notifier.setMonthIndex(1);
      expect(container.read(ipoCalendarUiProvider).activeMonthIndex, equals(1));

      // Select date
      notifier.selectDate('2026-11-04', pinned: true);
      expect(
        container.read(ipoCalendarUiProvider).activeDateKey,
        equals('2026-11-04'),
      );
      expect(container.read(ipoCalendarUiProvider).isPinned, isTrue);

      // Switch date navigation
      final dates = ['2026-11-02', '2026-11-04', '2026-11-10'];
      notifier.switchDate(-1, dates);
      expect(
        container.read(ipoCalendarUiProvider).activeDateKey,
        equals('2026-11-02'),
      );

      notifier.switchDate(1, dates);
      expect(
        container.read(ipoCalendarUiProvider).activeDateKey,
        equals('2026-11-04'),
      );
    });
  });

  group('IPO Calendar Widget Tests', () {
    testWidgets('IpoDatePopover displays at most 2 items per page with navigation',
        (tester) async {
      final events = [
        const IpoCalendarEntryDto(
          id: '1',
          companyName: 'Company One IPO',
          status: IpoCalendarDisplayStatus.listed,
          listingDate: '2026-10-05',
          listingPrice: 120.0,
          listingExchange: 'BSE,NSE',
        ),
        const IpoCalendarEntryDto(
          id: '2',
          companyName: 'Company Two IPO',
          status: IpoCalendarDisplayStatus.upcoming,
          listingDate: '2026-10-05',
          listingPrice: null,
          listingExchange: 'NSE',
        ),
        const IpoCalendarEntryDto(
          id: '3',
          companyName: 'Company Three IPO',
          status: IpoCalendarDisplayStatus.upcoming,
          listingDate: '2026-10-05',
          listingPrice: null,
          listingExchange: null,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: IpoDatePopover(
                events: events,
                sortedEventDates: const ['2026-10-05', '2026-10-12'],
                onMouseEnter: () {},
                onMouseLeave: () {},
              ),
            ),
          ),
        ),
      );

      // Verify at most 2 items visible on page 1
      expect(find.text('Company One IPO'), findsOneWidget);
      expect(find.text('Company Two IPO'), findsOneWidget);
      expect(find.text('Company Three IPO'), findsNothing);

      // Verify controls
      expect(find.text('< Previous'), findsOneWidget);
      expect(find.text('Next >'), findsOneWidget);
      expect(find.text('LISTED'), findsOneWidget);
      expect(find.text('UPCOMING'), findsOneWidget);
    });

    testWidgets('IpoMonthGrid renders calendar days and markers',
        (tester) async {
      final calendarData = IpoCalendarMonthDto(
        year: 2026,
        month: 10,
        dataFreshness: IpoCalendarDataFreshness.fresh,
        entries: const [
          IpoCalendarEntryDto(
            id: '1',
            companyName: 'Company One IPO',
            status: IpoCalendarDisplayStatus.listed,
            listingDate: '2026-10-05',
            listingPrice: 120.0,
            listingExchange: 'BSE,NSE',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: IpoMonthGrid(
                year: 2026,
                month: 10,
                calendarData: calendarData,
              ),
            ),
          ),
        ),
      );

      // Verify weekday headers
      expect(find.text('Sun'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);

      // Day 5 should exist and be clickable
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('IpoCalendarOverlay opens and switches months',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          ipoCalendarMonthProvider.overrideWith((ref, key) async {
            return IpoCalendarMonthDto(
              year: key.year,
              month: key.month,
              dataFreshness: IpoCalendarDataFreshness.fresh,
              entries: const [],
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      // Open the calendar overlay
      container.read(ipoCalendarUiProvider.notifier).open();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  IpoCalendarOverlay(),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Close button exists
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Arrow button to forward to next month
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

      // Tap forward arrow
      await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
      await tester.pumpAndSettle();

      // Now on next month, back arrow should be visible
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });
  });
}
