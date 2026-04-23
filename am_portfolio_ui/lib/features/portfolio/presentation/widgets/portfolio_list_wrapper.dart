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
  Widget _buildWithPortfolioService(portfolioService) => BlocProvider(
    create: (context) =>
        PortfolioCubit(portfolioService)..loadPortfoliosList(widget.userId),
    child: BlocConsumer<PortfolioCubit, PortfolioState>(
      listener: _handlePortfolioStateChange,
      builder: _buildPortfolioContent,
    ),
  );

  /// Handles portfolio state changes
  void _handlePortfolioStateChange(BuildContext context, PortfolioState state) {
    if (state is PortfolioListLoaded) {
      _autoSelectFirstPortfolio(state.portfolioList.portfolios);
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
    if (state is PortfolioListLoading) {
      return _buildLoadingScreen();
    }

    if (state is PortfolioListError) {
      return _buildRetryErrorScreen(context, state.message);
    }

    if (state is PortfolioListLoaded) {
      return _buildLoadedContent(state.portfolioList.portfolios);
    }

    return _buildLoadingScreen();
  }

  /// Builds content when portfolios are loaded
  Widget _buildLoadedContent(List<PortfolioItem> portfolios) {
    if (portfolios.isEmpty) {
      return _buildEmptyPortfoliosScreen();
    }

    if (selectedPortfolioId != null) {
      return _buildPortfolioScreen(portfolios);
    }

    return _buildLoadingScreen();
  }

  /// Builds the appropriate portfolio screen (mobile or web)
  Widget _buildPortfolioScreen(List<PortfolioItem> portfolios) {
    if (widget.isMobile) {
      return PortfolioMobileScreen(
        userId: widget.userId,
        selectedPortfolioId: selectedPortfolioId,
        selectedPortfolioName: selectedPortfolioName,
        portfolios: portfolios,
        onPortfolioChanged: _onPortfolioChanged,
        onBack: widget.onBack,
      );
    } else {
      return PortfolioWebScreen(
        userId: widget.userId,
        selectedPortfolioId: selectedPortfolioId,
        selectedPortfolioName: selectedPortfolioName,
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

