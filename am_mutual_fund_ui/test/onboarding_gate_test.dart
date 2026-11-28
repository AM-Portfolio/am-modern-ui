import 'package:am_mutual_fund_ui/providers/mf_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UCC failure keeps fatca/bank gated via draft flags', () {
    var draft = const MfOnboardingDraft(pan: 'GYAPK0411G');
    draft = draft.copyWith(uccOk: false, lastMessage: 'UCC failed');
    expect(draft.uccOk, isFalse);
    expect(draft.fatcaOk, isFalse);
    expect(draft.bankOk, isFalse);

    draft = draft.copyWith(uccOk: true, fatcaOk: true, bankOk: true);
    expect(draft.uccOk, isTrue);
    expect(draft.fatcaOk, isTrue);
    expect(draft.bankOk, isTrue);
  });
}
