import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/sectorial_allocation_widget.dart';
import '../widgets/market_cap_allocation_widget.dart';
import '../widgets/movers_widget.dart';
import '../cubit/portfolio_analytics_cubit.dart';
import '../cubit/portfolio_analytics_state.dart';
import 'package:am_common/am_common.dart';

/// Main portfolio analysis widget that orchestrates all analytics components
/// This widget provides comprehensive portfolio analysis including:
/// - Sector allocation visualization
/// - Market cap allocation breakdown
/// - Top movers (gainers and losers)
class PortfolioAnalysisWidget extends StatefulWidget {
  const PortfolioAnalysisWidget({required this.portfolioId, super.key});
  final String portfolioId;

  @override
  State<PortfolioAnalysisWidget> createState() =>
      _PortfolioAnalysisWidgetState();
}

class _PortfolioAnalysisWidgetState extends State<PortfolioAnalysisWidget> {
  // Hardcoded portfolio ID for testing
  String get effectivePortfolioId => '163d0143-4fcb-480c-ac20-622f14e0e293';

  @override
  void initState() {
    super.initState();
    CommonLogger.info(
      'Portfolio analysis widget initialized for portfolio: $effectivePortfolioId',
      tag: 'PortfolioAnalysisWidget',
    );

    // Load analytics data when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CommonLogger.debug(
        '🔍 PortfolioAnalysisWidget: About to call loadAnalytics with portfolioId: $effectivePortfolioId',
        tag: 'PortfolioAnalysisWidget',
      );
      context.read<PortfolioAnalyticsCubit>().loadAnalytics(
        effectivePortfolioId,
      );
    });
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async {
      CommonLogger.info(
        'Auto-refreshing portfolio analytics for portfolio: $effectivePortfolioId',
        tag: 'PortfolioAnalysisWidget',
      );
      context.read<PortfolioAnalyticsCubit>().refreshAnalytics(
        effectivePortfolioId,
      );
      // Wait a bit for the refresh to complete
      await Future.delayed(const Duration(milliseconds: 500));
    },
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildMarketCapAllocationSection(context),
          const SizedBox(height: 12),
          _buildMoversSection(context),
          const SizedBox(height: 12),
          _buildSectorAllocationSection(context),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );

  Widget _buildSectorAllocationSection(
    BuildContext context,
  ) => BlocBuilder<PortfolioAnalyticsCubit, PortfolioAnalyticsState>(
    builder: (context, state) {
      CommonLogger.debug(
        '🔍 SectorAllocationSection: Current state is ${state.runtimeType}',
        tag: 'PortfolioAnalysisWidget',
      );

      if (state is PortfolioAnalyticsLoading) {
        return const SectorialAllocationWidget(isLoading: true);
      } else if (state is PortfolioAnalyticsLoaded) {
        CommonLogger.debug(
          '🔍 SectorAllocationSection: sectorAllocation data = ${state.sectorAllocation != null ? 'available' : 'null'}',
          tag: 'PortfolioAnalysisWidget',
        );
        final isLoading = state.isLoadingType(
          AnalyticsDataType.sectorAllocation,
        );
        final error = state.getErrorForType(AnalyticsDataType.sectorAllocation);

        return SectorialAllocationWidget(
          sectorAllocation: state.sectorAllocation,
          isLoading: isLoading,
          error: error,
        );
      } else if (state is PortfolioAnalyticsError) {
        CommonLogger.error(
          'Failed to load sector allocation',
          tag: 'PortfolioAnalysisWidget',
          error: state.message,
        );
        return SectorialAllocationWidget(error: state.message);
      }

      return const SectorialAllocationWidget(isLoading: true);
    },
  );

  Widget _buildMoversSection(BuildContext context) =>
      BlocBuilder<PortfolioAnalyticsCubit, PortfolioAnalyticsState>(
        builder: (context, state) {
          if (state is PortfolioAnalyticsLoading) {
            return const MoversWidget(isLoading: true);
          } else if (state is PortfolioAnalyticsLoaded) {
            final isLoading = state.isLoadingType(AnalyticsDataType.movers);
            final error = state.getErrorForType(AnalyticsDataType.movers);

            return MoversWidget(
              movers: state.movers,
              isLoading: isLoading,
              error: error,
            );
          } else if (state is PortfolioAnalyticsError) {
            CommonLogger.error(
              'Failed to load movers',
              tag: 'PortfolioAnalysisWidget',
              error: state.message,
            );
            return MoversWidget(error: state.message);
          }

          return const MoversWidget(isLoading: true);
        },
      );

  Widget _buildMarketCapAllocationSection(BuildContext context) =>
      BlocBuilder<PortfolioAnalyticsCubit, PortfolioAnalyticsState>(
        builder: (context, state) {
          if (state is PortfolioAnalyticsLoading) {
            return const MarketCapAllocationWidget(isLoading: true);
          } else if (state is PortfolioAnalyticsLoaded) {
            final isLoading = state.isLoadingType(
              AnalyticsDataType.marketCapAllocation,
            );
            final error = state.getErrorForType(
              AnalyticsDataType.marketCapAllocation,
            );

            return MarketCapAllocationWidget(
              marketCapAllocation: state.marketCapAllocation,
              isLoading: isLoading,
              error: error,
            );
          } else if (state is PortfolioAnalyticsError) {
            CommonLogger.error(
              'Failed to load market cap allocation',
              tag: 'PortfolioAnalysisWidget',
              error: state.message,
            );
            return MarketCapAllocationWidget(error: state.message);
          }

          return const MarketCapAllocationWidget(isLoading: true);
        },
      );
}

