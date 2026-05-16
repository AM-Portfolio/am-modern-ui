import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_state.dart';
import '../../providers/portfolio_providers.dart';
import '../../internal/domain/entities/portfolio_list.dart';
import 'package:am_common/am_common.dart';
import '../mobile/portfolio_mobile_screen.dart';
import '../web/portfolio_web_screen.dart';
import 'global_portfolio_wrapper.dart';
import 'gmail_sync/gmail_connect_button.dart';

/// Wrapper widget that handles portfolio list loading and selection
/// Provides portfolio selection functionality for both mobile and web screens
class PortfolioListWrapper extends ConsumerStatefulWidget {
  const PortfolioListWrapper({
    required this.userId,
    required this.isMobile,
    super.key,
    this.isSidebarVisible = true,
    this.onToggleSidebar,
    this.onBack,
  });
  final String userId;
  final bool isMobile;
  final bool isSidebarVisible;
  final VoidCallback? onToggleSidebar;
  final VoidCallback? onBack;

  @override
  ConsumerState<PortfolioListWrapper> createState() =>
      _PortfolioListWrapperState();
}

class _PortfolioListWrapperState extends ConsumerState<PortfolioListWrapper> {
  String? selectedPortfolioId;
  String? selectedPortfolioName;

  @override
  void initState() {
    super.initState();
    _logInitialization();
  }

  /// Logs the initialization of the wrapper
  void _logInitialization() {
    CommonLogger.info(
      'PortfolioListWrapper initialized for userId: ${widget.userId}',
      tag: 'PortfolioListWrapper',
    );
  }

  /// Handles portfolio selection change
  void _onPortfolioChanged(String portfolioId, String portfolioName) {
    setState(() {
      selectedPortfolioId = portfolioId;
      selectedPortfolioName = portfolioName;
    });

    CommonLogger.info(
      'Portfolio selection changed to: $portfolioName ($portfolioId)',
      tag: 'PortfolioListWrapper',
    );
  }

  /// Auto-selects the first portfolio if none is selected
  void _autoSelectFirstPortfolio(List<PortfolioItem> portfolios) {
    if (portfolios.isNotEmpty && selectedPortfolioId == null) {
      final firstPortfolio = portfolios.first;
      setState(() {
        selectedPortfolioId = firstPortfolio.portfolioId;
        selectedPortfolioName = firstPortfolio.portfolioName;
      });

      CommonLogger.info(
        'Auto-selected first portfolio: ${firstPortfolio.portfolioName} (${firstPortfolio.portfolioId})',
        tag: 'PortfolioListWrapper',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final portfolioServiceAsync = ref.watch(portfolioServiceProvider);

    return portfolioServiceAsync.when(
      data: _buildWithPortfolioService,
      loading: _buildLoadingScreen,
      error: _buildErrorScreen,
    );
  }

  /// Builds the widget when portfolio service is loaded
  Widget _buildWithPortfolioService(portfolioService) => Builder(
    builder: (context) {
      final listContent = BlocConsumer<PortfolioCubit, PortfolioState>(
        listenWhen: _shouldListenForListChanges,
        listener: _handlePortfolioStateChange,
        buildWhen: _shouldRebuildPortfolioShell,
        builder: _buildPortfolioContent,
      );

      // Reuse cubit from GlobalPortfolioWrapper when present (am_app shell).
      try {
        context.read<PortfolioCubit>();
        return listContent;
      } catch (_) {
        return BlocProvider(
          create: (context) =>
              PortfolioCubit(portfolioService)..loadPortfoliosList(widget.userId),
          child: listContent,
        );
      }
    },
  );

  /// Avoid remounting mobile/web shell on every WebSocket price tick.
  bool _shouldRebuildPortfolioShell(
    PortfolioState previous,
    PortfolioState current,
  ) {
    if (previous.portfolioList == null && current.portfolioList != null) {
      return true;
    }
    if (previous.portfolioList != current.portfolioList) {
      return true;
    }
    if (previous is PortfolioListError || current is PortfolioListError) {
      return true;
    }
    if (previous is PortfolioListLoading && current is! PortfolioListLoading) {
      return true;
    }
    // PortfolioLoaded / PortfolioLoading detail updates: tabs handle via their own BlocBuilders.
    return false;
  }

  bool _shouldListenForListChanges(
    PortfolioState previous,
    PortfolioState current,
  ) =>
      current is PortfolioListLoaded && previous is! PortfolioListLoaded;

  /// Handles portfolio state changes
  void _handlePortfolioStateChange(BuildContext context, PortfolioState state) {
    if (state is PortfolioListLoaded) {
      _autoSelectFirstPortfolio(state.portfolioList!.portfolios);
    } else if (state is PortfolioListError) {
      _handlePortfolioError(context, state.message);
    }
  }

  /// Handles portfolio loading errors
  void _handlePortfolioError(BuildContext context, String message) {
    CommonLogger.error(
      'Failed to load portfolio list: $message',
      tag: 'PortfolioListWrapper',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to load portfolios: $message'),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Builds content based on portfolio state
  Widget _buildPortfolioContent(BuildContext context, PortfolioState state) {
    // If we have a list error and NO list available, show the retry error screen
    if (state is PortfolioListError && state.portfolioList == null) {
      return _buildRetryErrorScreen(context, state.message);
    }

    // If we are loading the list for the first time
    if (state is PortfolioListLoading && state.portfolioList == null) {
      return _buildLoadingScreen();
    }

    // Once we have a portfolio list, we can show the main content
    // This includes PortfolioListLoaded, PortfolioLoaded, PortfolioLoading, and PortfolioError
    if (state.portfolioList != null) {
      return _buildLoadedContent(state.portfolioList!.portfolios);
    }

    // Fallback for initial or any other unexpected state without a list
    return _buildLoadingScreen();
  }

  /// Resolves which portfolio is active (local selection, global wrapper, or cubit).
  String? _resolveSelectedPortfolioId(
    List<PortfolioItem> portfolios,
    PortfolioState state,
  ) {
    if (selectedPortfolioId != null) return selectedPortfolioId;
    final globalId = context.selectedPortfolioId;
    if (globalId != null) return globalId;
    if (state is PortfolioLoaded) return state.portfolioId;
    if (portfolios.isNotEmpty) return portfolios.first.portfolioId;
    return null;
  }

  String? _resolveSelectedPortfolioName(List<PortfolioItem> portfolios) {
    if (selectedPortfolioName != null) return selectedPortfolioName;
    final globalName = context.selectedPortfolioName;
    if (globalName != null) return globalName;
    final id = selectedPortfolioId ?? context.selectedPortfolioId;
    if (id != null) {
      for (final p in portfolios) {
        if (p.portfolioId == id) return p.portfolioName;
      }
    }
    if (portfolios.isNotEmpty) return portfolios.first.portfolioName;
    return null;
  }

  /// Builds content when portfolios are loaded
  Widget _buildLoadedContent(List<PortfolioItem> portfolios) {
    if (portfolios.isEmpty) {
      return _buildEmptyPortfoliosScreen();
    }

    final cubitState = context.read<PortfolioCubit>().state;
    final effectiveId = _resolveSelectedPortfolioId(portfolios, cubitState);
    if (effectiveId == null) {
      return _buildLoadingScreen();
    }

    if (selectedPortfolioId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || selectedPortfolioId != null) return;
        final name = _resolveSelectedPortfolioName(portfolios) ?? '';
        _onPortfolioChanged(effectiveId, name);
      });
    }

    return _buildPortfolioScreen(
      portfolios,
      portfolioId: effectiveId,
      portfolioName: _resolveSelectedPortfolioName(portfolios),
    );
  }

  /// Builds the appropriate portfolio screen (mobile or web)
  Widget _buildPortfolioScreen(
    List<PortfolioItem> portfolios, {
    required String portfolioId,
    String? portfolioName,
  }) {
    if (widget.isMobile) {
      return PortfolioMobileScreen(
        key: ValueKey('portfolio_mobile_$portfolioId'),
        userId: widget.userId,
        selectedPortfolioId: portfolioId,
        selectedPortfolioName: portfolioName,
        portfolios: portfolios,
        onPortfolioChanged: _onPortfolioChanged,
        onBack: widget.onBack,
      );
    } else {
      return PortfolioWebScreen(
        key: ValueKey('portfolio_web_$portfolioId'),
        userId: widget.userId,
        selectedPortfolioId: portfolioId,
        selectedPortfolioName: portfolioName,
        portfolios: portfolios,
        onPortfolioChanged: _onPortfolioChanged,
        isSidebarVisible: widget.isSidebarVisible,
        onToggleSidebar: widget.onToggleSidebar,
      );
    }
  }

  /// Builds loading screen
  Widget _buildLoadingScreen() => const Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading portfolios...'),
        ],
      ),
    ),
  );

  /// Builds error screen with retry functionality
  Widget _buildRetryErrorScreen(BuildContext context, String message) =>
      Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load portfolios'),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _retryLoadPortfolios(context),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );

  /// Builds empty portfolios screen
  Widget _buildEmptyPortfoliosScreen() => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text('No portfolios found'),
          const SizedBox(height: 8),
          const Text('Create a portfolio to get started'),
          const SizedBox(height: 24),
          // Add Gmail Connect button even when no portfolios exist
          const GmailConnectButton(),
        ],
      ),
    ),
  );

  /// Builds error screen for service initialization failure
  Widget _buildErrorScreen(Object error, StackTrace? stack) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Failed to initialize: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(portfolioServiceProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  /// Retries loading portfolios
  void _retryLoadPortfolios(BuildContext context) {
    context.read<PortfolioCubit>().loadPortfoliosList(widget.userId);
  }
}
