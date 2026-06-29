import 'package:am_design_system/am_design_system.dart' as ds;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../internal/domain/entities/portfolio_analytics.dart';
import '../cubit/portfolio_analytics_cubit.dart';
import '../cubit/portfolio_analytics_state.dart';
import 'movers_widget.dart';
import 'portfolio_market_movers_widget.dart';

/// Top movers panel that displays global market top gainers and losers.
class PortfolioTopMoversPanel extends StatelessWidget {
  const PortfolioTopMoversPanel({
    required this.portfolioId,
    required this.timeFrame,
    this.height,
    this.showTimeFrameSelector = false,
    super.key,
  });

  final String portfolioId;
  final ds.TimeFrame timeFrame;
  final double? height;
  final bool showTimeFrameSelector;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PortfolioAnalyticsCubit, PortfolioAnalyticsState>(
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
          return MoversWidget(error: state.message);
        }
        return const MoversWidget(isLoading: true);
      },
    );
  }
}