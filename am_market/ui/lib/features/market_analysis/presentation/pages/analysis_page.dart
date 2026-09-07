import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/market_analysis/presentation/widgets/heatmap_explorer_view.dart';
import 'package:am_market_ui/features/market_analysis/presentation/widgets/indices_performance_view_v2.dart';

/// Market Analysis Page with customized theme gradient and responsive global header actions.
class AnalysisPage extends ConsumerWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final marketColor = ModuleColors.market;
    final scaffoldBg = context.colors.scaffoldBackground;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scaffoldBg,
              Color.alphaBlend(marketColor.withValues(alpha: 0.05), scaffoldBg),
              context.colors.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Responsive Header Layout (stacked on mobile, side-by-side on desktop)
                if (isMobile) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Market Analysis',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Detailed indices performance, seasonality, and heatmaps',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Centered Global Timeframe Bar for mobile layouts to avoid clipping
                      const Center(child: GlobalTimeFrameBar()),
                    ],
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Market Analysis',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Detailed indices performance, seasonality, and heatmaps',
                            style: TextStyle(
                              fontSize: 14,
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      // Global Timeframe Bar aligned to the right on Web
                      const GlobalTimeFrameBar(),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                const IndicesPerformanceViewV2(),
                const SizedBox(height: 24),
                // Scrollable content height wrapper for sub-analytics elements
                const SizedBox(height: 850, child: HeatmapExplorerView()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
