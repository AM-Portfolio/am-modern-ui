import 'package:am_common/am_common.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists preset avatar per user', () async {
    final store = UserAvatarStore.instance;
    await store.loadForUser('user-a');
    await store.setPreference(UserAvatarPreference.preset('rocket'));
    expect(store.preference.kind, UserAvatarKind.preset);
    expect(store.preference.presetId, 'rocket');

    await store.loadForUser('user-b');
    expect(store.preference.kind, UserAvatarKind.initials);

    await store.loadForUser('user-a');
    expect(store.preference.presetId, 'rocket');
  });

  test('rejects oversized photo payload', () async {
    final store = UserAvatarStore.instance;
    await store.loadForUser('user-a');
    final huge = 'a' * (UserAvatarStore.maxPhotoBase64Chars + 10);
    expect(
      () => store.setPreference(UserAvatarPreference.photo(base64: huge)),
      throwsStateError,
    );
  });
}
