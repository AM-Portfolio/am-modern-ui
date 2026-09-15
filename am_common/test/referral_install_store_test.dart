import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:am_common/am_common.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('getOrCreateDeviceId is stable and long enough', () async {
    final a = await ReferralInstallStore.instance.getOrCreateDeviceId();
    final b = await ReferralInstallStore.instance.getOrCreateDeviceId();
    expect(a.length, greaterThanOrEqualTo(16));
    expect(a, b);
  });

  test('captureFromUri stores ref once without overwrite', () async {
    final first = await ReferralInstallStore.instance.captureFromUri(
      Uri.parse('https://asrax.in/download?ref=AbCdEfGh'),
    );
    expect(first, isTrue);
    expect(await ReferralInstallStore.instance.pendingReferralCode(), 'ABCDEFGH');

    final second = await ReferralInstallStore.instance.captureFromUri(
      Uri.parse('https://asrax.in/download?ref=ZZZZZZZZ'),
    );
    expect(second, isFalse);
    expect(await ReferralInstallStore.instance.pendingReferralCode(), 'ABCDEFGH');
  });

  test('signupAttribution clears only after clearPending', () async {
    await ReferralInstallStore.instance.captureFromUri(
      Uri.parse('https://asrax.in/download?ref=Invite01'),
    );
    final attr = await ReferralInstallStore.instance.signupAttribution();
    expect(attr.referralCode, 'INVITE01');
    expect(attr.deviceId.length, greaterThanOrEqualTo(16));

    await ReferralInstallStore.instance.clearPendingReferralCode();
    final after = await ReferralInstallStore.instance.signupAttribution();
    expect(after.referralCode, isNull);
  });

  test('intro seen is per user', () async {
    expect(await ReferralInstallStore.instance.isIntroSeen('u1'), isFalse);
    await ReferralInstallStore.instance.markIntroSeen('u1');
    expect(await ReferralInstallStore.instance.isIntroSeen('u1'), isTrue);
    expect(await ReferralInstallStore.instance.isIntroSeen('u2'), isFalse);
  });
}
