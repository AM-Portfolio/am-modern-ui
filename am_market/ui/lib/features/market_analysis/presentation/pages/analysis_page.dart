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
    
    return Scaffold(
      body: Container(
        // Applied custom linear gradient using the exact requested base shade #151524
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F0F1A), // Deep backdrop
              Color(0xFF151524), // Base theme shade (rgba(21, 21, 36, 1))
              Color(0xFF1F1F35), // Subtle lighter endpoint for structural gradient
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
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
                      const Text(
                        'Market Analysis',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Detailed indices performance, seasonality, and heatmaps',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
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
                          const Text(
                            'Market Analysis',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Detailed indices performance, seasonality, and heatmaps',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.6),
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
