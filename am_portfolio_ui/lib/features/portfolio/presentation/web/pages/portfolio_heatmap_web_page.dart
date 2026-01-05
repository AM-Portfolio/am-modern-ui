import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/portfolio_heatmap_widget.dart';

class PortfolioHeatmapWebPage extends ConsumerWidget {
  const PortfolioHeatmapWebPage({
    required this.userId,
    required this.portfolioId,
    super.key,
    this.portfolioName,
  });

  final String userId;
  final String portfolioId;
  final String? portfolioName;

  @override
  Widget build(BuildContext context, WidgetRef ref) => PortfolioHeatmapWidget(
    userId: userId,
    portfolioId: portfolioId,
    portfolioName: portfolioName,
    config: PortfolioHeatmapConfig.web,
  ).animate().fadeIn(duration: 800.ms).scale(curve: Curves.easeOutBack);
}
