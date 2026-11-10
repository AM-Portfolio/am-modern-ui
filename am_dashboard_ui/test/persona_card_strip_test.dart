import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/persona_card_strip.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ThemeData _theme() {
  return ThemeData.dark().copyWith(
    extensions: const <ThemeExtension<dynamic>>[AppColorsTheme.dark],
  );
}

Future<void> _pumpStrip(
  WidgetTester tester, {
  required double width,
  required Widget child,
}) async {
  tester.view.physicalSize = Size(width + 200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: Size(width + 200, 800)),
      child: MaterialApp(
        theme: _theme(),
        home: Scaffold(
          body: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('persona cards select favorite and delete', (tester) async {
    String? selected;
    String? favorited;
    FamilyMemberRow? deleted;

    await _pumpStrip(
      tester,
      width: 900,
      child: PersonaCardStrip(
        members: const [
          FamilyMemberRow(
            id: 'fm1',
            name: 'Priyanshu Kumar',
            portfolioCount: 2,
            totalValue: 600000,
            xirrPct: 12.5,
          ),
        ],
        selectedId: selected,
        primaryLabel: 'Munish',
        favoriteKey: favorited,
        householdTotalValue: 1000000,
        householdXirrPct: 10.2,
        householdAccountCount: 5,
        primaryTotalValue: 400000,
        primaryXirrPct: 0,
        primaryAccountCount: 3,
        memberAccountCounts: const {'fm1': 2},
        onSelected: (id) => selected = id,
        onFavorite: (key) => favorited = key,
        onDelete: (m) => deleted = m,
      ),
    );

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Munish'), findsOneWidget);
    expect(find.text('Priyanshu Kumar'), findsOneWidget);
    expect(find.text('5 accounts'), findsOneWidget);
    expect(find.text('3 accounts'), findsOneWidget);
    expect(find.text('2 accounts'), findsOneWidget);
    expect(find.textContaining('₹1,000,000'), findsOneWidget);
    expect(find.textContaining('₹400,000'), findsOneWidget);
    expect(find.textContaining('₹600,000'), findsOneWidget);
    expect(find.textContaining('+10.2%'), findsOneWidget);
    expect(find.textContaining('0.0%'), findsWidgets);
    expect(find.textContaining('+12.5%'), findsOneWidget);
    expect(find.byIcon(Icons.north_east_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.south_east_rounded), findsOneWidget);
    expect(find.byIcon(Icons.layers_rounded), findsOneWidget);
    expect(find.byIcon(Icons.groups_rounded), findsOneWidget);
    expect(find.byIcon(Icons.work_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pump();
    expect(selected, FavoritePersonaStore.kAll);

    await tester.ensureVisible(find.text('Priyanshu Kumar'));
    await tester.tap(find.text('Priyanshu Kumar'));
    await tester.pump();
    expect(selected, 'fm1');

    await tester.tap(find.byIcon(Icons.star_outline_rounded).first);
    await tester.pump();
    expect(favorited, isNotNull);

    await tester.ensureVisible(find.byIcon(Icons.delete_outline_rounded));
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pump();
    expect(deleted?.id, 'fm1');
  });

  testWidgets('delete only on family members with onDelete', (tester) async {
    await _pumpStrip(
      tester,
      width: 900,
      child: PersonaCardStrip(
        members: const [
          FamilyMemberRow(id: 'fm1', name: 'Priyanshu', totalValue: 1),
        ],
        selectedId: null,
        primaryLabel: 'You',
        favoriteKey: null,
        onSelected: (_) {},
        onFavorite: (_) {},
        onDelete: (_) {},
      ),
    );

    // All + You have no delete; only the one family member does.
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.layers_rounded), findsOneWidget);
    expect(find.byIcon(Icons.groups_rounded), findsOneWidget);
    expect(find.byIcon(Icons.work_outline_rounded), findsOneWidget);
  });

  testWidgets('no overflow at wide and compact strip widths', (tester) async {
    for (final width in <double>[900, 360]) {
      await _pumpStrip(
        tester,
        width: width,
        child: PersonaCardStrip(
          members: const [
            FamilyMemberRow(
              id: 'fm1',
              name: 'Priyanshu Kumar',
              totalValue: 1234567,
              xirrPct: 12.5,
            ),
          ],
          selectedId: 'fm1',
          primaryLabel: 'Munish',
          favoriteKey: 'fm1',
          compact: width <= 360,
          householdTotalValue: 9876543,
          householdXirrPct: 10.2,
          householdAccountCount: 5,
          primaryTotalValue: 400000,
          primaryXirrPct: -1.5,
          primaryAccountCount: 3,
          memberAccountCounts: const {'fm1': 2},
          onSelected: (_) {},
          onFavorite: (_) {},
          onDelete: (_) {},
        ),
      );
      expect(tester.takeException(), isNull, reason: 'width=$width');
    }
  });

  testWidgets('shows Add family filler when fewer than 3 personas',
      (tester) async {
    var added = false;

    await _pumpStrip(
      tester,
      width: 900,
      child: PersonaCardStrip(
        members: const [],
        selectedId: null,
        primaryLabel: 'You',
        favoriteKey: null,
        onSelected: (_) {},
        onFavorite: (_) {},
        onAddFamily: () => added = true,
      ),
    );

    expect(find.text('All'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    await tester.ensureVisible(find.text('Add family'));
    await tester.pumpAndSettle();
    expect(find.text('Add family'), findsOneWidget);
    await tester.tap(find.text('Add family'));
    await tester.pump();
    expect(added, isTrue);
  });

  testWidgets('shows 2.5 cards and swipes to later personas', (tester) async {
    await _pumpStrip(
      tester,
      width: 900,
      child: PersonaCardStrip(
        members: const [
          FamilyMemberRow(id: 'a', name: 'Alpha', totalValue: 1),
          FamilyMemberRow(id: 'b', name: 'Beta', totalValue: 2),
          FamilyMemberRow(id: 'c', name: 'Gamma', totalValue: 3),
        ],
        selectedId: null,
        primaryLabel: 'You',
        favoriteKey: null,
        onSelected: (_) {},
        onFavorite: (_) {},
      ),
    );

    expect(find.byKey(const Key('persona-card-strip-scroll')), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    // Third full card peeks; later members stay off-screen until swipe.
    expect(find.text('Gamma'), findsNothing);

    await tester.drag(
      find.byKey(const Key('persona-card-strip-scroll')),
      const Offset(-700, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Gamma'), findsOneWidget);
  });

  testWidgets('peek layout keeps third card partially in viewport',
      (tester) async {
    await _pumpStrip(
      tester,
      width: 500,
      child: PersonaCardStrip(
        members: const [
          FamilyMemberRow(id: 'fm1', name: 'Priyanshu', totalValue: 1),
        ],
        selectedId: null,
        primaryLabel: 'You',
        favoriteKey: null,
        onSelected: (_) {},
        onFavorite: (_) {},
        onDelete: (_) {},
      ),
    );

    final scrollable = find.byKey(const Key('persona-card-strip-scroll'));
    expect(scrollable, findsOneWidget);
    expect(
      tester.widget<ListView>(scrollable).scrollDirection,
      Axis.horizontal,
    );

    final allRect = tester.getRect(find.text('All'));
    final youRect = tester.getRect(find.text('You'));
    expect(youRect.left, greaterThan(allRect.left));
    expect(find.text('Priyanshu'), findsOneWidget);
  });
}
