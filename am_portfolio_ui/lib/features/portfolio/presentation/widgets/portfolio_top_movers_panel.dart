import 'package:am_analysis_core/am_analysis_core.dart';
import 'package:am_analysis_ui/widgets/analysis_top_movers_widget.dart';
import 'package:am_design_system/am_design_system.dart' as ds;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_state.dart';
import 'holdings_to_movers_mapper.dart';

/// Top movers with holdings-based fallback when analysis API returns 500.
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
    return BlocBuilder<PortfolioCubit, PortfolioState>(
      buildWhen: (previous, current) {
        if (current is PortfolioLoaded && current.portfolioId == portfolioId) {
          return previous is! PortfolioLoaded ||
              previous.holdings != current.holdings;
        }
        return false;
      },
      builder: (context, state) {
        List<MoverItem>? fallback;
        var holdingsCount = 0;
        if (state is PortfolioLoaded && state.portfolioId == portfolioId) {
          holdingsCount = state.holdings.length;
          fallback = moversFromHoldings(
            state.holdings,
            timeFrame: timeFrame,
          );
        }

        return AnalysisTopMoversWidget(
          key: ValueKey('movers_${timeFrame.code}_${portfolioId}_$holdingsCount'),
          portfolioId: portfolioId,
          initialTimeFrame: timeFrame,
          showTimeFrameSelector: showTimeFrameSelector,
          height: height,
          fallbackMovers: fallback,
        );
      },
    );
  }
}