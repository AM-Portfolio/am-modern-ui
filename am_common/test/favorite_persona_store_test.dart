import 'package:am_common/core/session/favorite_persona_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save load clear favorite persona', () async {
    const userId = 'user-1';
    expect(await FavoritePersonaStore.instance.load(userId), isNull);

    await FavoritePersonaStore.instance
        .save(userId, FavoritePersonaStore.kAll);
    expect(
      await FavoritePersonaStore.instance.load(userId),
      FavoritePersonaStore.kAll,
    );

    await FavoritePersonaStore.instance.save(userId, 'fm-priyanshu');
    expect(await FavoritePersonaStore.instance.load(userId), 'fm-priyanshu');

    await FavoritePersonaStore.instance.clear(userId);
    expect(await FavoritePersonaStore.instance.load(userId), isNull);
  });

  test('keyFromSelection and selectionFromKey round-trip', () {
    expect(FavoritePersonaStore.keyFromSelection(null), FavoritePersonaStore.kYou);
    expect(
      FavoritePersonaStore.keyFromSelection(FavoritePersonaStore.kAll),
      FavoritePersonaStore.kAll,
    );
    expect(FavoritePersonaStore.keyFromSelection('fm1'), 'fm1');

    expect(FavoritePersonaStore.selectionFromKey(null), isNull);
    expect(FavoritePersonaStore.selectionFromKey(FavoritePersonaStore.kYou), isNull);
    expect(
      FavoritePersonaStore.selectionFromKey(FavoritePersonaStore.kAll),
      FavoritePersonaStore.kAll,
    );
    expect(FavoritePersonaStore.selectionFromKey('fm1'), 'fm1');
  });
}
