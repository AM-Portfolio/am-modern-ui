import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:am_common/am_common.dart';
import '../../cubit/portfolio_cubit.dart';
import '../../cubit/portfolio_heatmap_cubit.dart';
import '../../cubit/portfolio_state.dart';
import '../../widgets/portfolio_summary_widget.dart';
import '../pages/portfolio_heatmap_mobile_page.dart';
import '../portfolio_analysis_widget.dart';
import 'portfolio_holdings_widget.dart';
import '../pages/trade_portfolio_list_mobile_page.dart';

/// Widget that handles portfolio tab content based on state
class PortfolioTabContentWidget extends ConsumerWidget {
  const PortfolioTabContentWidget({
    required this.tabController,
    required this.currentPortfolioId,
    required this.userId,
    super.key,
  });
  final TabController tabController;
  final String currentPortfolioId;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      BlocBuilder<PortfolioCubit, PortfolioState>(
        builder: (context, state) => TabBarView(
          controller: tabController,
          children: [
            _OverviewTab(currentPortfolioId: currentPortfolioId, userId: userId),
            _HoldingsTab(currentPortfolioId: currentPortfolioId, userId: userId),
            _AnalysisTab(currentPortfolioId: currentPortfolioId, userId: userId),
            _HeatmapTab(currentPortfolioId: currentPortfolioId, userId: userId),
            _TradeTab(userId: userId, ref: ref),
          ],
        ),
      );
}

/// Overview tab widget
class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.currentPortfolioId, required this.userId});
  final String currentPortfolioId;
  final String userId;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PortfolioCubit, PortfolioState>(
        builder: (context, state) {
          if (state is PortfolioLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PortfolioError) {
            return _buildErrorWithRefresh(
              context,
              state.message,
              'Pull to Refresh Portfolio',
            );
          }

          if (state is PortfolioLoaded) {
            return _buildOverviewContent(context, state);
          }

          return _buildLoadingWithRefresh(context, 'Pull to Refresh Portfolio');
        },
      );

  Widget _buildOverviewContent(BuildContext context, PortfolioLoaded state) {
    final summary = state.summary;

    CommonLogger.debug(
      'Building overview with summary - totalValue: ${summary.totalValue}, todayChange: ${summary.todayChange}, totalGainLoss: ${summary.totalGainLoss}',
      tag: 'PortfolioOverviewTab',
    );

    return RefreshIndicator(
      onRefresh: () => _refreshPortfolio(context, 'Pull to Refresh Overview'),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: PortfolioSummaryWidget(
          summary: summary,
          onViewHoldings: () => _navigateToTab(1, context),
          onViewAnalysis: () => _navigateToTab(2, context),
        ),
      ),
    );
  }

  Widget _buildErrorWithRefresh(
    BuildContext context,
    String message,
    String logAction,
  ) => RefreshIndicator(
    onRefresh: () => _refreshPortfolio(context, logAction),
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: PortfolioErrorWidget(
          message: message,
          onRetry: () => _refreshPortfolio(context, logAction),
        ),
      ),
    ),
  );

  Widget _buildLoadingWithRefresh(BuildContext context, String logAction) =>
      RefreshIndicator(
        onRefresh: () => _refreshPortfolio(context, logAction),
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: Center(child: Text('Loading portfolio...')),
          ),
        ),
      );

  Future<void> _refreshPortfolio(BuildContext context, String action) async {
    CommonLogger.userAction(
      action,
      tag: 'PortfolioOverviewTab',
      metadata: {'portfolioId': currentPortfolioId, 'userId': userId},
    );
    context.read<PortfolioCubit>().refreshPortfolioById(
      userId,
      currentPortfolioId,
    );
  }

  void _navigateToTab(int index, BuildContext context) {
    // Find the tab controller from the widget tree
    final tabController = DefaultTabController.of(context);
    tabController.animateTo(index);
  }
}

/// Holdings tab widget
class _HoldingsTab extends StatelessWidget {
  const _HoldingsTab({required this.currentPortfolioId, required this.userId});
  final String currentPortfolioId;
  final String userId;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PortfolioCubit, PortfolioState>(
        builder: (context, state) {
          if (state is PortfolioLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PortfolioError) {
            return _buildErrorWithRefresh(context, state.message);
          }

          return PortfolioHoldingsWidget(
            userId: userId,
            portfolioId: currentPortfolioId,
          );
        },
      );

  Widget _buildErrorWithRefresh(BuildContext context, String message) =>
      RefreshIndicator(
        onRefresh: () => _refreshPortfolio(context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: PortfolioErrorWidget(
              message: message,
              onRetry: () => _refreshPortfolio(context),
            ),
          ),
        ),
      );

  Future<void> _refreshPortfolio(BuildContext context) async {
    CommonLogger.userAction(
      'Pull to Refresh Holdings',
      tag: 'PortfolioHoldingsTab',
      metadata: {'portfolioId': currentPortfolioId, 'userId': userId},
    );
    context.read<PortfolioCubit>().refreshPortfolioById(
      userId,
      currentPortfolioId,
    );
  }
}

/// Analysis tab widget
class _AnalysisTab extends StatelessWidget {
  const _AnalysisTab({required this.currentPortfolioId, required this.userId});
  final String currentPortfolioId;
  final String userId;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PortfolioCubit, PortfolioState>(
        builder: (context, state) {
          if (state is PortfolioLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PortfolioError) {
            return _buildErrorWithRefresh(context, state.message);
          }

          return RefreshIndicator(
            onRefresh: () => _refreshPortfolio(context),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: PortfolioAnalysisWidget(portfolioId: currentPortfolioId),
            ),
          );
        },
      );

  Widget _buildErrorWithRefresh(BuildContext context, String message) =>
      RefreshIndicator(
        onRefresh: () => _refreshPortfolio(context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: PortfolioErrorWidget(
              message: message,
              onRetry: () => _refreshPortfolio(context),
            ),
          ),
        ),
      );

  Future<void> _refreshPortfolio(BuildContext context) async {
    CommonLogger.userAction(
      'Pull to Refresh Analysis',
      tag: 'PortfolioAnalysisTab',
      metadata: {'portfolioId': currentPortfolioId, 'userId': userId},
    );
    context.read<PortfolioCubit>().refreshPortfolioById(
      userId,
      currentPortfolioId,
    );
  }
}

/// Heatmap tab widget using the new mobile heatmap page
class _HeatmapTab extends StatelessWidget {
  const _HeatmapTab({required this.currentPortfolioId, required this.userId});
  final String currentPortfolioId;
  final String userId;

  @override
  Widget build(BuildContext context) => BlocProvider<PortfolioHeatmapCubit>(
    create: (context) => PortfolioHeatmapCubit(),
    child: PortfolioHeatmapMobilePage(
      userId: userId,
      portfolioId: currentPortfolioId,
      portfolioName: _getPortfolioName(context),
    ),
  );

  /// Get portfolio name from the current portfolio state
  String? _getPortfolioName(BuildContext context) => 'Heatmap';
}

/// Trade tab widget using the trade mobile page with Riverpod
class _TradeTab extends StatelessWidget {
  const _TradeTab({required this.userId, required this.ref});
  final String userId;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return TradePortfolioListMobilePage(userId: userId);
  }
}

/// Reusable error widget for portfolio tabs
class PortfolioErrorWidget extends StatelessWidget {
  const PortfolioErrorWidget({
    required this.message,
    required this.onRetry,
    super.key,
  });
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text('Error', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

