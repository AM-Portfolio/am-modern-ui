import 'package:am_common/am_common.dart';
import 'package:am_doc_intelligence_ui/features/import_portfolio_sync.dart';
import 'package:am_doc_intelligence_ui/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsePortfolioBriefMap', () {
    test('keeps familyMemberId and familyMemberName when present', () {
      final parsed = parsePortfolioBriefMap({
        'portfolioId': 'p1',
        'portfolioName': 'Groww',
        'familyMemberId': 'fm-1',
        'familyMemberName': 'Priyanshu Kumar',
      });
      expect(parsed, isNotNull);
      expect(parsed!['portfolioId'], 'p1');
      expect(parsed['portfolioName'], 'Groww');
      expect(parsed['familyMemberId'], 'fm-1');
      expect(parsed['familyMemberName'], 'Priyanshu Kumar');
    });

    test('omits empty family fields', () {
      final parsed = parsePortfolioBriefMap({
        'id': 'p2',
        'name': 'You book',
        'familyMemberId': '  ',
      });
      expect(parsed, isNotNull);
      expect(parsed!.containsKey('familyMemberId'), isFalse);
      expect(parsed.containsKey('familyMemberName'), isFalse);
    });

    test('returns null when id missing', () {
      expect(
        parsePortfolioBriefMap({'portfolioName': 'x'}),
        isNull,
      );
    });
  });

  group('personaKeyForImport', () {
    test('empty familyMemberId maps to You', () {
      expect(personaKeyForImport(), FavoritePersonaStore.kYou);
      expect(personaKeyForImport(familyMemberId: ''), FavoritePersonaStore.kYou);
      expect(
        personaKeyForImport(familyMemberId: '  '),
        FavoritePersonaStore.kYou,
      );
    });

    test('non-empty familyMemberId is the persona key', () {
      expect(personaKeyForImport(familyMemberId: 'fm-1'), 'fm-1');
    });
  });

  group('resolveFamilyMemberIdAfterImport', () {
    test('uses sync familyMemberId when already stamped', () async {
      final id = await resolveFamilyMemberIdAfterImport(
        sync: const ImportedPortfolioRef(
          portfolioId: 'p1',
          portfolioName: 'CAS',
          familyMemberId: 'fm-new',
        ),
        familyIdsBefore: const {},
        timeout: Duration.zero,
        interval: Duration.zero,
      );
      expect(id, 'fm-new');
    });
  });

  group('importedPortfolioRefFromBrief', () {
    test('maps family fields onto ImportedPortfolioRef', () {
      final ref = importedPortfolioRefFromBrief({
        'portfolioId': 'p1',
        'portfolioName': 'Groww',
        'familyMemberId': 'fm-1',
        'familyMemberName': 'Priyanshu',
      });
      expect(ref.portfolioId, 'p1');
      expect(ref.familyMemberId, 'fm-1');
      expect(ref.familyMemberName, 'Priyanshu');
    });
  });
}
