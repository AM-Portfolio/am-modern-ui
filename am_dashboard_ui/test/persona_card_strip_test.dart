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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('persona cards select favorite and delete', (tester) async {
    String? selected;
    String? favorited;
    FamilyMemberRow? deleted;

    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1400, 800)),
        child: MaterialApp(
          theme: _theme(),
          home: Scaffold(
            body: PersonaCardStrip(
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
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Munish'), findsOneWidget);
    expect(find.text('Priyanshu Kumar'), findsOneWidget);
    expect(find.text('5 accounts'), findsOneWidget);
    expect(find.text('3 accounts'), findsOneWidget);
    expect(find.text('2 accounts'), findsOneWidget);
    expect(find.textContaining('₹1,000,000'), findsOneWidget);
    expect(find.textContaining('₹400,000'), findsOneWidget);
    expect(find.textContaining('₹600,000'), findsOneWidget);
    expect(find.textContaining('XIRR +10.2%'), findsOneWidget);
    expect(find.textContaining('XIRR 0.0%'), findsOneWidget);
    expect(find.textContaining('XIRR +12.5%'), findsOneWidget);
    expect(find.byIcon(Icons.north_east_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.south_east_rounded), findsOneWidget);

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
}
