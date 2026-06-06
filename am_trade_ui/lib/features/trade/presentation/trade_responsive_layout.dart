import 'package:flutter/material.dart';

import 'mobile/trade_mobile_screen.dart';
import 'web/trade_web_screen.dart';

/// Responsive router that switches between [TradeWebScreen] and [TradeMobileScreen]
/// based on the available screen width.
///
/// ## Breakpoint
/// Must match [UnifiedSidebarScaffold.tabletBreakpoint] (1100px).
/// Below that the sidebar scaffold already goes mobile-mode, so we should
/// render [TradeMobileScreen] instead to get the proper mobile UX.
///
/// - < [_mobileBreakpoint] px → [TradeMobileScreen] (bottom tab nav, 4 tabs)
/// - >= [_mobileBreakpoint] px → [TradeWebScreen]  (sidebar nav, 9+ tabs)
///
/// ## State preservation on resize
/// Both _currentTabIndex and the selected portfolio are hoisted here so that
/// when the layout switches the new screen starts on the same view — preventing
/// the unwanted jump back to the Portfolios page.
///
/// ## "Add Trade" tab (web index 9)
/// The web screen has a hidden "Add Trade" tab at index 9, which is beyond the
/// [TradeViewType] enum length of 9 (indices 0–8). We track this as the
/// special constant [_webAddTradeIndex]. When switching to mobile at this
/// index, [TradeMobileScreen] shows its own "Add Trade" tab (index 3).
class TradeResponsiveLayout extends StatefulWidget {
  const TradeResponsiveLayout({super.key});

  /// Must match UnifiedSidebarScaffold.tabletBreakpoint so we don't render
  /// TradeWebScreen inside a width where the sidebar already collapses to mobile.
  static const double _mobileBreakpoint = 1100;

  /// Index of the hidden "Add Trade" NavigationItem in TradeWebScreen's
  /// SwipeNavigationController (beyond the TradeViewType enum range).
  static const int _webAddTradeIndex = 9;

  @override
  State<TradeResponsiveLayout> createState() => _TradeResponsiveLayoutState();
}

class _TradeResponsiveLayoutState extends State<TradeResponsiveLayout> {
  /// Raw SwipeNavigationController index from the active screen.
  int _currentTabIndex = 0;

  String? _currentPortfolioId;
  String? _currentPortfolioName;

  void _onTabChanged(int index) {
    if (_currentTabIndex != index) {
      setState(() => _currentTabIndex = index);
    }
  }

  void _onPortfolioChanged(String id, String name) {
    if (_currentPortfolioId != id) {
      setState(() {
        _currentPortfolioId = id;
        _currentPortfolioName = name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < TradeResponsiveLayout._mobileBreakpoint;

        if (isMobile) {
          return TradeMobileScreen(
            initialTabIndex: _currentTabIndex,
            selectedPortfolioId: _currentPortfolioId,
            selectedPortfolioName: _currentPortfolioName,
            onTabChanged: (index) {
              // Mobile index 3 is Add Trade, which is Web index 9.
              if (index == 3) {
                _onTabChanged(TradeResponsiveLayout._webAddTradeIndex);
              } else {
                _onTabChanged(index);
              }
            },
            onPortfolioChanged: _onPortfolioChanged,
          );
        }

        // --- Desktop: map raw index → TradeViewType enum ---
        //
        // Index 9 is the special "Add Trade" hidden tab, which sits beyond the
        // TradeViewType enum (length 9, indices 0-8). When coming back to desktop
        // from mobile "Add Trade", fall back to holdings as the closest meaningful view.
        final TradeViewType webView;
        if (_currentTabIndex == TradeResponsiveLayout._webAddTradeIndex ||
            _currentTabIndex >= TradeViewType.values.length) {
          webView = TradeViewType.holdings;
        } else {
          webView = TradeViewType.values[_currentTabIndex];
        }

        return TradeWebScreen(
          initialView: webView,
          selectedPortfolioId: _currentPortfolioId,
          selectedPortfolioName: _currentPortfolioName,
          onTabChanged: _onTabChanged,
          onPortfolioChanged: _onPortfolioChanged,
        );
      },
    );
  }
}
