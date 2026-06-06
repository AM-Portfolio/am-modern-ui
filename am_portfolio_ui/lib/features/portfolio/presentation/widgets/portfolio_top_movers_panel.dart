import 'package:am_design_system/am_design_system.dart' as ds;
import 'package:flutter/material.dart';

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
    return PortfolioMarketMoversWidget(
      key: ValueKey('market_movers_${timeFrame.code}'),
      timeFrame: timeFrame,
      height: height,
    );
  }
}