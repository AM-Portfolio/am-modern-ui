import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:am_common/am_common.dart';
import '../domain/models/basket_opportunity.dart';
import 'pages/basket_preview_page.dart';
import 'pages/manual_basket_creator_page.dart';
import 'widgets/basket_explorer.dart';

/// Nested basket navigation inside portfolio content (keeps global + secondary sidebars).
class BasketNavigation {
  BasketNavigation._();

  static const String explorerRoute = '/';
  static const String previewRoute = '/preview';
  static const String creatorRoute = '/creator';
  static const int basketsTabIndex = 4;

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static bool get hasNestedNavigator => navigatorKey.currentState != null;

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    required String userId,
    required String portfolioId,
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
      case explorerRoute:
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BasketExplorer(
            portfolioId: portfolioId,
          ),
        );
    }
  }

  static void _persistPreview({
    required String userId,
    required String portfolioId,
    required String etfIsin,
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
        ),
      ),
    );
  }

  static void _persistCreator({
    required String userId,
    required String portfolioId,
    required String etfIsin,
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
  }) {
    if (etfIsin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ETF ISIN is missing for this opportunity')),
      );
      return;
    }

    final args = BasketPreviewArgs(
      etfIsin: etfIsin,
      userId: userId,
      portfolioId: portfolioId,
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
        ),
      ),
    );
  }

  static void openCreator(
    BuildContext context, {
    required BasketOpportunity opportunity,
    required String userId,
    required String portfolioId,
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
}

class BasketPreviewArgs {
  const BasketPreviewArgs({
    required this.etfIsin,
    required this.userId,
    required this.portfolioId,
  });

  final String etfIsin;
  final String userId;
  final String portfolioId;

  Map<String, dynamic> toMap() => {
        'etfIsin': etfIsin,
        'userId': userId,
        'portfolioId': portfolioId,
      };

  factory BasketPreviewArgs.fromMap(Map<String, dynamic> map) {
    return BasketPreviewArgs(
      etfIsin: map['etfIsin'] as String,
      userId: map['userId'] as String,
      portfolioId: map['portfolioId'] as String,
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

class _BasketNavigatorObserver extends NavigatorObserver {
  _BasketNavigatorObserver(this.userId);
  final String userId;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name == BasketNavigation.previewRoute ||
        route.settings.name == BasketNavigation.creatorRoute) {
      BasketNavigation.clearBasketSession(userId);
    }
  }
}

/// Hosts basket explorer / preview / creator inside the portfolio body pane.
class BasketSectionNavigator extends StatefulWidget {
  const BasketSectionNavigator({
    super.key,
    required this.userId,
    required this.portfolioId,
  });

  final String userId;
  final String portfolioId;

  @override
  State<BasketSectionNavigator> createState() => _BasketSectionNavigatorState();
}

class _BasketSectionNavigatorState extends State<BasketSectionNavigator> {
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

    if (basket.route == BasketNavigation.previewRoute &&
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
      ),
    );
  }
}
