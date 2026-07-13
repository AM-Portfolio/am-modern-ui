import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/am_common.dart';

import '../providers/trade_internal_providers.dart';
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
class TradeResponsiveLayout extends ConsumerStatefulWidget {
  const TradeResponsiveLayout({
    super.key,
    this.initialPortfolioId,
    this.initialTab = 'portfolios',
    this.onTabChanged,
    this.onPortfolioChanged,
  });

  final String? initialPortfolioId;
  final String initialTab;
  final ValueChanged<String>? onTabChanged;
  final void Function(String portfolioId, String portfolioName)? onPortfolioChanged;

  /// Must match UnifiedSidebarScaffold.tabletBreakpoint so we don't render
  /// TradeWebScreen inside a width where the sidebar already collapses to mobile.
  static const double _mobileBreakpoint = 1100;

  /// Index of the hidden "Add Trade" NavigationItem in TradeWebScreen's
  /// SwipeNavigationController (beyond the TradeViewType enum range).
  static const int _webAddTradeIndex = 9;

  static const _tabSlugs = [
    'portfolios',
    'holdings',
    'calendar',
    'trades',
    'journal',
    'analysis',
    'market-analysis',
    'report',
    'unified',
  ];

  static int tabIndexFromSlug(String slug) {
    final index = _tabSlugs.indexOf(slug);
    return index >= 0 ? index : 0;
  }

  static String slugFromIndex(int index) =>
      _tabSlugs[index.clamp(0, _tabSlugs.length - 1)];

  @override
  ConsumerState<TradeResponsiveLayout> createState() =>
      TradeResponsiveLayoutState();
}

class TradeResponsiveLayoutState extends ConsumerState<TradeResponsiveLayout> {
  /// Raw SwipeNavigationController index from the active screen.
  late int _currentTabIndex;
  final GlobalKey<TradeWebScreenState> _webScreenKey = GlobalKey<TradeWebScreenState>();

  @override
  void initState() {
    super.initState();
    _currentTabIndex = TradeResponsiveLayout.tabIndexFromSlug(widget.initialTab);
    _currentPortfolioId = widget.initialPortfolioId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapTradeData());
  }

  void _bootstrapTradeData() {
    if (!mounted) return;
    invalidateTradeData(ref);
    ref.read(tradePortfoliosProvider.future).ignore();
  }

  @override
  void didUpdateWidget(TradeResponsiveLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      final next = TradeResponsiveLayout.tabIndexFromSlug(widget.initialTab);
      if (_currentTabIndex != next) {
        setState(() => _currentTabIndex = next);
      }
    }
    if (widget.initialPortfolioId != oldWidget.initialPortfolioId &&
        widget.initialPortfolioId != null) {
      setState(() => _currentPortfolioId = widget.initialPortfolioId);
    }
  }

  void openAddTrade() {
    setState(() {
      _currentTabIndex = TradeResponsiveLayout._webAddTradeIndex;
    });
    // Give it a frame to mount TradeWebScreen if it was on mobile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _webScreenKey.currentState?.openAddTrade();
    });
  }

  String? _currentPortfolioId;
  String? _currentPortfolioName;

  void _onTabChanged(int index) {
    if (_currentTabIndex != index) {
      setState(() => _currentTabIndex = index);
    }
    if (index != TradeResponsiveLayout._webAddTradeIndex) {
      widget.onTabChanged?.call(TradeResponsiveLayout.slugFromIndex(index));
    }
  }

  void _onPortfolioChanged(String id, String name) {
    if (_currentPortfolioId != id) {
      setState(() {
        _currentPortfolioId = id;
        _currentPortfolioName = name;
      });
    }
    context.selectPortfolio(id, name);
    widget.onPortfolioChanged?.call(id, name);
  }

  @override
  Widget build(BuildContext context) {
    final inheritedPortfolioId = context.selectedPortfolioId;
    final effectivePortfolioId = _currentPortfolioId ?? inheritedPortfolioId;
    if (_currentPortfolioId == null && inheritedPortfolioId != null) {
      _currentPortfolioId = inheritedPortfolioId;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < TradeResponsiveLayout._mobileBreakpoint;

        if (isMobile) {
          return TradeMobileScreen(
            initialTabIndex: _currentTabIndex,
            selectedPortfolioId: effectivePortfolioId,
            selectedPortfolioName: _currentPortfolioName ?? context.selectedPortfolioName,
            onTabChanged: (index) {
              // Map mobile view indices to web/controller indices.
              if (index == MobileTradeViewType.addTrade.index) {
                _onTabChanged(TradeResponsiveLayout._webAddTradeIndex);
              } else if (index == MobileTradeViewType.journal.index) {
                _onTabChanged(
                  TradeResponsiveLayout.tabIndexFromSlug('journal'),
                );
              } else if (index == MobileTradeViewType.metrics.index) {
                _onTabChanged(
                  TradeResponsiveLayout.tabIndexFromSlug('analysis'),
                );
              } else if (index == MobileTradeViewType.templates.index) {
                // Templates is mobile-only; keep local index without a web slug.
                if (_currentTabIndex != index) {
                  setState(() => _currentTabIndex = index);
                }
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
          key: _webScreenKey,
          initialView: webView,
          initialTabIndex: _currentTabIndex,
          selectedPortfolioId: effectivePortfolioId,
          selectedPortfolioName: _currentPortfolioName ?? context.selectedPortfolioName,
          onTabChanged: _onTabChanged,
          onPortfolioChanged: _onPortfolioChanged,
        );
      },
    );
  }
}
