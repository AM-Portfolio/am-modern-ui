import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_analysis_ui/widgets/analysis_allocation_widget.dart';
import 'package:am_analysis_ui/widgets/analysis_top_movers_widget.dart';
import 'package:am_analysis_ui/widgets/analysis_performance_widget.dart';
import 'package:am_analysis_ui/models/analysis_enums.dart';
import 'package:am_design_system/am_design_system.dart' as ds;

import 'package:intl/intl.dart';

import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_state.dart';


/// Portfolio overview widget showing summary and key metrics
class PortfolioOverviewWidget extends StatefulWidget {
  const PortfolioOverviewWidget({required this.userId, this.portfolioId, super.key});
  final String userId;
  final String? portfolioId;

  @override
  State<PortfolioOverviewWidget> createState() => _PortfolioOverviewWidgetState();
}

class _PortfolioOverviewWidgetState extends State<PortfolioOverviewWidget> {
  ds.TimeFrame _selectedTimeFrame = ds.TimeFrame.oneMonth;

  void _onTimeFrameChanged(ds.TimeFrame timeFrame) {
    setState(() {
      _selectedTimeFrame = timeFrame;
    });
  }

  @override
  Widget build(BuildContext context) {
    final portfolioId = widget.portfolioId;
    final userId = widget.userId;
    
    print('[PortfolioOverview] Building with portfolioId=$portfolioId');

    return BlocBuilder<PortfolioCubit, PortfolioState>(
      builder: (context, state) {
        print('[PortfolioOverview] Current State: ${state.runtimeType}');
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
              padding: const EdgeInsets.all(16), // Reduced from 20
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (portfolioId != null) ...[
                    // Header with Global Time Frame Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ds.TimeFrameSelector.portfolio(
                          selectedTimeFrame: _selectedTimeFrame,
                          onTimeFrameChanged: _onTimeFrameChanged,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Row 1: 4 Metric Cards with staggered animations
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            'Total Balance',
                            _formatCurrency(state.summary.totalValue),
                            '${state.summary.todayChangePercentage >= 0 ? "+" : ""}${state.summary.todayChangePercentage.toStringAsFixed(2)}%',
                            const Color(0xFF6C5DD3),
                            Icons.account_balance_wallet,
                            isPositive: state.summary.todayChangePercentage >= 0,
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            'Daily P&L',
                            _formatCurrency(state.summary.todayChange),
                            '${state.summary.todayChange >= 0 ? "+" : ""}${state.summary.todayChangePercentage.toStringAsFixed(2)}% today',
                            state.summary.todayChange >= 0 
                                ? const Color(0xFF00B894) 
                                : const Color(0xFFFF7675),
                            Icons.trending_up,
                            isPositive: state.summary.todayChange >= 0,
                          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2, end: 0),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            'Total Return',
                            _formatCurrency(state.summary.totalGainLoss),
                            'All time',
                            state.summary.totalGainLoss >= 0
                                ? const Color(0xFF00B894)
                                : const Color(0xFFFF7675),
                            Icons.show_chart,
                            isPositive: state.summary.totalGainLoss >= 0,
                          ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            'Cash Available',
                            _formatCurrency(12000.00),
                            'Buying power',
                            const Color(0xFF4A90E2),
                            Icons.add_circle_outline,
                            isHighlight: true,
                          ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.2, end: 0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Row 2: Performance Chart + Sector Allocation with animations
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Performance Chart (Left, 60%)
                        Expanded(
                          flex: 6,
                          child: Container(
                            height: 340,
                            child: AnalysisPerformanceWidget(
                              key: ValueKey('perf_${_selectedTimeFrame.code}'),
                              portfolioId: portfolioId!,
                              initialTimeFrame: _selectedTimeFrame,
                              showTimeFrameSelector: false,
                              height: 340,
                            ),
                          ).animate().fadeIn(duration: 500.ms, delay: 400.ms).slideX(begin: -0.1, end: 0),
                        ),
                        const SizedBox(width: 12),
                        
                        // Sector Allocation (Right, 40%)
                        Expanded(
                          flex: 4,
                          child: Container(
                            height: 340,
                            child: AnalysisAllocationWidget(
                              key: ValueKey('alloc_${_selectedTimeFrame.code}'),
                              portfolioId: portfolioId!,
                              initialTimeFrame: _selectedTimeFrame,
                              groupBy: GroupBy.sector,
                            ),
                          ).animate().fadeIn(duration: 500.ms, delay: 500.ms).slideX(begin: 0.1, end: 0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Row 3: Top Gainers + Top Losers with animation
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AnalysisTopMoversWidget(
                            key: ValueKey('movers_${_selectedTimeFrame.code}'),
                            portfolioId: portfolioId!,
                            initialTimeFrame: _selectedTimeFrame,
                            showTimeFrameSelector: false,
                            height: 300,
                          ),
                        ).animate().fadeIn(duration: 500.ms, delay: 600.ms).slideY(begin: 0.2, end: 0),
                      ],
                    ),
                  ] else ...[ 
                    // Fallback for no portfolio ID
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('Please select a portfolio to view details'),
                      ),
                    ),
                  ],
                ],

              ),
            );
          }
          return const SizedBox.shrink();
        },
      );
  }

  // Helper method for building summary cards (old fallback - can be removed later)
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

  // Modern Metric Cards with Theme Colors
  Widget _buildMetricCard(
    BuildContext context, // Add context parameter
    String title,
    String value,
    String subtitle,
    Color accentColor,
    IconData icon, {
    bool isPositive = false,
    bool isHighlight = false,
  }) {
    // Use theme colors
    final cardColor = Theme.of(context).cardColor;
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isHighlight ? accentColor : cardColor,
        borderRadius: BorderRadius.circular(12),
        border: !isHighlight ? Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
          width: 1,
        ) : null,
        boxShadow: isHighlight ? [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Title + Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: isHighlight 
                        ? Colors.white.withValues(alpha: 0.85) 
                        : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isHighlight
                      ? Colors.white.withValues(alpha: 0.2)
                      : accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: isHighlight ? Colors.white : accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Main Value
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isHighlight ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
              height: 1.1,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Subtitle with change indicator
          Row(
            children: [
              if (isPositive) ...[
                Icon(
                  Icons.arrow_upward_rounded,
                  size: 12,
                  color: isHighlight 
                      ? Colors.white.withValues(alpha: 0.9)
                      : accentColor,
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: isHighlight
                        ? Colors.white.withValues(alpha: 0.75)
                        : (isPositive 
                            ? accentColor 
                            : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
                    fontWeight: isPositive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper to format currency
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  
  // Compact horizontal summary cards
  Widget _buildCompactSummaryCards(BuildContext context, summary) => Row(
    children: [
      Expanded(
        child: _buildCompactCard(
          'Total Value',
          '\$${summary.totalValue.toStringAsFixed(2)}',
          Icons.account_balance_wallet,
          const Color(0xFF6C5DD3),
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _buildCompactCard(
          'Today',
          '\$${summary.todayChange.toStringAsFixed(2)}',
          Icons.trending_up,
          summary.todayChange >= 0 ? const Color(0xFF00B894) : const Color(0xFFFF7675),
        ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1, end: 0),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _buildCompactCard(
          'Total P&L',
          '\$${summary.totalGainLoss.toStringAsFixed(2)}',
          Icons.show_chart,
          summary.totalGainLoss >= 0 ? const Color(0xFF00B894) : const Color(0xFFFF7675),
        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
      ),
    ],
  );

  Widget _buildCompactCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }


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
