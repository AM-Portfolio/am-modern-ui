import 'package:am_common/am_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matchesFamilyPortfolioFilter All / You / member', () {
    expect(
      matchesFamilyPortfolioFilter(
        familyMemberId: null,
        filterKey: FavoritePersonaStore.kAll,
      ),
      isTrue,
    );
    expect(
      matchesFamilyPortfolioFilter(
        familyMemberId: 'fm1',
        filterKey: FavoritePersonaStore.kAll,
      ),
      isTrue,
    );
    expect(
      matchesFamilyPortfolioFilter(
        familyMemberId: null,
        filterKey: FavoritePersonaStore.kYou,
      ),
      isTrue,
    );
    expect(
      matchesFamilyPortfolioFilter(
        familyMemberId: 'fm1',
        filterKey: FavoritePersonaStore.kYou,
      ),
      isFalse,
    );
    expect(
      matchesFamilyPortfolioFilter(
        familyMemberId: 'fm1',
        filterKey: 'fm1',
      ),
      isTrue,
    );
    expect(
      matchesFamilyPortfolioFilter(
        familyMemberId: 'fm2',
        filterKey: 'fm1',
      ),
      isFalse,
    );
  });

  test('labelForFamilyPortfolioFilter suffixes only for All', () {
    expect(
      labelForFamilyPortfolioFilter(
        baseName: 'Groww',
        familyMemberId: 'fm1',
        familyMemberName: 'Priyanshu',
        filterKey: FavoritePersonaStore.kAll,
        showFamilyUi: true,
      ),
      'Groww (Priyanshu)',
    );
    expect(
      labelForFamilyPortfolioFilter(
        baseName: 'Groww',
        familyMemberId: 'fm1',
        familyMemberName: 'Priyanshu',
        filterKey: FavoritePersonaStore.kYou,
        showFamilyUi: true,
      ),
      'Groww',
    );
    expect(
      labelForFamilyPortfolioFilter(
        baseName: 'Groww',
        familyMemberId: 'fm1',
        familyMemberName: 'Priyanshu',
        filterKey: FavoritePersonaStore.kAll,
        showFamilyUi: false,
      ),
      'Groww',
    );
  });

  test('showFamilyPortfolioFilter hides when empty', () {
    expect(showFamilyPortfolioFilter(const []), isFalse);
    expect(
      showFamilyPortfolioFilter([(id: null, name: 'x')]),
      isFalse,
    );
    expect(
      showFamilyPortfolioFilter([(id: 'fm1', name: 'Priyanshu')]),
      isTrue,
    );
  });
}
