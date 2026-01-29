import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../mobile/widgets/portfolio_holdings_widget.dart';

import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/am_design_system.dart';

/// Web-specific portfolio holdings page with template-based architecture
class PortfolioHoldingsWebPage extends StatelessWidget {
  const PortfolioHoldingsWebPage({
    required this.userId,
    required this.portfolioId,
    super.key,
    this.portfolioName,
  });

  final String userId;
  final String portfolioId;
  final String? portfolioName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           if (portfolioName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                '$portfolioName Holdings',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          Expanded(
            child: PortfolioHoldingsWidget(
              userId: userId,
              portfolioId: portfolioId,
            ),
          ),
        ],
      ),
    );
  }
}
