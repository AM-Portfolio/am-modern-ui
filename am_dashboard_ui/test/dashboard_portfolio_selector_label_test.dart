import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';
import 'package:am_dashboard_ui/presentation/widgets/dashboard_portfolio_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatPortfolioDropdownLabel primary vs family', () {
    expect(
      formatPortfolioDropdownLabel(displayName: 'Dhan'),
      'Dhan',
    );
    expect(
      formatPortfolioDropdownLabel(
        displayName: 'Dhan',
        familyMemberId: 'fm1',
        familyMemberName: 'Priyanshu Kumar',
      ),
      'Dhan (Priyanshu)',
    );
    expect(
      formatPortfolioDropdownLabel(
        displayName: 'Dhan',
        familyMemberId: 'fm1',
        familyMemberName: '  ',
      ),
      'Dhan',
    );
  });

  test('parseDashboardPortfolioChoices applies family suffix', () {
    final choices = parseDashboardPortfolioChoices([
      {
        'portfolioId': 'p-primary',
        'portfolioName': 'Dhan',
        'kind': 'BROKER',
        'brokerType': 'DHAN',
        'assetCount': 10,
      },
      {
        'portfolioId': 'p-family',
        'portfolioName': 'Dhan',
        'kind': 'BROKER',
        'brokerType': 'DHAN',
        'assetCount': 5,
        'familyMemberId': 'fm1',
        'familyMemberName': 'Priyanshu Kumar',
      },
    ]);
    expect(choices.map((c) => c.name), ['Dhan', 'Dhan (Priyanshu)']);
  });

  test('enrichChoicesWithHubIds fills blank family member name', () {
    final choices = parseDashboardPortfolioChoices([
      {
        'portfolioId': 'p-family',
        'portfolioName': 'Dhan',
        'kind': 'BROKER',
        'brokerType': 'DHAN',
        'assetCount': 5,
        'familyMemberId': 'fm1',
      },
    ]);
    expect(choices.single.name, 'Dhan');

    final enriched = enrichChoicesWithHubIds(
      choices,
      const AccountsHub(
        familyMembers: [
          FamilyMemberRow(id: 'fm1', name: 'Priyanshu Kumar'),
        ],
      ),
    );
    expect(enriched.single.name, 'Dhan (Priyanshu)');
  });
}
