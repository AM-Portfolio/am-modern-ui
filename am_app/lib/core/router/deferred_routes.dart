import 'package:am_analysis_ui/services/real_analysis_service.dart'
    deferred as analysis_svc;
import 'package:am_analysis_ui/widgets/analysis_dashboard.dart'
    deferred as analysis_ui;
import 'package:am_analysis_core/am_analysis_core.dart' show AnalysisEntityType;
import 'package:am_ai_ui/presentation/screens/ai_chat_screen.dart' as ai_ui;
import 'package:am_diagnostic_ui/presentation/pages/diagnostic_dashboard_page.dart'
    deferred as diagnostic_ui;
import 'package:am_doc_intelligence_ui/features/doc_intelligence_screen.dart'
    deferred as doc_intel_ui;
import 'package:am_market_ui/features/dashboard/presentation/pages/dashboard_page.dart'
    deferred as market_ui;
import 'package:am_market_ui/features/market_analysis/services/market_analysis_service.dart'
    deferred as market_deps;
import 'package:am_paper_ui/am_paper_ui.dart' deferred as paper_ui;
import 'package:am_portfolio_ui/features/portfolio/presentation/pages/portfolio_screen.dart'
    deferred as portfolio_pages;
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/global_portfolio_wrapper.dart'
    deferred as portfolio_shell;
import 'package:am_portfolio_ui/features/portfolio/presentation/web/pages/portfolio_holdings_web_page.dart'
    deferred as portfolio_holdings;
import 'package:am_trade_ui/features/trade/presentation/add_trade/pages/add_trade_web_page.dart'
    deferred as trade_add;
import 'package:am_trade_ui/features/trade/presentation/trade_responsive_layout.dart'
    deferred as trade_ui;
import 'package:am_trade_ui/features/trade/providers/trade_controller_providers.dart'
    deferred as trade_providers;
import 'package:am_user_ui/am_user_ui.dart' deferred as user_ui;
import 'package:am_subscription_ui/am_subscription_ui.dart' as am_sub;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../../features/shell/skeletons/module_skeletons.dart';
import '../di/injection.dart';
import 'deferred_module_loader.dart';

Future<void> _ensureFeatureDi() => configureFeatureDependencies();

Future<void> _loadPortfolioLibraries() => Future.wait([
      portfolio_pages.loadLibrary(),
      portfolio_shell.loadLibrary(),
      portfolio_holdings.loadLibrary(),
    ]);

Future<void> _loadPortfolio() async {
  await _ensureFeatureDi();
  await Future.wait([
    _loadPortfolioLibraries(),
    trade_ui.loadLibrary(),
    trade_add.loadLibrary(),
    trade_providers.loadLibrary(),
  ]);
}

typedef PortfolioAddTradeBuilder = Widget Function(
  BuildContext context,
  String portfolioId,
  String? portfolioName,
  VoidCallback onComplete,
);

typedef PortfolioHoldingsPageBuilder = Widget Function(
  BuildContext context,
  String portfolioId,
);

Widget _defaultPortfolioAddTradeBuilder(
  BuildContext context,
  String portfolioId,
  String? portfolioName,
  VoidCallback onComplete,
) {
  return Consumer(
    builder: (context, ref, _) {
      final cubitAsync = ref.watch(trade_providers.tradeControllerCubitProvider);
      return cubitAsync.when(
        data: (cubit) => BlocProvider.value(
          value: cubit,
          child: trade_add.AddTradeWebPage(
            portfolioId: portfolioId,
            portfolioName: portfolioName,
            onTradeAdded: onComplete,
            onCancel: onComplete,
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      );
    },
  );
}

Widget _defaultPortfolioHoldingsPageBuilder(
  BuildContext context,
  String portfolioId,
) {
  return portfolio_holdings.PortfolioHoldingsWebPage(
    portfolioId: portfolioId,
  );
}

Future<void> _loadTrade() async {
  await _ensureFeatureDi();
  await Future.wait([
    _loadPortfolioLibraries(),
    trade_ui.loadLibrary(),
  ]);
}

Future<void> _loadMarket() async {
  await _ensureFeatureDi();
  await Future.wait([
    market_ui.loadLibrary(),
    market_deps.loadLibrary(),
    paper_ui.loadLibrary(),
  ]);
  market_deps.registerMarketAnalysisServiceDi();
}

Future<void> _loadAnalysis() async {
  await Future.wait([
    analysis_ui.loadLibrary(),
    analysis_svc.loadLibrary(),
  ]);
}

Future<void> _loadDocIntel() => doc_intel_ui.loadLibrary();

Future<void> _loadUser() => user_ui.loadLibrary();

Future<void> _loadDiagnostic() => diagnostic_ui.loadLibrary();

Widget buildPortfolioRoute({
  required String? portfolioId,
  required String tab,
  required void Function(String slug) onTabChanged,
  required void Function(String id, String name) onPortfolioChanged,
  PortfolioAddTradeBuilder? addTradeBuilder,
  PortfolioHoldingsPageBuilder? holdingsPageBuilder,
  VoidCallback? onOpenDocIntel,
  Widget Function(String portfolioId, String? portfolioName, VoidCallback onCancel)? uploadPortfolioBuilder,
}) {
  final tradeBuilder = addTradeBuilder ?? _defaultPortfolioAddTradeBuilder;
  final holdingsBuilder =
      holdingsPageBuilder ?? _defaultPortfolioHoldingsPageBuilder;
  return DeferredModuleLoader(
    load: _loadPortfolio,
    skeleton: const PortfolioModuleSkeleton(),
    loadingMessage: 'Loading Portfolio…',
    builder: () => portfolio_shell.GlobalPortfolioWrapper(
      streamingTab: 'Portfolio',
      onPortfolioChanged: onPortfolioChanged,
      child: portfolio_pages.PortfolioScreen(
        initialPortfolioId: portfolioId,
        initialTab: tab,
        onTabChanged: onTabChanged,
        onPortfolioChanged: onPortfolioChanged,
        addTradeBuilder: tradeBuilder,
        holdingsPageBuilder: holdingsBuilder,
        onOpenDocIntel: onOpenDocIntel,
        uploadPortfolioBuilder: uploadPortfolioBuilder,
      ),
    ),
  );
}

Widget buildTradeDiscoveryRoute({
  required void Function(String slug) onTabChanged,
  required void Function(String id, String name) onPortfolioChanged,
}) {
  return DeferredModuleLoader(
    load: _loadTrade,
    skeleton: const TradeModuleSkeleton(),
    loadingMessage: 'Loading Trade…',
    builder: () => portfolio_shell.GlobalPortfolioWrapper(
      streamingTab: 'Trade',
      onPortfolioChanged: onPortfolioChanged,
      child: trade_ui.TradeResponsiveLayout(
        initialTab: 'portfolios',
        onTabChanged: onTabChanged,
        onPortfolioChanged: onPortfolioChanged,
      ),
    ),
  );
}

Widget buildTradePortfolioRoute({
  required String portfolioId,
  required String tab,
  required void Function(String slug) onTabChanged,
  required void Function(String id, String name) onPortfolioChanged,
}) {
  return DeferredModuleLoader(
    load: _loadTrade,
    skeleton: const TradeModuleSkeleton(),
    loadingMessage: 'Loading Trade…',
    builder: () => portfolio_shell.GlobalPortfolioWrapper(
      streamingTab: 'Trade',
      onPortfolioChanged: onPortfolioChanged,
      child: trade_ui.TradeResponsiveLayout(
        initialPortfolioId: portfolioId,
        initialTab: tab,
        onTabChanged: onTabChanged,
        onPortfolioChanged: onPortfolioChanged,
      ),
    ),
  );
}

Widget buildTradeLegacyTabRoute({
  required String tab,
  required void Function(String slug) onTabChanged,
  required void Function(String id, String name) onPortfolioChanged,
}) {
  return DeferredModuleLoader(
    load: _loadTrade,
    skeleton: const TradeModuleSkeleton(),
    loadingMessage: 'Loading Trade…',
    builder: () => portfolio_shell.GlobalPortfolioWrapper(
      streamingTab: 'Trade',
      onPortfolioChanged: onPortfolioChanged,
      child: trade_ui.TradeResponsiveLayout(
        initialTab: tab,
        onTabChanged: onTabChanged,
        onPortfolioChanged: onPortfolioChanged,
      ),
    ),
  );
}

Widget buildMarketRoute({
  required String userId,
  required String tab,
  required void Function(String slug) onTabChanged,
}) {
  return DeferredModuleLoader(
    load: _loadMarket,
    skeleton: const MarketModuleSkeleton(),
    loadingMessage: 'Loading Market…',
    builder: () => market_ui.MarketPage(
      userId: userId,
      initialTab: tab,
      onTabChanged: onTabChanged,
      paperDesk: paper_ui.PaperGateScreen(),
    ),
  );
}

Widget buildAiChatRoute({required String userId, String? displayName}) {
  return ai_ui.AiChatScreen(userId: userId, displayName: displayName);
}

Widget buildLabRoute() {
  return DeferredModuleLoader(
    load: _loadDiagnostic,
    skeleton: const GenericModuleSkeleton(),
    loadingMessage: 'Loading Lab…',
    builder: () => diagnostic_ui.DiagnosticDashboardPage(),
  );
}

Widget buildAnalysisRoute({required String userId}) {
  return DeferredModuleLoader(
    load: _loadAnalysis,
    skeleton: const GenericModuleSkeleton(),
    loadingMessage: 'Loading Analysis…',
    builder: () => analysis_ui.AnalysisDashboard(
      entityType: AnalysisEntityType.PORTFOLIO,
      entityId: userId,
      analysisService: analysis_svc.RealAnalysisService(),
    ),
  );
}

Widget buildDocIntelRoute({
  required String userId,
  String tab = 'doc-processor',
  ValueChanged<String>? onTabChanged,
}) {
  return DeferredModuleLoader(
    load: _loadDocIntel,
    skeleton: const GenericModuleSkeleton(),
    loadingMessage: 'Loading Doc Intel…',
    builder: () => doc_intel_ui.DocIntelligenceScreen(
      userId: userId,
      initialTab: tab,
      onTabChanged: onTabChanged,
    ),
  );
}

Widget buildProfileRoute({
  required String userId,
  String? email,
  String? displayName,
  String? photoUrl,
  VoidCallback? onOpenPrivacyPolicy,
  VoidCallback? onOpenTermsOfService,
  VoidCallback? onOpenSubscription,
  VoidCallback? onOpenReferral,
  VoidCallback? onOpenActiveSessions,
  VoidCallback? onOpenScanWebLogin,
  bool highlightSubscription = false,
}) {
  return DeferredModuleLoader(
    load: _loadUser,
    skeleton: const GenericModuleSkeleton(),
    loadingMessage: 'Loading Profile…',
    builder: () => _ProfileSubscriptionLoader(
      builder: (statusLabel, isPaid, referralLabel) => user_ui.ProfileSettingsPage(
        userId: userId,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        onOpenPrivacyPolicy: onOpenPrivacyPolicy,
        onOpenTermsOfService: onOpenTermsOfService,
        onOpenSubscription: onOpenSubscription,
        onOpenReferral: onOpenReferral,
        onOpenActiveSessions: onOpenActiveSessions,
        onOpenScanWebLogin: onOpenScanWebLogin,
        highlightSubscription: highlightSubscription,
        subscriptionStatusLabel: statusLabel,
        isPaidSubscription: isPaid,
        referralStatusLabel: referralLabel,
      ),
    ),
  );
}

Widget buildActiveSessionsRoute({VoidCallback? onOpenSecuritySettings}) {
  return DeferredModuleLoader(
    load: _loadUser,
    skeleton: const GenericModuleSkeleton(),
    loadingMessage: 'Loading sessions…',
    builder: () => user_ui.ActiveSessionsPage(
      onOpenSecuritySettings: onOpenSecuritySettings,
    ),
  );
}

/// Loads subscription + referral status labels for Profile Account tiles.
class _ProfileSubscriptionLoader extends StatefulWidget {
  const _ProfileSubscriptionLoader({required this.builder});

  final Widget Function(
    String? statusLabel,
    bool isPaid,
    String? referralLabel,
  ) builder;

  @override
  State<_ProfileSubscriptionLoader> createState() =>
      _ProfileSubscriptionLoaderState();
}

class _ProfileSubscriptionLoaderState extends State<_ProfileSubscriptionLoader> {
  String? _statusLabel;
  bool _isPaid = false;
  String? _referralLabel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([_loadSubscription(), _loadReferral()]);
  }

  Future<void> _loadSubscription() async {
    try {
      if (!GetIt.instance.isRegistered<am_sub.SubscriptionCubit>()) {
        return;
      }
      final cubit = GetIt.instance<am_sub.SubscriptionCubit>();
      await cubit.ensureSubscriptionStatus();
      if (!mounted) return;
      setState(() {
        _statusLabel = cubit.statusLabel;
        _isPaid = cubit.isPaidSubscription;
      });
    } catch (_) {
      // Leave default Profile copy if subscription API fails.
    }
  }

  Future<void> _loadReferral() async {
    try {
      if (!GetIt.instance.isRegistered<am_sub.SubscriptionRemoteDataSource>()) {
        return;
      }
      final summary = await GetIt.instance<am_sub.SubscriptionRemoteDataSource>()
          .getReferralSummary();
      if (!mounted) return;
      setState(() {
        _referralLabel =
            '${summary.qualifiedCount} of ${summary.lifetimeCap} successful · '
            'up to 6 months Pro';
      });
    } catch (_) {
      // Leave default invite copy if referral API fails.
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(_statusLabel, _isPaid, _referralLabel);
}

Widget buildPrivacyPolicyRoute({
  VoidCallback? onBack,
  VoidCallback? onOpenTerms,
}) {
  return DeferredModuleLoader(
    load: _loadUser,
    skeleton: const GenericModuleSkeleton(),
    loadingMessage: 'Loading Privacy Policy…',
    builder: () => user_ui.PrivacyPolicyPage(
      onBack: onBack,
      onOpenTerms: onOpenTerms,
    ),
  );
}

Widget buildTermsOfServiceRoute({
  VoidCallback? onBack,
  VoidCallback? onOpenPrivacy,
}) {
  return DeferredModuleLoader(
    load: _loadUser,
    skeleton: const GenericModuleSkeleton(),
    loadingMessage: 'Loading Terms of Service…',
    builder: () => user_ui.TermsOfServicePage(
      onBack: onBack,
      onOpenPrivacy: onOpenPrivacy,
    ),
  );
}
