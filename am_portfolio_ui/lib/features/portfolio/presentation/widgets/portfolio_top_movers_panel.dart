import 'package:am_design_system/am_design_system.dart' as ds;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../internal/domain/entities/portfolio_analytics.dart';
import '../../internal/domain/entities/portfolio_holding.dart';
import '../cubit/portfolio_analytics_cubit.dart';
import '../cubit/portfolio_analytics_state.dart';
import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_state.dart';
import 'movers_join.dart';
import 'movers_widget.dart';

/// Top movers panel: holdings ranked by today's ₹ impact on the portfolio.
class PortfolioTopMoversPanel extends StatelessWidget {
  const PortfolioTopMoversPanel({
    required this.portfolioId,
    required this.timeFrame,
    this.height,
    this.showTimeFrameSelector = false,
    this.compact = false,
    this.fillHeight = false,
    super.key,
  });

  /// Movers | Stress | What-If peer row (shared band height).
  static const double peerBandHeight = 456;

  final String portfolioId;
  final ds.TimeFrame timeFrame;
  final double? height;
  final bool showTimeFrameSelector;
  /// Mobile-style Gainers|Losers tabs, fewer rows — used on intel Overview.
  final bool compact;
  /// Peer stretch rows (Movers | Stress | What-If).
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PortfolioCubit, PortfolioState>(
      builder: (context, portfolioState) {
        final holdings = _holdingsForJoin(portfolioState);
        return BlocBuilder<PortfolioAnalyticsCubit, PortfolioAnalyticsState>(
          builder: (context, state) {
            void retry() =>
                context.read<PortfolioAnalyticsCubit>().loadAnalytics(
                      portfolioId,
                      timeFrame: timeFrame,
                    );

            if (state is PortfolioAnalyticsLoading && holdings.isEmpty) {
              return MoversWidget(
                isLoading: true,
                compact: compact,
                fillHeight: fillHeight,
              );
            } else if (state is PortfolioAnalyticsLoaded ||
                holdings.isNotEmpty) {
              final loaded = state is PortfolioAnalyticsLoaded ? state : null;
              final isLoading = holdings.isEmpty &&
                  (loaded?.isLoadingType(AnalyticsDataType.movers) ?? false);
              final error = holdings.isEmpty
                  ? loaded?.getErrorForType(AnalyticsDataType.movers)
                  : null;
              final Movers? movers;
              if (holdings.isNotEmpty) {
                movers = buildPortfolioMovers(
                  holdings,
                  sessionDate: loaded?.movers?.sessionDate,
                  priceFreshness: loaded?.movers?.priceFreshness,
                );
              } else if (loaded?.movers != null) {
                movers = enrichMovers(loaded!.movers!, holdings);
              } else {
                movers = null;
              }
              return MoversWidget(
                movers: movers,
                isLoading: isLoading,
                error: error,
                compact: compact,
                fillHeight: fillHeight,
                onRetry: retry,
              );
            } else if (state is PortfolioAnalyticsError) {
              return MoversWidget(
                error: state.message,
                compact: compact,
                fillHeight: fillHeight,
                onRetry: retry,
              );
            } else if (state is PortfolioAnalyticsInitial) {
              return MoversWidget(compact: compact, fillHeight: fillHeight);
            }
            return MoversWidget(
              isLoading: true,
              compact: compact,
              fillHeight: fillHeight,
            );
          },
        );
      },
    );
  }

  static List<PortfolioHolding> _holdingsForJoin(PortfolioState state) {
    if (state is PortfolioLoaded && !state.isHoldingsLoading) {
      return state.holdings;
    }
    return const [];
  }
}
