import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../widgets/portfolio_list_wrapper.dart';
import 'package:am_common/am_common.dart';

/// Platform-aware portfolio screen router
/// Routes to mobile or web specific portfolio screens based on platform
/// Now uses PortfolioListWrapper for portfolio selection functionality
class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({
    super.key,
    this.initialPortfolioId,
    this.initialTab = 'overview',
    this.onTabChanged,
    this.onPortfolioChanged,
    this.isSidebarVisible = true,
    this.onToggleSidebar,
    this.onBack,
    this.addTradeBuilder,
    this.holdingsPageBuilder,
    this.onOpenDocIntel,
    this.uploadPortfolioBuilder,
    this.onQuickAdd,
  });

  final String? initialPortfolioId;
  final String initialTab;
  final ValueChanged<String>? onTabChanged;
  final void Function(String portfolioId, String portfolioName)? onPortfolioChanged;

  final bool isSidebarVisible;
  final VoidCallback? onToggleSidebar;
  final VoidCallback? onBack;
  final Widget Function(BuildContext context, String portfolioId, String? portfolioName, VoidCallback onComplete)? addTradeBuilder;
  /// Web-only Holdings override (mobile keeps PortfolioHoldingsWidget).
  final Widget Function(BuildContext context, String portfolioId)? holdingsPageBuilder;
  final VoidCallback? onOpenDocIntel;
  final Widget Function(String portfolioId, String? portfolioName, VoidCallback onCancel)? uploadPortfolioBuilder;
  final ValueChanged<GlobalAddActionKind>? onQuickAdd;

  @override
  Widget build(BuildContext context) {
    CommonLogger.info(
      'Routing to portfolio screen with selection',
      tag: 'PortfolioScreen',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Match AppShell GlobalSidebar gate (full layout width > 1100), not
        // content-only width — otherwise desktop chrome + mobile portfolio
        // leaves GlobalAddActions with no listener.
        final layoutWidth = MediaQuery.sizeOf(context).width;
        final isMobileView = layoutWidth <= 1100;

        CommonLogger.debug(
          'Using PortfolioListWrapper for ${isMobileView ? 'mobile' : 'web'} view (layout: $layoutWidth, content: ${constraints.maxWidth})',
          tag: 'PortfolioScreen',
        );

        // Usage of PortfolioListWrapper handles platform-specific screen selection
        return PortfolioListWrapper(
          isMobile: isMobileView,
          initialPortfolioId: initialPortfolioId,
          initialTab: initialTab,
          onTabChanged: onTabChanged,
          onPortfolioChanged: onPortfolioChanged,
          isSidebarVisible: isSidebarVisible,
          onToggleSidebar: onToggleSidebar,
          onBack: onBack,
          addTradeBuilder: addTradeBuilder,
          holdingsPageBuilder: holdingsPageBuilder,
          onOpenDocIntel: onOpenDocIntel,
          uploadPortfolioBuilder: uploadPortfolioBuilder,
          onQuickAdd: onQuickAdd,
        );
      },
    );
  }
}
