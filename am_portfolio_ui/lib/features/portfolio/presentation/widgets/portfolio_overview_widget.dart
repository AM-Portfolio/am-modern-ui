import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_analysis_ui/widgets/analysis_allocation_widget.dart';
import 'package:am_analysis_ui/widgets/analysis_top_movers_widget.dart';
import 'package:am_analysis_ui/widgets/analysis_performance_widget.dart';
import 'package:am_analysis_ui/models/analysis_enums.dart';

import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_state.dart';
import 'headless_allocation_demo.dart';

/// Portfolio overview widget showing summary and key metrics
class PortfolioOverviewWidget extends StatelessWidget {
  const PortfolioOverviewWidget({required this.userId, this.portfolioId, super.key});
  final String userId;
  final String? portfolioId;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PortfolioCubit, PortfolioState>(
        builder: (context, state) {
          if (state is PortfolioLoading) {
            return _buildOverviewSkeleton(context);
          } else if (state is PortfolioError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<PortfolioCubit>().loadPortfolio(userId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is PortfolioLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Portfolio Overview',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  _buildSummaryCards(context, state.summary),
                  const SizedBox(height: 24),
                  _buildPerformanceSection(context, state.summary),
                  const SizedBox(height: 24),
                  // Analysis Widgets Section
                  Text(
                    'Portfolio Analytics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 🎨 Headless Architecture Demo
                  if (portfolioId != null) ...[  
                    Text(
                      '🎨 Headless Architecture Comparison',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 400,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Default Widget
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Default Widget (Pre-built UI)',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white60,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: AnalysisAllocationWidget(
                                    portfolioId: portfolioId!,
                                    groupBy: GroupBy.sector,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Right: Headless Architecture  
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Headless (Custom UI + Core Cubit)',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white60,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: HeadlessAllocationDemo(
                                    portfolioId: portfolioId!,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Original Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AnalysisTopMoversWidget(
                            portfolioId: portfolioId!,
                            height: 350,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Performance Chart
                    AnalysisPerformanceWidget(
                      portfolioId: portfolioId!,
                      height: 300,
                    ),
                  ],
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      );

  Widget _buildSummaryCards(BuildContext context, summary) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    childAspectRatio: 1.8, // Slightly wider for better layout
    mainAxisSpacing: 16,
    crossAxisSpacing: 16,
    children: [
      _buildSummaryCard(
        'Total Value',
        '\$${summary.totalValue.toStringAsFixed(2)}',
        Icons.account_balance_wallet,
        const Color(0xFF6C5DD3), // Purple accent
        isGlossy: true,
      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
      _buildSummaryCard(
        'Today Change',
        '\$${summary.todayChange.toStringAsFixed(2)}',
        Icons.trending_up,
        summary.todayChange >= 0 ? const Color(0xFF00B894) : const Color(0xFFFF7675), // Green/Red
        isGlossy: true,
      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
      _buildSummaryCard(
        'Total P&L',
        '\$${summary.totalGainLoss.toStringAsFixed(2)}',
        Icons.show_chart,
        summary.totalGainLoss >= 0 ? const Color(0xFF00B894) : const Color(0xFFFF7675),
        isGlossy: true,
      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
      _buildSummaryCard(
        'Holdings',
        '${summary.totalHoldings}',
        Icons.pie_chart,
        const Color(0xFFFFA502), // Orange accent
        isGlossy: true,
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
    ],
  );

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isGlossy = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C3E), // Dark card background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          // Neon glow effect based on color
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2C2C3E),
            const Color(0xFF2C2C3E).withValues(alpha: 0.8),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Glassmorphism shine effect
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      // Optional: Add a small trend indicator or sparkline here
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[400],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSection(BuildContext context, summary) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Performance',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _buildPerformanceCard(
              'Today',
              '${summary.todayChangePercentage.toStringAsFixed(2)}%',
              summary.todayChangePercentage >= 0 ? const Color(0xFF00B894) : const Color(0xFFFF7675),
            ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1, end: 0),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildPerformanceCard(
              'Total',
              '${summary.totalGainLossPercentage.toStringAsFixed(2)}%',
              summary.totalGainLossPercentage >= 0 ? const Color(0xFF00B894) : const Color(0xFFFF7675),
            ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1, end: 0),
          ),
        ],
      ),
    ],
  );

  Widget _buildPerformanceCard(String title, String percentage, Color color) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C3E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  percentage,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                    shadows: [
                      Shadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Circular Progress or Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
                border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
              ),
              child: Icon(
                percentage.startsWith('-') ? Icons.arrow_downward : Icons.arrow_upward,
                color: color,
                size: 20,
              ),
            ),
          ],
        ),
      );

  Widget _buildOverviewSkeleton(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 200,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C3E),
              borderRadius: BorderRadius.circular(8),
            ),
          ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.8,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: List.generate(4, (index) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C3E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
              ).animate(onPlay: (controller) => controller.repeat())
               .shimmer(duration: 1200.ms, delay: (100 * index).ms, color: Colors.white.withOpacity(0.05));
            }),
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 150,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C3E),
                  borderRadius: BorderRadius.circular(8),
                ),
              ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.05)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C3E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1200.ms, delay: 400.ms, color: Colors.white.withOpacity(0.05)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C3E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1200.ms, delay: 500.ms, color: Colors.white.withOpacity(0.05)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
