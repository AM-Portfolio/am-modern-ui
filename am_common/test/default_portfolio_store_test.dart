import 'package:am_common/core/session/default_portfolio_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save load clear default portfolio', () async {
    const userId = 'user-1';
    expect(await DefaultPortfolioStore.instance.load(userId), isNull);

    await DefaultPortfolioStore.instance
        .save(userId, id: 'pf-42', name: 'Groww');
    final loaded = await DefaultPortfolioStore.instance.load(userId);
    expect(loaded?.id, 'pf-42');
    expect(loaded?.name, 'Groww');

    await DefaultPortfolioStore.instance.clear(userId);
    expect(await DefaultPortfolioStore.instance.load(userId), isNull);
  });
}
