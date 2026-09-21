import 'package:flutter/material.dart';
import '../../mobile/widgets/portfolio_holdings_widget.dart';
import 'package:am_common/am_common.dart';

/// Web-specific portfolio holdings page with template-based architecture.
///
/// News scrolls after the holdings list (see [PortfolioHoldingsWidget]).
class PortfolioHoldingsWebPage extends StatelessWidget {
  const PortfolioHoldingsWebPage({
    required this.portfolioId,
    super.key,
    this.portfolioName,
  });

  final String portfolioId;
  final String? portfolioName;

  @override
  Widget build(BuildContext context) {
    final activePortfolioId =
        context.selectedPortfolioId ?? portfolioId;
    return PortfolioHoldingsWidget(
      portfolioId: activePortfolioId,
      showNewsSection: true,
    );
  }
}
