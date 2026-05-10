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
    return PortfolioHoldingsWidget(userId: userId, portfolioId: portfolioId);
  }
}
