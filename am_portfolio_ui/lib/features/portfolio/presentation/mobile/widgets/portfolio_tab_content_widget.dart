import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:am_common/am_common.dart';
import '../../cubit/portfolio_cubit.dart';
import '../../cubit/portfolio_heatmap_cubit.dart';
import '../../cubit/portfolio_state.dart';
import '../../widgets/portfolio_overview_widget.dart';
import 'package:am_analysis_ui/am_analysis_ui.dart' hide TimeFrame;
import '../pages/portfolio_heatmap_mobile_page.dart';
import '../portfolio_analysis_widget.dart';
import 'portfolio_holdings_widget.dart';
import '../pages/trade_portfolio_list_mobile_page.dart';

/// Widget that handles portfolio tab content based on state
class PortfolioTabContentWidget extends ConsumerWidget {
  const PortfolioTabContentWidget({
    required this.tabController,
    required this.currentPortfolioId,
    super.key,
  });
  final TabController tabController;
  final String currentPortfolioId;
  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) => TabBarView(
      controller: tabController,
      children: [
        _OverviewTab(currentPortfolioId: currentPortfolioId, ),
        _HoldingsTab(currentPortfolioId: currentPortfolioId, ),
        _AnalysisTab(currentPortfolioId: currentPortfolioId, ),
        _HeatmapTab(currentPortfolioId: currentPortfolioId, ),
        _TradeTab(ref: ref),
      ],
    );
}

/// Overview tab widget
class _OverviewTab extends StatefulWidget {
  const _OverviewTab({required this.currentPortfolioId, });
  final String currentPortfolioId;
  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<PortfolioCubit, PortfolioState>(
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
            return _buildOverviewContent(context);
          }

          return _buildLoadingWithRefresh(context, 'Pull to Refresh Portfolio');
        },
      );
  }

  Widget _buildOverviewContent(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _refreshPortfolio(context, 'Pull to Refresh Overview'),
      child: PortfolioOverviewWidget(
        key: ValueKey('overview_mobile_${widget.currentPortfolioId}'),
        portfolioId: widget.currentPortfolioId,
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
      metadata: {
        'portfolioId': widget.currentPortfolioId,
      },
    );
    context.read<PortfolioCubit>().refreshPortfolioById(widget.currentPortfolioId);
  }
}

/// Holdings tab widget
class _HoldingsTab extends StatelessWidget {
  const _HoldingsTab({required this.currentPortfolioId, });
  final String currentPortfolioId;
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
            key: ValueKey('holdings_$currentPortfolioId'),
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
      metadata: {'portfolioId': currentPortfolioId},
    );
    context.read<PortfolioCubit>().refreshPortfolioById(currentPortfolioId);
  }
}

/// Analysis tab widget
class _AnalysisTab extends StatelessWidget {
  const _AnalysisTab({required this.currentPortfolioId, });
  final String currentPortfolioId;
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
              child: PortfolioAnalysisWidget(
                key: ValueKey('analysis_$currentPortfolioId'),
                portfolioId: currentPortfolioId,
              ),
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
      metadata: {'portfolioId': currentPortfolioId},
    );
    context.read<PortfolioCubit>().refreshPortfolioById(currentPortfolioId);
  }
}

/// Heatmap tab widget using the new mobile heatmap page
class _HeatmapTab extends StatelessWidget {
  const _HeatmapTab({required this.currentPortfolioId, });
  final String currentPortfolioId;
  @override
  Widget build(BuildContext context) => BlocProvider<PortfolioHeatmapCubit>(
    create: (context) => PortfolioHeatmapCubit(),
    child: PortfolioHeatmapMobilePage(
      portfolioId: currentPortfolioId,
      portfolioName: _getPortfolioName(context),
    ),
  );

  /// Get portfolio name from the current portfolio state
  String? _getPortfolioName(BuildContext context) => 'Heatmap';
}

/// Trade tab widget using the trade mobile page with Riverpod
class _TradeTab extends StatelessWidget {
  const _TradeTab({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return TradePortfolioListMobilePage();
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
