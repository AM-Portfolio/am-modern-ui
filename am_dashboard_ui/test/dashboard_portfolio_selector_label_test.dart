import 'package:am_common/am_common.dart';
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

  test('parseDashboardPortfolioChoices keeps bare names + family fields', () {
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
    expect(choices.map((c) => c.name), ['Dhan', 'Dhan']);
    expect(choices[1].familyMemberId, 'fm1');
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
    expect(enriched.single.familyMemberName, 'Priyanshu Kumar');
    expect(enriched.single.name, 'Dhan');
  });

  test('filterDashboardChoicesByFamily All vs You vs member', () {
    final choices = enrichChoicesWithHubIds(
      parseDashboardPortfolioChoices([
        {
          'portfolioId': 'p-primary',
          'portfolioName': 'Groww',
          'kind': 'BROKER',
          'brokerType': 'GROWW',
          'assetCount': 10,
        },
        {
          'portfolioId': 'p-family',
          'portfolioName': 'Groww',
          'kind': 'BROKER',
          'brokerType': 'GROWW',
          'assetCount': 5,
          'familyMemberId': 'fm1',
          'familyMemberName': 'Priyanshu Kumar',
        },
      ]),
      const AccountsHub(
        familyMembers: [
          FamilyMemberRow(id: 'fm1', name: 'Priyanshu Kumar'),
        ],
      ),
    );

    final all = filterDashboardChoicesByFamily(
      choices: choices,
      filterKey: FavoritePersonaStore.kAll,
      showFamilyUi: true,
    );
    expect(all.map((c) => c.name), ['Groww', 'Groww (Priyanshu)']);

    final you = filterDashboardChoicesByFamily(
      choices: choices,
      filterKey: FavoritePersonaStore.kYou,
      showFamilyUi: true,
    );
    expect(you.map((c) => c.name), ['Groww']);
    expect(you.single.id, 'p-primary');

    final member = filterDashboardChoicesByFamily(
      choices: choices,
      filterKey: 'fm1',
      showFamilyUi: true,
    );
    expect(member.map((c) => c.name), ['Groww']);
    expect(member.single.id, 'p-family');
  });
}
