import 'package:flutter_test/flutter_test.dart';

import 'package:am_app/core/navigation/cross_module_section_sequence.dart';
import 'package:am_app/core/router/app_routes.dart';

void main() {
  group('AppRoutes Market default landing', () {
    test('Market bottom-nav opens Dashboard not Paper', () {
      expect(
        AppRoutes.navTitleToDefaultPath['Market'],
        AppRoutes.marketPath('dashboard'),
      );
      expect(
        AppRoutes.navTitleToDefaultPath['Paper'],
        AppRoutes.marketPath('paper'),
      );
    });
  });

  group('CrossModuleSectionSequence.marketSwipeTabs', () {
    test('includes IPO and sibling Market user tabs in web order', () {
      expect(
        CrossModuleSectionSequence.marketSwipeTabs,
        [
          'all-indices',
          'dashboard',
          'paper',
          'market-analysis',
          'equity-insider',
          'futures-options',
          'ipo-center',
          'watch-list',
        ],
      );
    });

    test('ipo-center resolves to a Market path in the swipe sequence', () {
      final index = CrossModuleSectionSequence.indexOfLocation(
        AppRoutes.marketPath('ipo-center'),
      );
      expect(index, greaterThanOrEqualTo(0));
      expect(
        CrossModuleSectionSequence.marketStepPath('ipo-center'),
        AppRoutes.marketPath('ipo-center'),
      );
    });
  });

  group('CrossModuleSectionSequence AI Chat in swipe order', () {
    test('Market → AI Chat → Profile → wraps to Dashboard', () {
      const portfolioId = 'p1';
      final marketLast = CrossModuleSectionSequence.marketStepPath(
        CrossModuleSectionSequence.marketSwipeTabs.last,
      );
      final marketIndex = CrossModuleSectionSequence.indexOfLocation(
        marketLast,
        portfolioId: portfolioId,
      );
      final aiIndex = CrossModuleSectionSequence.indexOfLocation(
        AppRoutes.aiChat,
        portfolioId: portfolioId,
      );
      final profileIndex = CrossModuleSectionSequence.indexOfLocation(
        AppRoutes.profile,
        portfolioId: portfolioId,
      );
      final dashboardIndex = CrossModuleSectionSequence.indexOfLocation(
        AppRoutes.dashboard,
        portfolioId: portfolioId,
      );

      expect(aiIndex, marketIndex + 1);
      expect(profileIndex, aiIndex + 1);
      expect(dashboardIndex, 0);

      expect(
        CrossModuleSectionSequence.nextPath(
          marketLast,
          portfolioId: portfolioId,
        ),
        AppRoutes.aiChat,
      );
      expect(
        CrossModuleSectionSequence.nextPath(
          AppRoutes.aiChat,
          portfolioId: portfolioId,
        ),
        AppRoutes.profile,
      );
      expect(
        CrossModuleSectionSequence.nextPath(
          AppRoutes.profile,
          portfolioId: portfolioId,
        ),
        AppRoutes.dashboard,
      );
    });

    test('indexOfLocation resolves AI Chat path', () {
      expect(
        CrossModuleSectionSequence.indexOfLocation(AppRoutes.aiChat),
        greaterThanOrEqualTo(0),
      );
      expect(
        CrossModuleSectionSequence.indexOfLocation('${AppRoutes.aiChat}/session'),
        CrossModuleSectionSequence.indexOfLocation(AppRoutes.aiChat),
      );
    });
  });
}
