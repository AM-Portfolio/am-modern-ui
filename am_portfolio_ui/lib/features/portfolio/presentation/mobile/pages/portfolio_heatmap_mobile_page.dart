import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/portfolio_heatmap_widget.dart';

/// Portfolio Heatmap Mobile Page
/// Optimized for mobile devices with touch-friendly controls and responsive design
class PortfolioHeatmapMobilePage extends ConsumerWidget {
  const PortfolioHeatmapMobilePage({
    required this.portfolioId,
    super.key,
    this.portfolioName,
  });

  final String portfolioId;
  final String? portfolioName;

  @override
  Widget build(BuildContext context, WidgetRef ref) => PortfolioHeatmapWidget(
    portfolioId: portfolioId,
    portfolioName: portfolioName,
    config: PortfolioHeatmapConfig.mobile,
  );
}
