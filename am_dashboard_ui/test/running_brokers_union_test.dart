import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runningBrokersUnionDirectory adds valued first-class CAS dirs', () {
    final running = [
      AccountsPortfolioRow(
        portfolioId: 'z1',
        displayName: 'Zerodha',
        brokerType: 'ZERODHA',
        current: 930972,
        assetCount: 109,
        familyMemberId: 'fm1',
      ),
    ];
    final demat = [
      const DematAccountRow(
        accountNo: 'G1',
        accountType: 'demat',
        mappedBroker: 'groww',
        holdingValue: 106711.35,
        familyMemberId: 'fm1',
      ),
      const DematAccountRow(
        accountNo: 'A1',
        accountType: 'demat',
        mappedBroker: 'angleone',
        holdingValue: 15812.5,
        familyMemberId: 'fm1',
      ),
      const DematAccountRow(
        accountNo: 'M1',
        accountType: 'demat',
        mappedBroker: 'mirae',
        holdingValue: 43425.87,
        familyMemberId: 'fm1',
      ),
      const DematAccountRow(
        accountNo: 'Z2',
        accountType: 'demat',
        mappedBroker: 'zerodha',
        holdingValue: 942866,
        familyMemberId: 'fm1',
      ),
    ];

    final union = runningBrokersUnionDirectory(
      runningBrokers: running,
      directoryDemat: demat,
    );
    final codes = union.map((p) => p.brokerType).toSet();
    expect(codes, containsAll(['ZERODHA', 'GROWW', 'ANGEL_ONE']));
    expect(codes, isNot(contains('CAS_DEMAT')));
    expect(union.where((p) => p.brokerType == 'ZERODHA').length, 1);
    expect(
      union.firstWhere((p) => p.brokerType == 'GROWW').current,
      106711.35,
    );
  });
}
