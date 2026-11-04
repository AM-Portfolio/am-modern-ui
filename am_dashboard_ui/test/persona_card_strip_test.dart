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

    await tester.pumpWidget(
      MaterialApp(
        theme: _theme(),
        home: Scaffold(
          body: PersonaCardStrip(
            members: const [
              FamilyMemberRow(
                id: 'fm1',
                name: 'Priyanshu Kumar',
                portfolioCount: 2,
              ),
            ],
            selectedId: selected,
            primaryLabel: 'Munish',
            favoriteKey: favorited,
            onSelected: (id) => selected = id,
            onFavorite: (key) => favorited = key,
            onDelete: (m) => deleted = m,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Munish'), findsOneWidget);
    expect(find.text('Priyanshu Kumar'), findsOneWidget);
    expect(find.text('Household'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pump();
    expect(selected, FavoritePersonaStore.kAll);

    await tester.tap(find.text('Priyanshu Kumar'));
    await tester.pump();
    expect(selected, 'fm1');

    await tester.tap(find.byIcon(Icons.star_outline_rounded).first);
    await tester.pump();
    expect(favorited, isNotNull);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pump();
    expect(deleted?.id, 'fm1');
  });
}
