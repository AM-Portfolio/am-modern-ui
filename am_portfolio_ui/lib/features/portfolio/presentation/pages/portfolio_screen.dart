import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../widgets/portfolio_list_wrapper.dart';
import 'package:am_common/core/utils/logger.dart';

/// Platform-aware portfolio screen router
/// Routes to mobile or web specific portfolio screens based on platform
/// Now uses PortfolioListWrapper for portfolio selection functionality
class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({
    required this.userId,
    super.key,
    this.isSidebarVisible = true,
    this.onToggleSidebar,
    this.onBack,
  });

  final String userId;
  final bool isSidebarVisible;
  final VoidCallback? onToggleSidebar;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    CommonLogger.info(
      'Routing to portfolio screen with selection for userId: $userId',
      tag: 'PortfolioScreen',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the same breakpoint (850px) as AuthWrapper for consistency
        final isMobileView = constraints.maxWidth < 850;

        CommonLogger.debug(
          'Using PortfolioListWrapper for ${isMobileView ? 'mobile' : 'web'} view (width: ${constraints.maxWidth})',
          tag: 'PortfolioScreen',
        );

        // Usage of PortfolioListWrapper handles platform-specific screen selection
        return PortfolioListWrapper(
          userId: userId,
          isMobile: isMobileView, // Dynamic switch based on width
          isSidebarVisible: isSidebarVisible,
          onToggleSidebar: onToggleSidebar,
          onBack: onBack,
        );
      },
    );
  }
}
