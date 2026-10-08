import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:get_it/get_it.dart';
import 'package:am_common/am_common.dart' as common;
import 'package:am_library/am_library.dart';
import 'package:am_subscription_ui/am_subscription_ui.dart' as am_sub;

import '../../core/navigation/cross_module_section_sequence.dart';
import '../../core/navigation/cross_section_swipe_host.dart';
import '../../core/router/app_routes.dart';
import '../../core/router/share_url_builder.dart';

/// Dev mock portfolio IDs (trade mock JSON) must not be restored from session.
bool _isDevMockPortfolioId(String portfolioId) =>
    portfolioId.startsWith('mock-');

/// Main application shell with navigation — hosts [ShellRoute] child pages.
class SearchIntent extends Intent {}

class AppShell extends StatefulWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  bool _sessionRestored = false;
  bool _shellMarked = false;
  bool _portfolioSeeded = false;
  String _lastRecordedLocation = '';
  final List<String> _history = [];

  late final AnimationController _bottomNavController;
  late final Animation<double> _bottomNavFactor;
  late final ValueNotifier<bool> _mobileSearchOpen;
  bool _wantBottomNav = true;
  double _bottomNavScrollAccum = 0;
  static const double _bottomNavScrollThreshold = 12;
  static const Duration _bottomNavIdleHide = Duration(seconds: 3);
  static const double _bottomNavTapSlop = 18;
  int? _chromePointer;
  Offset? _chromePointerDown;
  bool _chromePointerMoved = false;
  bool _chromeScrollSessionActive = false;
  Timer? _bottomNavHideTimer;
  Timer? _securityAlertHideTimer;
  StreamSubscription<bool>? _marketGateSubscription;
  StreamSubscription<List<SecurityEventModel>>? _securityEventsSub;
  StreamSubscription<void>? _featureFlagServiceSub;
  SecurityEventModel? _securityAlert;

  bool get _isSecurityAlertBannerEnabled {
    if (FeatureFlags().enableSecurityAlertBanner) {
      return true;
    }
    if (GetIt.instance.isRegistered<common.FeatureFlagService>()) {
      return GetIt.instance<common.FeatureFlagService>().isOn(
        common.FeatureFlagKeys.securityAlertBannerEnabled,
        defaultValue: false,
      );
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _bottomNavController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
      value: 1.0,
    );
    final bottomNavCurve = CurvedAnimation(
      parent: _bottomNavController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _bottomNavFactor = Tween<double>(begin: 0.0, end: 1.0).animate(bottomNavCurve);
    // Drive overlay consumers with the linear controller value so layout
    // lift stays in sync with show/hide (curved factor overshoots).
    _bottomNavController.addListener(() {
      GlobalBottomNavVisibility.setFactor(_bottomNavController.value);
    });
    GlobalBottomNavVisibility.setFactor(_bottomNavController.value);

    _mobileSearchOpen = ValueNotifier<bool>(false);
    _mobileSearchOpen.addListener(_onMobileSearchOpenChanged);
    GlobalBottomNavVisibility.hideRequests.addListener(_onHideRequest);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialAuthAndConnect();
      _restoreSessionNav();
      _seedPortfolioSelectionFromSession();
      _startSecurityAlertsIfWeb();
      _listenToFeatureFlagChanges();
      // At top of initial page → show bottom nav for 3s.
      if (mounted) _showBottomNavWithIdleHide();
    });
  }

  void _onHideRequest() {
    if (!mounted) return;
    _bottomNavHideTimer?.cancel();
    _setBottomNavVisible(false);
  }

  @override
  void dispose() {
    _featureFlagServiceSub?.cancel();
    _featureFlagServiceSub = null;
    _bottomNavHideTimer?.cancel();
    _securityAlertHideTimer?.cancel();
    _marketGateSubscription?.cancel();
    GlobalBottomNavVisibility.hideRequests.removeListener(_onHideRequest);
    _mobileSearchOpen.removeListener(_onMobileSearchOpenChanged);
    _mobileSearchOpen.dispose();
    _marketGateSubscription = null;
    _securityEventsSub?.cancel();
    _securityEventsSub = null;
    if (kIsWeb) {
      AuthProviders.securityAlertService.stop();
    }
    _bottomNavController.dispose();
    super.dispose();
  }

  void _listenToFeatureFlagChanges() {
    if (!GetIt.instance.isRegistered<common.FeatureFlagService>()) return;
    _featureFlagServiceSub ??= GetIt.instance<common.FeatureFlagService>()
        .changes
        .listen((_) {
      if (!mounted) return;
      if (!_isSecurityAlertBannerEnabled) {
        _securityAlertHideTimer?.cancel();
        if (kIsWeb) {
          AuthProviders.securityAlertService.stop();
        }
        if (_securityAlert != null) {
          setState(() => _securityAlert = null);
        }
      } else {
        _startSecurityAlertsIfWeb();
      }
    });
  }

  void _startSecurityAlertsIfWeb() {
    if (!kIsWeb) return;
    if (!_isSecurityAlertBannerEnabled) {
      AuthProviders.securityAlertService.stop();
      _securityAlertHideTimer?.cancel();
      if (_securityAlert != null) {
        setState(() => _securityAlert = null);
      }
      return;
    }
    // Local demo-login review runs: skip new-sign-in banner.
    if (common.DemoLoginConfig.isDevSectionVisible) return;
    final service = AuthProviders.securityAlertService;
    service.start();
    _securityEventsSub ??= service.events.listen((events) {
      if (!mounted) return;
      if (!_isSecurityAlertBannerEnabled) {
        _securityAlertHideTimer?.cancel();
        setState(() => _securityAlert = null);
        return;
      }
      final next = events.isNotEmpty ? events.first : null;
      if (next == null) {
        _securityAlertHideTimer?.cancel();
        setState(() => _securityAlert = null);
        return;
      }
      if (_securityAlert?.eventId == next.eventId) return;
      _presentSecurityAlert(next);
    });
  }

  void _presentSecurityAlert(SecurityEventModel event) {
    _securityAlertHideTimer?.cancel();
    setState(() => _securityAlert = event);
    _securityAlertHideTimer = Timer(const Duration(seconds: 5), () {
      unawaited(_acknowledgeSecurityAlert());
    });
  }

  Future<void> _acknowledgeSecurityAlert() async {
    final alert = _securityAlert;
    if (alert == null) return;
    _securityAlertHideTimer?.cancel();
    await AuthProviders.securityAlertService.acknowledge(alert.eventId);
    if (!mounted) return;
    setState(() => _securityAlert = null);
  }

  Future<void> _startMarketStreamingGate() async {
    if (!GetIt.instance.isRegistered<common.MarketStreamingGate>()) return;
    final gate = GetIt.instance<common.MarketStreamingGate>();
    await gate.start();
    _marketGateSubscription?.cancel();
    _marketGateSubscription = gate.isOpenStream.listen((open) {
      if (!mounted) return;
      if (open) {
        _applyStreamingTabCoordinator(_activeNavItem);
      } else {
        _applyStreamingTabCoordinator(_activeNavItem);
      }
    });
  }

  void _resetMarketStreamingGate() {
    _marketGateSubscription?.cancel();
    _marketGateSubscription = null;
    if (GetIt.instance.isRegistered<common.MarketStreamingGate>()) {
      GetIt.instance<common.MarketStreamingGate>().reset();
    }
  }

  Future<void> _syncFeatureFlagAttributes(String userId) async {
    if (!GetIt.instance.isRegistered<common.FeatureFlagService>()) return;
    await GetIt.instance<common.FeatureFlagService>().updateAttributes({
      'id': userId,
      'platform': common.featureFlagPlatform(),
      'environment': common.ConfigService.resolvedEnv,
    });
  }

  Future<void> _clearFeatureFlagAttributes() async {
    if (!GetIt.instance.isRegistered<common.FeatureFlagService>()) return;
    await GetIt.instance<common.FeatureFlagService>().updateAttributes({
      'platform': common.featureFlagPlatform(),
      'environment': common.ConfigService.resolvedEnv,
    });
  }

  void _setBottomNavVisible(bool visible) {
    if (_wantBottomNav == visible) return;
    _wantBottomNav = visible;
    _bottomNavScrollAccum = 0;
    if (visible) {
      _bottomNavController.forward();
    } else {
      _bottomNavController.reverse();
    }
  }

  void _onMobileSearchOpenChanged() {
    if (!mounted) return;
    if (_mobileSearchOpen.value) {
      _bottomNavHideTimer?.cancel();
      _setBottomNavVisible(false);
    }
  }

  bool get _isAiChatRoute {
    try {
      return _currentLocation.startsWith(AppRoutes.aiChat);
    } catch (_) {
      return false;
    }
  }

  void _showBottomNavWithIdleHide() {
    if (_mobileSearchOpen.value) return;
    // AI chat + keyboard: never flash the floating nav while typing.
    if (mounted &&
        _isAiChatRoute &&
        MediaQuery.viewInsetsOf(context).bottom > 0) {
      return;
    }
    _bottomNavHideTimer?.cancel();
    _setBottomNavVisible(true);
    _bottomNavHideTimer = Timer(_bottomNavIdleHide, () {
      if (mounted) _setBottomNavVisible(false);
    });
  }

  void _onChromePointerDown(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.touch &&
        event.kind != PointerDeviceKind.mouse &&
        event.kind != PointerDeviceKind.stylus) {
      return;
    }
    if (_chromePointer != null) return;
    _chromePointer = event.pointer;
    _chromePointerDown = event.position;
    _chromePointerMoved = false;
  }

  void _onChromePointerMove(PointerMoveEvent event) {
    if (event.pointer != _chromePointer || _chromePointerDown == null) return;
    if ((event.position - _chromePointerDown!).distance > _bottomNavTapSlop) {
      _chromePointerMoved = true;
    }
  }

  void _onChromePointerUp(PointerUpEvent event) {
    if (event.pointer != _chromePointer) return;
    final wasTap = !_chromePointerMoved && !_chromeScrollSessionActive;
    _chromePointer = null;
    _chromePointerDown = null;
    _chromePointerMoved = false;
    if (GlobalBottomNavVisibility.suppressChromeTapReveal) {
      GlobalBottomNavVisibility.suppressChromeTapReveal = false;
      return;
    }
    if (wasTap) {
      _showBottomNavWithIdleHide();
    }
  }

  void _onChromePointerCancel(PointerCancelEvent event) {
    if (event.pointer != _chromePointer) return;
    _chromePointer = null;
    _chromePointerDown = null;
    _chromePointerMoved = false;
    if (GlobalBottomNavVisibility.suppressChromeTapReveal) {
      GlobalBottomNavVisibility.suppressChromeTapReveal = false;
    }
  }

  /// Scroll away → hide; at / toward top → show for [_bottomNavIdleHide] (3s).
  bool _handleBottomNavScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is ScrollStartNotification) {
      _chromeScrollSessionActive = true;
      return false;
    }
    if (notification is ScrollEndNotification) {
      _chromeScrollSessionActive = false;
      // Landed at top of any page → pop bottom nav for 3s.
      if (notification.metrics.pixels <= 0.5) {
        _showBottomNavWithIdleHide();
      }
      return false;
    }
    if (notification is! ScrollUpdateNotification) return false;

    // Already at (or above) the top — same as mobile section pills.
    if (notification.metrics.pixels <= 0.5) {
      if (!_wantBottomNav) {
        _showBottomNavWithIdleHide();
      }
      _bottomNavScrollAccum = 0;
      return false;
    }

    final delta = notification.scrollDelta ?? 0.0;
    if (delta == 0) return false;

    // Meaningful scroll invalidates an in-flight tap-to-reveal gesture.
    _chromePointerMoved = true;

    // Reset accum when direction flips (matches mobile section-tab chrome).
    if ((_bottomNavScrollAccum > 0 && delta < 0) ||
        (_bottomNavScrollAccum < 0 && delta > 0)) {
      _bottomNavScrollAccum = 0;
    }
    _bottomNavScrollAccum += delta;

    if (_bottomNavScrollAccum >= _bottomNavScrollThreshold && _wantBottomNav) {
      _bottomNavHideTimer?.cancel();
      _setBottomNavVisible(false);
      _bottomNavScrollAccum = 0;
    } else if (_bottomNavScrollAccum <= -_bottomNavScrollThreshold) {
      _showBottomNavWithIdleHide();
      _bottomNavScrollAccum = 0;
    }
    return false;
  }

  void _updateHistory(String currentLocation) {
    if (currentLocation != _lastRecordedLocation) {
      _lastRecordedLocation = currentLocation;
      // Reveal bottom nav whenever the route changes.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showBottomNavWithIdleHide();
      });
      if (_history.contains(currentLocation)) {
        final index = _history.indexOf(currentLocation);
        _history.removeRange(index + 1, _history.length);
      } else {
        _history.add(currentLocation);
      }
    }
  }

  List<SidebarItem> _sidebarItemsFor({required bool isAdmin}) => [
        const SidebarItem(
            title: 'Dashboard', icon: Icons.dashboard_rounded),
        const SidebarItem(
            title: 'Portfolio',
            icon: Icons.account_balance_wallet_rounded),
        const SidebarItem(title: 'Trade', icon: Icons.swap_horiz_rounded),
        const SidebarItem(title: 'Market', icon: Icons.show_chart_rounded),
        const SidebarItem(
            title: 'AI Chat', icon: Icons.auto_awesome_rounded),
        if (isAdmin)
          const SidebarItem(
              title: 'Analysis', icon: Icons.analytics_outlined),
      ];

  Future<void> _seedPortfolioSelectionFromSession() async {
    if (_portfolioSeeded) return;
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    _portfolioSeeded = true;

    final session =
        await common.SessionPersistenceService.instance.load(authState.user.id);
    if (session?.portfolioId == null || !mounted) return;

    final portfolioId = session!.portfolioId!;
    if (_isDevMockPortfolioId(portfolioId)) return;

    common.PortfolioSelectionScope.maybeStateOf(context)?.seedSelection(
      portfolioId,
      session.portfolioName,
    );
  }

  Future<void> _restoreSessionNav() async {
    if (_sessionRestored) return;
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    final userId = authState.user.id;
    final current = GoRouterState.of(context).matchedLocation;

    if (ShareUrlBuilder.isReloadableAppRoute(current) ||
        ShareUrlBuilder.isExplicitDeepLink(current)) {
      _sessionRestored = true;
      _syncSessionFromLocation(userId, current);
      return;
    }

    _sessionRestored = true;

    final session =
        await common.SessionPersistenceService.instance.load(userId);
    if (session == null || !mounted) return;

    if (ShareUrlBuilder.isExplicitDeepLink(current)) return;

    var savedPath = AppRoutes.pathForNavTitle(session.globalNav);
    if (savedPath == null) return;

    // Doc Intel is no longer a primary nav destination.
    if (session.globalNav == 'Doc Intel') {
      savedPath = AppRoutes.dashboard;
    }
    // Paper is now a Market tab (legacy sessions used primary "Paper").
    if (session.globalNav == 'Paper') {
      savedPath = AppRoutes.marketPath('paper');
    }

    final portfolioId = session.portfolioId;
    final restoredPortfolioId =
        portfolioId != null && _isDevMockPortfolioId(portfolioId)
            ? null
            : portfolioId;

    if (restoredPortfolioId != null) {
      if (session.globalNav == 'Portfolio') {
        savedPath = AppRoutes.portfolioPath(
          restoredPortfolioId,
          AppRoutes.portfolioTab(session.portfolioTabIndex),
        );
      } else if (session.globalNav == 'Trade') {
        savedPath = AppRoutes.tradePath(restoredPortfolioId, 'portfolios');
      }
    } else if (portfolioId != null && restoredPortfolioId == null) {
      common.SessionPersistenceService.instance.patch(
        userId,
        (s) => s.copyWith(clearPortfolio: true),
      );
    }

    if (current == AppRoutes.dashboard && savedPath != AppRoutes.dashboard) {
      final streamingNav =
          session.globalNav == 'Paper' ? 'Market' : session.globalNav;
      _applyStreamingTabCoordinator(streamingNav);
      context.go(savedPath);
    }
  }

  void _syncSessionFromLocation(String userId, String location) {
    final nav = AppRoutes.activeNavTitleForLocation(location);
    final portfolioId = ShareUrlBuilder.portfolioIdFromLocation(location);
    final portfolioTab = ShareUrlBuilder.portfolioTabFromLocation(location);

    if (portfolioId != null) {
      common.PortfolioSelectionScope.maybeStateOf(context)
          ?.seedSelection(portfolioId, null);
    }

    common.SessionPersistenceService.instance.patch(
      userId,
      (s) => s.copyWith(
        globalNav: nav,
        portfolioId: portfolioId,
        portfolioTabIndex: portfolioTab != null
            ? AppRoutes.portfolioTabIndex(portfolioTab)
            : s.portfolioTabIndex,
        clearPortfolio: portfolioId == null,
      ),
    );
  }

  void _applyStreamingTabCoordinator(String tabTitle) {
    if (!GetIt.instance.isRegistered<common.AmStompClient>()) return;
    if (tabTitle.isEmpty) return;
    common.StreamingTabCoordinator(GetIt.instance<common.AmStompClient>())
        .onTabSelected(tabTitle);
  }

    List<common.CommandItem> _getMockSearchItems(BuildContext context) {
    return [
      // Indices
      common.CommandItem(title: 'NIFTY 50', subtitle: 'National Stock Exchange Index', category: 'Market', icon: Icons.show_chart, onSelected: () => context.go('/app/market/NIFTY50')),
      common.CommandItem(title: 'NIFTY BANK', subtitle: 'Banking Sector Index', category: 'Market', icon: Icons.account_balance, onSelected: () => context.go('/app/market/BANKNIFTY')),
      common.CommandItem(title: 'SENSEX', subtitle: 'BSE SENSEX Index', category: 'Market', icon: Icons.show_chart, onSelected: () => context.go('/app/market/SENSEX')),
      common.CommandItem(title: 'NIFTY IT', subtitle: 'IT Sector Index', category: 'Market', icon: Icons.computer, onSelected: () => context.go('/app/market/NIFTYIT')),
      
      // Top Stocks
      common.CommandItem(title: 'Reliance Industries', subtitle: 'RELIANCE - Equity', category: 'Market', icon: Icons.business, onSelected: () => context.go('/app/market/RELIANCE')),
      common.CommandItem(title: 'HDFC Bank', subtitle: 'HDFCBANK - Equity', category: 'Market', icon: Icons.business, onSelected: () => context.go('/app/market/HDFCBANK')),
      common.CommandItem(title: 'TCS', subtitle: 'TCS - Equity', category: 'Market', icon: Icons.business, onSelected: () => context.go('/app/market/TCS')),
      common.CommandItem(title: 'ICICI Bank', subtitle: 'ICICIBANK - Equity', category: 'Market', icon: Icons.business, onSelected: () => context.go('/app/market/ICICIBANK')),
      common.CommandItem(title: 'Infosys', subtitle: 'INFY - Equity', category: 'Market', icon: Icons.business, onSelected: () => context.go('/app/market/INFY')),
      common.CommandItem(title: 'State Bank of India', subtitle: 'SBIN - Equity', category: 'Market', icon: Icons.business, onSelected: () => context.go('/app/market/SBIN')),
      common.CommandItem(title: 'Bharti Airtel', subtitle: 'BHARTIARTL - Equity', category: 'Market', icon: Icons.business, onSelected: () => context.go('/app/market/BHARTIARTL')),
      common.CommandItem(title: 'ITC', subtitle: 'ITC - Equity', category: 'Market', icon: Icons.business, onSelected: () => context.go('/app/market/ITC')),
      common.CommandItem(title: 'Larsen & Toubro', subtitle: 'LT - Equity', category: 'Market', icon: Icons.business, onSelected: () => context.go('/app/market/LT')),
      common.CommandItem(title: 'Bajaj Finance', subtitle: 'BAJFINANCE - Equity', category: 'Market', icon: Icons.business, onSelected: () => context.go('/app/market/BAJFINANCE')),
      common.CommandItem(title: 'Hindustan Unilever', subtitle: 'HINDUNILVR - Equity', category: 'Market', icon: Icons.business, onSelected: () => context.go('/app/market/HINDUNILVR')),
      common.CommandItem(title: 'Axis Bank', subtitle: 'AXISBANK - Equity', category: 'Market', icon: Icons.business, onSelected: () => context.go('/app/market/AXISBANK')),
      common.CommandItem(title: 'Kotak Mahindra Bank', subtitle: 'KOTAKBANK - Equity', category: 'Market', icon: Icons.business, onSelected: () => context.go('/app/market/KOTAKBANK')),
      common.CommandItem(title: 'Mahindra & Mahindra', subtitle: 'M&M - Equity', category: 'Market', icon: Icons.business, onSelected: () => context.go('/app/market/M&M')),
      common.CommandItem(title: 'Tata Motors', subtitle: 'TATAMOTORS - Equity', category: 'Market', icon: Icons.directions_car, onSelected: () => context.go('/app/market/TATAMOTORS')),
      common.CommandItem(title: 'Asian Paints', subtitle: 'ASIANPAINT - Equity', category: 'Market', icon: Icons.format_paint, onSelected: () => context.go('/app/market/ASIANPAINT')),
      common.CommandItem(title: 'Maruti Suzuki', subtitle: 'MARUTI - Equity', category: 'Market', icon: Icons.directions_car, onSelected: () => context.go('/app/market/MARUTI')),
      common.CommandItem(title: 'Sun Pharma', subtitle: 'SUNPHARMA - Equity', category: 'Market', icon: Icons.medical_services, onSelected: () => context.go('/app/market/SUNPHARMA')),
      common.CommandItem(title: 'Tata Steel', subtitle: 'TATASTEEL - Equity', category: 'Market', icon: Icons.precision_manufacturing, onSelected: () => context.go('/app/market/TATASTEEL')),
      common.CommandItem(title: 'Wipro', subtitle: 'WIPRO - Equity', category: 'Market', icon: Icons.business, onSelected: () => context.go('/app/market/WIPRO')),
      common.CommandItem(title: 'Power Grid Corp', subtitle: 'POWERGRID - Equity', category: 'Market', icon: Icons.bolt, onSelected: () => context.go('/app/market/POWERGRID')),
      common.CommandItem(title: 'NTPC', subtitle: 'NTPC - Equity', category: 'Market', icon: Icons.bolt, onSelected: () => context.go('/app/market/NTPC')),
      common.CommandItem(title: 'Ultratech Cement', subtitle: 'ULTRACEMCO - Equity', category: 'Market', icon: Icons.construction, onSelected: () => context.go('/app/market/ULTRACEMCO')),
      common.CommandItem(title: 'Titan Company', subtitle: 'TITAN - Equity', category: 'Market', icon: Icons.watch, onSelected: () => context.go('/app/market/TITAN')),
      common.CommandItem(title: 'Nestle India', subtitle: 'NESTLEIND - Equity', category: 'Market', icon: Icons.fastfood, onSelected: () => context.go('/app/market/NESTLEIND')),
      common.CommandItem(title: 'Bajaj Finserv', subtitle: 'BAJAJFINSV - Equity', category: 'Market', icon: Icons.business, onSelected: () => context.go('/app/market/BAJAJFINSV')),
      common.CommandItem(title: 'Tech Mahindra', subtitle: 'TECHM - Equity', category: 'Market', icon: Icons.computer, onSelected: () => context.go('/app/market/TECHM')),
      common.CommandItem(title: 'ONGC', subtitle: 'ONGC - Equity', category: 'Market', icon: Icons.oil_barrel, onSelected: () => context.go('/app/market/ONGC')),
      common.CommandItem(title: 'Hindalco', subtitle: 'HINDALCO - Equity', category: 'Market', icon: Icons.precision_manufacturing, onSelected: () => context.go('/app/market/HINDALCO')),
      common.CommandItem(title: 'HCL Tech', subtitle: 'HCLTECH - Equity', category: 'Market', icon: Icons.computer, onSelected: () => context.go('/app/market/HCLTECH')),
      common.CommandItem(title: 'Coal India', subtitle: 'COALINDIA - Equity', category: 'Market', icon: Icons.terrain, onSelected: () => context.go('/app/market/COALINDIA')),
      common.CommandItem(title: 'Adani Enterprises', subtitle: 'ADANIENT - Equity', category: 'Market', icon: Icons.business, onSelected: () => context.go('/app/market/ADANIENT')),
      common.CommandItem(title: 'Adani Ports', subtitle: 'ADANIPORTS - Equity', category: 'Market', icon: Icons.directions_boat, onSelected: () => context.go('/app/market/ADANIPORTS')),
      
      // Global
      common.CommandItem(title: 'AAPL', subtitle: 'Apple Inc. - Equity', category: 'Market', icon: Icons.show_chart, onSelected: () => context.go('/app/market/AAPL')),
      common.CommandItem(title: 'TSLA', subtitle: 'Tesla Inc. - Equity', category: 'Market', icon: Icons.show_chart, onSelected: () => context.go('/app/market/TSLA')),
      
      // App Pages
      common.CommandItem(title: 'Trade Journal', subtitle: 'Review your past performance', category: 'Trade', icon: Icons.book, onSelected: () => context.go('/app/trade/journal')),
      common.CommandItem(title: 'Federal Reserve cuts rates', subtitle: 'Breaking News', category: 'News', icon: Icons.article, onSelected: () => context.go('/app/dashboard')),
      common.CommandItem(title: 'My Tech Basket', subtitle: 'Custom Portfolio Basket', category: 'Portfolio', icon: Icons.pie_chart, onSelected: () => context.go('/app/portfolio/baskets')),
      common.CommandItem(title: 'Place New Order', subtitle: 'Open the trading desk', category: 'Action', icon: Icons.add_shopping_cart, onSelected: () => context.go('/app/trade')),
    ];
  }

  void _showSearch() {
    final items = _getMockSearchItems(context);
    final isMobile =
        MediaQuery.sizeOf(context).width < UIConstants.mobileBreakpoint;
    if (isMobile) {
      common.AmCommandPalette.showMobileTop(context, items: items);
    } else {
      common.AmCommandPalette.show(context, items: items);
    }
  }

  Color _moduleAccentFor(String title) {
    switch (title.toLowerCase()) {
      case 'dashboard':
        return ModuleColors.dashboard;
      case 'portfolio':
        return ModuleColors.portfolio;
      case 'trade':
        return ModuleColors.trade;
      case 'market':
        return ModuleColors.market;
      case 'ai chat':
        return ModuleColors.aiChat;
      case 'analysis':
      case 'doc intel':
        return ModuleColors.analytics;
      default:
        return ModuleColors.dashboard;
    }
  }

  void _onGlobalNavigate(String title, String userId) {
    final path = AppRoutes.pathForNavTitle(title);
    if (path == null) return;

    ProductTelemetry.instance.featureAction(
      'global_nav',
      tag: 'shell',
      metadata: {'title': title},
    );
    _showBottomNavWithIdleHide();
    _applyStreamingTabCoordinator(title);
    context.go(path);
    common.SessionPersistenceService.instance.patch(
      userId,
      (s) => s.copyWith(globalNav: title, clearBasket: title != 'Portfolio'),
    );
  }

  String? _resolveSwipePortfolioId() {
    final fromUrl =
        ShareUrlBuilder.portfolioIdFromLocation(_currentLocation);
    if (fromUrl != null && fromUrl.isNotEmpty) return fromUrl;
    final cached = common.SessionPersistenceService.instance.cached?.portfolioId;
    if (cached != null &&
        cached.isNotEmpty &&
        !_isDevMockPortfolioId(cached)) {
      return cached;
    }
    return null;
  }

  void _goSwipePath(String path, String userId) {
    _showBottomNavWithIdleHide();
    final navTitle = AppRoutes.activeNavTitleForLocation(path);
    _applyStreamingTabCoordinator(navTitle);
    context.go(path);
    common.SessionPersistenceService.instance.patch(
      userId,
      (s) => s.copyWith(
        globalNav: navTitle,
        clearBasket: navTitle != 'Portfolio',
      ),
    );
  }

  void _onCrossSectionNext(String userId) {
    // Doc Intel is a shortcut destination (not in the swipe sequence).
    if (_currentLocation.startsWith(AppRoutes.docIntel)) return;
    final next = CrossModuleSectionSequence.nextPath(
      _currentLocation,
      portfolioId: _resolveSwipePortfolioId(),
    );
    if (next == null) return;
    _goSwipePath(next, userId);
  }

  void _onCrossSectionPrevious(String userId) {
    if (_currentLocation.startsWith(AppRoutes.docIntel)) return;
    final prev = CrossModuleSectionSequence.previousPath(
      _currentLocation,
      portfolioId: _resolveSwipePortfolioId(),
    );
    if (prev == null) return;
    _goSwipePath(prev, userId);
  }

  Future<void> _checkInitialAuthAndConnect() async {
    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;
    if (authState is Authenticated) {
      common.AppLogger.info(
        'AppShell: Initialized while Authenticated. Triggering STOMP connection...',
      );
      final stompCubit = context.read<common.StompConnectionCubit>();

      stompCubit.onConnected = (userId) {
        common.AppLogger.info('AppShell (Initial): STOMP Connected for $userId');
        if (mounted) _applyStreamingTabCoordinator(_activeNavItem);
      };

      final secureStorage = GetIt.instance<common.SecureStorageService>();
      final token = await secureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          common.AppLogger.warning(
            'AppShell: Authenticated state but no token in storage. Forcing logout.',
          );
          authCubit.logout();
        }
        return;
      }
      if (mounted) {
        stompCubit.updateToken(token, userId: authState.user.id);
        unawaited(common.UserAvatarStore.instance.loadForUser(authState.user.id));
        unawaited(_startMarketStreamingGate());
        unawaited(_syncFeatureFlagAttributes(authState.user.id));
        unawaited(
          am_sub.ReferralIntroHost.maybeShow(context, authState.user.id),
        );
      }
    }
  }

  String get _activeNavItem {
    final location = GoRouterState.of(context).matchedLocation;
    return AppRoutes.activeNavTitleForLocation(location);
  }

  String get _currentLocation => GoRouterState.of(context).matchedLocation;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listener: (context, state) async {
            final stompCubit = context.read<common.StompConnectionCubit>();

            if (state is Authenticated) {
              common.AppLogger.info(
                'AppShell: AuthState changed to Authenticated. Connecting STOMP...',
              );

              stompCubit.onConnected = (userId) {
                common.AppLogger.info('AppShell: STOMP Connected for $userId');
                if (context.mounted) {
                  _applyStreamingTabCoordinator(_activeNavItem);
                }
              };

              final secureStorage = GetIt.instance<common.SecureStorageService>();
              final token = await secureStorage.getAccessToken();
              if (token == null || token.isEmpty) {
                if (context.mounted) {
                  common.AppLogger.warning(
                    'AppShell: Authenticated state but no token. Forcing logout.',
                  );
                  context.read<AuthCubit>().logout();
                }
                return;
              }
              if (context.mounted) {
                stompCubit.updateToken(token, userId: state.user.id);
                _portfolioSeeded = false;
                _restoreSessionNav();
                _seedPortfolioSelectionFromSession();
                unawaited(
                  common.UserAvatarStore.instance.loadForUser(state.user.id),
                );
                unawaited(_startMarketStreamingGate());
                unawaited(_syncFeatureFlagAttributes(state.user.id));
                unawaited(
                  am_sub.ReferralIntroHost.maybeShow(context, state.user.id),
                );
              }
            } else if (state is Unauthenticated) {
              _portfolioSeeded = false;
              common.AppLogger.info(
                'AppShell: AuthState changed to Unauthenticated. Disconnecting STOMP...',
              );
              _resetMarketStreamingGate();
              unawaited(_clearFeatureFlagAttributes());
              stompCubit.onConnected = null;
              stompCubit.updateToken(null);
            }
          },
        ),
        BlocListener<FeatureFlagCubit, FeatureFlagState>(
          listener: (context, state) {
            if (!_isSecurityAlertBannerEnabled) {
              _securityAlertHideTimer?.cancel();
              if (kIsWeb) {
                AuthProviders.securityAlertService.stop();
              }
              if (_securityAlert != null) {
                setState(() => _securityAlert = null);
              }
            } else {
              _startSecurityAlertsIfWeb();
            }
          },
        ),
      ],
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final authPending = authState is AuthInitial ||
              authState is AuthLoading ||
              authState is AuthRestoreFailed;

          if (authState is! Authenticated && !authPending) {
            return const SizedBox.shrink();
          }

          if (!_shellMarked && authState is Authenticated) {
            _shellMarked = true;
            common.BootTrace.instance.mark('shell_visible');
          }
final userId =
              authState is Authenticated ? authState.user.id : '';
          final isAdmin =
              authState is Authenticated && authState.user.isAdmin;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          final currentLocation = GoRouterState.of(context).matchedLocation;
          _updateHistory(currentLocation);

          // AI chat + soft keyboard: keep floating nav hidden for the session.
          final aiChatKeyboardOpen = currentLocation.startsWith(AppRoutes.aiChat) &&
              MediaQuery.viewInsetsOf(context).bottom > 0;
          if (aiChatKeyboardOpen && _wantBottomNav) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _bottomNavHideTimer?.cancel();
              _setBottomNavVisible(false);
            });
          }

          final shell = LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = BrowserZoomScope.layoutWidthOf(context) > 1100;

              return PopScope(
                canPop: _history.length <= 1,
                onPopInvokedWithResult: (didPop, result) {
                  if (didPop) return;
                  if (_history.length > 1) {
                    _history.removeLast(); // Remove current location
                    final previousLocation = _history.last;
                    
                    final previousTitle = AppRoutes.activeNavTitleForLocation(previousLocation);
                    _applyStreamingTabCoordinator(previousTitle);
                    
                    context.go(previousLocation);
                    
                    common.SessionPersistenceService.instance.patch(
                      userId,
                      (s) => s.copyWith(
                        globalNav: previousTitle.isEmpty ? 'Dashboard' : previousTitle,
                      ),
                    );
                  }
                },
                child: common.MobileSearchScope(
                  getItems: () => _getMockSearchItems(context),
                  searchOpen: _mobileSearchOpen,
                  child: common.OfflineShell(
                                    child: Shortcuts(
                    shortcuts: {
                      LogicalKeySet(
                        !kIsWeb && Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control,
                        LogicalKeyboardKey.keyK
                      ): SearchIntent(),
                    },
                    child: Actions(
                      actions: {
                        SearchIntent: CallbackAction<SearchIntent>(
                          onInvoke: (intent) {
                            _showSearch();
                            return null;
                          },
                        ),
                      },
                      child: Scaffold(
                  // Body draws under the floating overlay nav — no reserved slot.
                  extendBody: !isDesktop,
                  resizeToAvoidBottomInset: false,
                  body: Stack(
                    children: [
                      Row(
                        children: [
                          if (isDesktop && authState is Authenticated)
                            GlobalSidebar(
                              activeNavItem: _activeNavItem,
                              isDarkMode: isDark,
                              userName: authState.user.displayName,
                              userEmail: authState.user.email,
                              userAvatarUrl: authState.user.photoUrl,
                              userAvatar: _buildSidebarAvatar(
                                displayName: authState.user.displayName ??
                                    authState.user.email,
                                photoUrl: authState.user.photoUrl,
                              ),
                              moduleShareUrls: AppRoutes.navTitleToDefaultPath,
                                onSearchTap: _showSearch,
                              onThemeToggle: () {
                                try {
                                  final cubit = context.read<ThemeCubit>();
                                  showThemeModePickerDialog(
                                    context: context,
                                    currentMode: cubit.state.mode,
                                    onSelected: (mode) {
                                      cubit.setTheme(mode);
                                    },
                                  );
                                } catch (e) {
                                  debugPrint('Theme picker error: $e');
                                }
                              },
                              onLogout: () async {
                                final uid = authState.user.id;
                                if (GetIt.I.isRegistered<common.OfflineSyncEngine>() &&
                                    uid.isNotEmpty) {
                                  await GetIt.I<common.OfflineSyncEngine>()
                                      .clearUser(uid);
                                }
                                if (GetIt.I.isRegistered<am_sub.SubscriptionCubit>()) {
                                  await GetIt.I<am_sub.SubscriptionCubit>()
                                      .invalidateCache();
                                }
                                if (context.mounted) {
                                  await context.read<AuthCubit>().logout();
                                }
                              },
                              onProfileTap: () =>
                                  context.go(AppRoutes.profile),
                              onNavigate: (title) =>
                                  _onGlobalNavigate(title, userId),
                              items: _sidebarItemsFor(isAdmin: isAdmin),
                            ),
                          Expanded(
                            child: isDesktop
                                ? (authState is Authenticated
                                    ? common.CrossSectionNavScope(
                                        controller:
                                            common.CrossSectionNavController(
                                          goNextModule: () =>
                                              _onCrossSectionNext(userId),
                                          goPreviousModule: () =>
                                              _onCrossSectionPrevious(userId),
                                        ),
                                        child: common.PortfolioSelectionScope(
                                          child: widget.child,
                                        ),
                                      )
                                    : widget.child)
                                : Listener(
                                    behavior: HitTestBehavior.translucent,
                                    onPointerDown: _onChromePointerDown,
                                    onPointerMove: _onChromePointerMove,
                                    onPointerUp: _onChromePointerUp,
                                    onPointerCancel: _onChromePointerCancel,
                                    child: NotificationListener<
                                        ScrollNotification>(
                                      onNotification: _handleBottomNavScroll,
                                      child: authState is Authenticated
                                          ? common.CrossSectionNavScope(
                                              controller: common
                                                  .CrossSectionNavController(
                                                goNextModule: () =>
                                                    _onCrossSectionNext(
                                                        userId),
                                                goPreviousModule: () =>
                                                    _onCrossSectionPrevious(
                                                        userId),
                                              ),
                                              child:
                                                  common.PortfolioSelectionScope(
                                                child: CrossSectionSwipeHost(
                                                  onNext: () =>
                                                      _onCrossSectionNext(
                                                          userId),
                                                  onPrevious: () =>
                                                      _onCrossSectionPrevious(
                                                          userId),
                                                  child: widget.child,
                                                ),
                                              ),
                                            )
                                          : widget.child,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      if (!isDesktop && authState is Authenticated)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: ValueListenableBuilder<bool>(
                            valueListenable: _mobileSearchOpen,
                            builder: (context, searchOpen, child) {
                              if (searchOpen) {
                                return const SizedBox.shrink();
                              }
                              return child!;
                            },
                            child: AnimatedBuilder(
                            animation: _bottomNavController,
                            builder: (context, child) {
                              final visible =
                                  _bottomNavController.value > 0.01;
                              return IgnorePointer(
                                ignoring: !visible,
                                child: child,
                              );
                            },
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 1.15),
                                end: Offset.zero,
                              ).animate(_bottomNavFactor),
                              child: FadeTransition(
                                opacity: _bottomNavFactor,
                                child: GlobalBottomNavigation(
                                  activeNavItem: _activeNavItem,
                                  isDarkMode: isDark,
                                  accentColor: _moduleAccentFor(_activeNavItem),
                                  userName: authState.user.displayName,
                                  visibleCount: 5,
                                  moduleShareUrls: AppRoutes.navTitleToDefaultPath,
                                  onSearchTap: _showSearch,
                              onNavigate: (title) =>
                                  _onGlobalNavigate(title, userId),
                                  items: [
                                    const SidebarItem(
                                      title: 'Dashboard',
                                      icon: Icons.dashboard_rounded,
                                    ),
                                    const SidebarItem(
                                      title: 'Portfolio',
                                      icon: Icons
                                          .account_balance_wallet_rounded,
                                    ),
                                    const SidebarItem(
                                      title: 'Trade',
                                      icon: Icons.swap_horiz_rounded,
                                    ),
                                    const SidebarItem(
                                      title: 'Market',
                                      icon: Icons.show_chart_rounded,
                                    ),
                                    const SidebarItem(
                                      title: 'AI Chat',
                                      icon: Icons.auto_awesome_rounded,
                                    ),
                                    const SidebarItem(
                                      title: 'Profile',
                                      icon: Icons.person_rounded,
                                    ),
                                    if (isAdmin) ...[
                                      const SidebarItem(
                                        title: 'Analysis',
                                        icon: Icons.analytics_outlined,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          ),
                        ),
                      if (kIsWeb && _isSecurityAlertBannerEnabled && _securityAlert != null)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SecurityAlertBanner(
                            event: _securityAlert!,
                            onAcknowledge: () async {
                              await _acknowledgeSecurityAlert();
                            },
                            onReviewSessions: () {
                              context.go(AppRoutes.activeSessions);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                ),
              ),
              ),
              ),
              );
            },
          );

          // Cover shell while auth restores (web + native). Authenticated users
          // never hit this branch — [authPending] is false once session lands.
          if (!authPending) return shell;

          final failed = authState is AuthRestoreFailed;
          return Stack(
            children: [
              shell,
              Positioned.fill(
                child: AmSessionStatusView(
                  title: failed
                      ? 'Connection issue — retrying session…'
                      : 'Restoring your session…',
                  subtitle: failed
                      ? 'We could not reach the auth service. You can retry now.'
                      : 'Signing you back into AM securely',
                  tone: failed
                      ? AmSessionStatusTone.retrying
                      : AmSessionStatusTone.restoring,
                  onRetry: failed
                      ? () => context.read<AuthCubit>().checkAuthStatus()
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebarAvatar({
    required String displayName,
    String? photoUrl,
  }) {
    final isPaid = GetIt.I.isRegistered<am_sub.SubscriptionCubit>() &&
        GetIt.I<am_sub.SubscriptionCubit>().isPaidSubscription;
    final avatar = common.UserAvatar(
      radius: 20,
      displayName: displayName,
      remotePhotoUrl: photoUrl,
    );
    if (!isPaid) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.9),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                blurRadius: 8,
              ),
            ],
          ),
          child: avatar,
        ),
        Positioned(
          top: -4,
          child: Icon(
            Icons.workspace_premium_rounded,
            size: 14,
            color: const Color(0xFFFFB300),
            shadows: [
              Shadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

