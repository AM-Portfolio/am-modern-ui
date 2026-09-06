import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:am_common/am_common.dart';
import '../domain/models/basket_opportunity.dart';
import 'pages/basket_preview_page.dart';
import 'pages/basket_dashboard_page.dart';
import 'pages/manual_basket_creator_page.dart';
import 'pages/basket_final_preview_page.dart';
import 'widgets/basket_explorer.dart';
import 'providers/basket_providers.dart';
import 'flow/basket_flow_controller.dart';

/// Nested basket navigation inside portfolio content (keeps global + secondary sidebars).
class BasketNavigation {
  BasketNavigation._();

  static const String explorerRoute = '/';
  static const String previewRoute = '/preview';
  static const String creatorRoute = '/creator';
  static const String finalPreviewRoute = '/final_preview';
  static const String dashboardRoute = '/dashboard';
  static const int basketsTabIndex = 4;

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Shared Discover / My Baskets mode (sticky header + explorer).
  static final ValueNotifier<BasketViewMode> viewMode =
      ValueNotifier(BasketViewMode.discover);

  static bool get hasNestedNavigator => navigatorKey.currentState != null;

  /// Switch explorer mode; pops nested preview/customize back to explorer first.
  static void setViewMode(BasketViewMode mode) {
    final nested = navigatorKey.currentState;
    if (nested != null && nested.canPop()) {
      nested.popUntil(
        (route) =>
            route.settings.name == explorerRoute || route.isFirst,
      );
    }
    if (viewMode.value != mode) {
      viewMode.value = mode;
    }
  }

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    required String userId,
    required String portfolioId,
    bool showInlineToggle = false,
  }) {
    switch (settings.name) {
      case previewRoute:
        final args = settings.arguments! as BasketPreviewArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BasketPreviewPage(
            etfIsin: args.etfIsin,
            userId: args.userId,
            portfolioId: args.portfolioId,
            seededOpportunity: args.seededOpportunity,
            embedded: true,
          ),
        );
      case creatorRoute:
        final args = settings.arguments! as BasketCreatorArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ManualBasketCreatorPage(
            opportunity: args.opportunity,
            userId: args.userId,
            portfolioId: args.portfolioId,
            embedded: true,
          ),
        );
      case finalPreviewRoute:
        final args = settings.arguments! as BasketFinalPreviewArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BasketFinalPreviewPage(args: args),
        );
      case dashboardRoute:
        final args = settings.arguments! as Map<String, dynamic>;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BasketDashboardPage(
            basketId: args['basketId'] as String,
            userId: args['userId'] as String,
            embedded: true,
          ),
        );
      case explorerRoute:
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BasketExplorer(
            userId: userId,
            portfolioId: portfolioId,
            showInlineToggle: showInlineToggle,
          ),
        );
    }
  }

  static void _persistPreview({
    required String userId,
    required String portfolioId,
    required String etfIsin,
    String? draftId,
  }) {
    SessionPersistenceService.instance.patch(
      userId,
      (s) => s.copyWith(
        globalNav: 'Portfolio',
        portfolioTabIndex: basketsTabIndex,
        portfolioId: portfolioId,
        basket: BasketSessionState(
          route: previewRoute,
          etfIsin: etfIsin,
          userId: userId,
          portfolioId: portfolioId,
          draftId: draftId,
        ),
      ),
    );
  }

  static void _persistCreator({
    required String userId,
    required String portfolioId,
    required String etfIsin,
    String? draftId,
  }) {
    SessionPersistenceService.instance.patch(
      userId,
      (s) => s.copyWith(
        globalNav: 'Portfolio',
        portfolioTabIndex: basketsTabIndex,
        portfolioId: portfolioId,
        basket: BasketSessionState(
          route: creatorRoute,
          etfIsin: etfIsin,
          userId: userId,
          portfolioId: portfolioId,
          draftId: draftId,
        ),
      ),
    );
  }

  static void openDashboard(
    BuildContext context, {
    required String basketId,
    required String userId,
    required String portfolioId,
    bool fromCreationFlow = false,
  }) {
    final args = {
      'basketId': basketId,
      'userId': userId,
    };

    final nested = navigatorKey.currentState;
    if (nested != null) {
      if (fromCreationFlow) {
        nested.popUntil(
          (route) =>
              route.settings.name == explorerRoute || route.isFirst,
        );
      }
      nested.pushNamed(dashboardRoute, arguments: args);
      return;
    }

    if (GoRouter.maybeOf(context) != null) {
      context.push('/portfolio/basket/dashboard', extra: args);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BasketDashboardPage(
          basketId: basketId,
          userId: userId,
          embedded: false,
        ),
      ),
    );
  }

  static VoidCallback? _showMyBasketsListener;

  /// BasketExplorer registers this to switch to the My Baskets tab when requested.
  static void registerMyBasketsListener(VoidCallback listener) {
    _showMyBasketsListener = listener;
  }

  static void unregisterMyBasketsListener() {
    _showMyBasketsListener = null;
  }

  static void _notifyShowMyBaskets() {
    setViewMode(BasketViewMode.myBaskets);
    _showMyBasketsListener?.call();
  }

  /// Pop nested basket flow back to explorer and show My Baskets tab.
  static void returnToMyBaskets(
    BuildContext context, {
    required String userId,
  }) {
    clearBasketSession(userId);

    final nested = navigatorKey.currentState;
    if (nested != null) {
      nested.popUntil(
        (route) =>
            route.settings.name == explorerRoute || route.isFirst,
      );
      _notifyShowMyBaskets();
      return;
    }

    if (GoRouter.maybeOf(context) != null) {
      context.go('/portfolio/baskets');
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Resume a saved draft on Customize (skip Preview).
  static void openCreatorFromDraft(
    BuildContext context, {
    required BasketOpportunity opportunity,
    required String userId,
    required String portfolioId,
    String? draftId,
  }) {
    final args = BasketCreatorArgs(
      opportunity: opportunity,
      userId: userId,
      portfolioId: portfolioId,
    );

    _persistCreator(
      userId: userId,
      portfolioId: portfolioId,
      etfIsin: opportunity.etfIsin,
      draftId: draftId,
    );

    final nested = navigatorKey.currentState;
    if (nested != null) {
      nested.popUntil(
        (route) =>
            route.settings.name == explorerRoute || route.isFirst,
      );
      nested.pushNamed(creatorRoute, arguments: args);
      _notifyShowMyBaskets();
      return;
    }

    if (GoRouter.maybeOf(context) != null) {
      context.push('/portfolio/basket/creator', extra: args.toMap());
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManualBasketCreatorPage(
          opportunity: opportunity,
          userId: userId,
          portfolioId: portfolioId,
        ),
      ),
    );
  }

  static void clearBasketSession(String userId) {
    SessionPersistenceService.instance.patch(
      userId,
      (s) => s.copyWith(clearBasket: true),
    );
  }

  static void openPreview(
    BuildContext context, {
    required String etfIsin,
    required String userId,
    required String portfolioId,
    BasketOpportunity? opportunity,
    BasketOpportunity? seededOpportunity,
  }) {
    if (etfIsin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ETF ISIN is missing for this opportunity')),
      );
      return;
    }

    final seed = seededOpportunity ?? opportunity;
    final args = BasketPreviewArgs(
      etfIsin: etfIsin,
      userId: userId,
      portfolioId: portfolioId,
      seededOpportunity: seed,
    );

    _persistPreview(
      userId: userId,
      portfolioId: portfolioId,
      etfIsin: etfIsin,
    );

    final nested = navigatorKey.currentState;
    if (nested != null) {
      nested.pushNamed(previewRoute, arguments: args);
      return;
    }

    if (GoRouter.maybeOf(context) != null) {
      context.push('/portfolio/basket/preview', extra: args.toMap());
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BasketPreviewPage(
          etfIsin: etfIsin,
          userId: userId,
          portfolioId: portfolioId,
          seededOpportunity: seed,
        ),
      ),
    );
  }

  static void openCreator(
    BuildContext context, {
    required BasketOpportunity opportunity,
    required String userId,
    required String portfolioId,
    String? draftId,
  }) {
    final args = BasketCreatorArgs(
      opportunity: opportunity,
      userId: userId,
      portfolioId: portfolioId,
    );

    _persistCreator(
      userId: userId,
      portfolioId: portfolioId,
      etfIsin: opportunity.etfIsin,
      draftId: draftId,
    );

    final nested = navigatorKey.currentState;
    if (nested != null) {
      nested.pushNamed(creatorRoute, arguments: args);
      return;
    }

    if (GoRouter.maybeOf(context) != null) {
      context.push('/portfolio/basket/creator', extra: args.toMap());
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManualBasketCreatorPage(
          opportunity: opportunity,
          userId: userId,
          portfolioId: portfolioId,
        ),
      ),
    );
  }

  static void openFinalPreview(
    BuildContext context, {
    required BasketFinalPreviewArgs args,
  }) {
    final nested = navigatorKey.currentState;
    if (nested != null) {
      nested.pushNamed(finalPreviewRoute, arguments: args);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BasketFinalPreviewPage(args: args),
      ),
    );
  }
}

class BasketPreviewArgs {
  const BasketPreviewArgs({
    required this.etfIsin,
    required this.userId,
    required this.portfolioId,
    BasketOpportunity? opportunity,
    BasketOpportunity? seededOpportunity,
  }) : seededOpportunity = seededOpportunity ?? opportunity;

  final String etfIsin;
  final String userId;
  final String portfolioId;
  final BasketOpportunity? seededOpportunity;

  BasketOpportunity? get opportunity => seededOpportunity;

  Map<String, dynamic> toMap() => {
        'etfIsin': etfIsin,
        'userId': userId,
        'portfolioId': portfolioId,
        if (seededOpportunity != null) 'seededOpportunity': seededOpportunity,
        if (opportunity != null) 'opportunity': opportunity,
      };

  factory BasketPreviewArgs.fromMap(Map<String, dynamic> map) {
    final seed = map['seededOpportunity'] ?? map['opportunity'];
    return BasketPreviewArgs(
      etfIsin: map['etfIsin'] as String,
      userId: map['userId'] as String,
      portfolioId: map['portfolioId'] as String,
      seededOpportunity: seed as BasketOpportunity?,
    );
  }
}

class BasketCreatorArgs {
  const BasketCreatorArgs({
    required this.opportunity,
    required this.userId,
    required this.portfolioId,
  });

  final BasketOpportunity opportunity;
  final String userId;
  final String portfolioId;

  Map<String, dynamic> toMap() => {
        'opportunity': opportunity,
        'userId': userId,
        'portfolioId': portfolioId,
      };
}

class BasketFinalPreviewArgs {
  const BasketFinalPreviewArgs({
    required this.originalOpportunity,
    required this.finalOpportunity,
    required this.finalItems,
    required this.investmentAmount,
    required this.basketName,
    required this.userId,
    required this.portfolioId,
    required this.excludedItems,
    required this.idempotencyKey,
    this.trustCustomizeOutput = false,
    this.draftId,
  });

  final BasketOpportunity originalOpportunity;
  final BasketOpportunity finalOpportunity;
  final List<BasketItem> finalItems;
  final double investmentAmount;
  final String basketName;
  final String userId;
  final String portfolioId;
  final Set<String> excludedItems;
  final String idempotencyKey;
  final bool trustCustomizeOutput;
  final String? draftId;
}

class _BasketNavigatorObserver extends NavigatorObserver {
  _BasketNavigatorObserver(this.userId);
  final String userId;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final prevName = previousRoute?.settings.name;
    // Only clear when returning to explorer. Creator→preview must keep session.
    if (prevName == BasketNavigation.explorerRoute ||
        (previousRoute?.isFirst == true &&
            prevName != BasketNavigation.previewRoute &&
            prevName != BasketNavigation.creatorRoute &&
            prevName != BasketNavigation.finalPreviewRoute &&
            prevName != BasketNavigation.dashboardRoute)) {
      if (route.settings.name == BasketNavigation.previewRoute ||
          route.settings.name == BasketNavigation.creatorRoute ||
          route.settings.name == BasketNavigation.finalPreviewRoute) {
        BasketNavigation.clearBasketSession(userId);
      }
      return;
    }

    // Re-persist preview when popping creator back onto preview.
    if (route.settings.name == BasketNavigation.creatorRoute &&
        prevName == BasketNavigation.previewRoute) {
      final args = previousRoute?.settings.arguments;
      if (args is BasketPreviewArgs) {
        BasketNavigation._persistPreview(
          userId: args.userId,
          portfolioId: args.portfolioId,
          etfIsin: args.etfIsin,
        );
      }
    }
  }
}

/// Hosts basket explorer / preview / creator inside the portfolio body pane.
class BasketSectionNavigator extends ConsumerStatefulWidget {
  const BasketSectionNavigator({
    super.key,
    required this.userId,
    required this.portfolioId,
    this.showInlineToggle = false,
  });

  final String userId;
  final String portfolioId;

  /// Web: true for Smart Baskets + Discover/My Baskets header.
  /// Mobile: false — toggle lives in portfolio sticky header.
  final bool showInlineToggle;

  @override
  ConsumerState<BasketSectionNavigator> createState() =>
      _BasketSectionNavigatorState();
}

class _BasketSectionNavigatorState
    extends ConsumerState<BasketSectionNavigator> {
  bool _restored = false;
  late final _BasketNavigatorObserver _observer;

  @override
  void initState() {
    super.initState();
    _observer = _BasketNavigatorObserver(widget.userId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreBasketRoute());
  }

  Future<void> _restoreBasketRoute() async {
    if (_restored) return;
    _restored = true;

    final session = SessionPersistenceService.instance.cached ??
        await SessionPersistenceService.instance.load(widget.userId);
    final basket = session?.basket;
    if (basket == null || basket.route == BasketNavigation.explorerRoute) {
      return;
    }

    final nav = BasketNavigation.navigatorKey.currentState;
    if (nav == null || !mounted) return;

    if (basket.route == BasketNavigation.creatorRoute &&
        basket.draftId != null &&
        basket.draftId!.isNotEmpty) {
      try {
        final repository = await ref.read(basketRepositoryProvider.future);
        final detail = await repository.getDraft(
          draftId: basket.draftId!,
          userId: widget.userId,
        );
        final opportunity = detail.opportunity;
        if (opportunity == null || !mounted) return;
        ref.read(basketFlowControllerProvider.notifier).restoreFromDraft(
              opportunity: opportunity,
              excludedSymbols: detail.excludedSymbols.toSet(),
              manualQtyOverrides: detail.manualQtyOverrides,
              investmentAmount: detail.investmentAmount ?? 0,
              basketName: detail.basketName ??
                  'My ${detail.etfName ?? 'ETF'} Basket',
              hasCalculated: detail.hasCalculated,
              draftId: detail.id,
            );
        nav.pushNamed(
          BasketNavigation.creatorRoute,
          arguments: BasketCreatorArgs(
            opportunity: opportunity,
            userId: widget.userId,
            portfolioId: widget.portfolioId,
          ),
        );
        return;
      } catch (_) {
        // Fall through to preview restore.
      }
    }

    if ((basket.route == BasketNavigation.previewRoute ||
            basket.route == BasketNavigation.creatorRoute) &&
        basket.etfIsin != null &&
        basket.etfIsin!.isNotEmpty) {
      nav.pushNamed(
        BasketNavigation.previewRoute,
        arguments: BasketPreviewArgs(
          etfIsin: basket.etfIsin!,
          userId: widget.userId,
          portfolioId: widget.portfolioId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: BasketNavigation.navigatorKey,
      initialRoute: BasketNavigation.explorerRoute,
      observers: [_observer],
      onGenerateRoute: (settings) => BasketNavigation.onGenerateRoute(
        settings,
        userId: widget.userId,
        portfolioId: widget.portfolioId,
        showInlineToggle: widget.showInlineToggle,
      ),
    );
  }
}
