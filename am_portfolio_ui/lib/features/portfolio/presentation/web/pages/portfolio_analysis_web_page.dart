import 'package:am_design_system/am_design_system.dart';
import 'package:am_common/am_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../internal/domain/entities/portfolio_analytics_request.dart';
import '../../../internal/domain/entities/portfolio_summary.dart';
import '../../../internal/domain/entities/portfolio_holding.dart';
import '../../../internal/domain/entities/portfolio_analytics.dart';
import '../../../providers/portfolio_providers.dart';
import '../../widgets/global_portfolio_wrapper.dart';

/// Web-specific portfolio analysis page with comprehensive analytics
class PortfolioAnalysisWebPage extends ConsumerStatefulWidget {
  const PortfolioAnalysisWebPage({
    required this.portfolioId,
    super.key,
    this.portfolioName,
  });
  final String portfolioId;
  final String? portfolioName;

  @override
  ConsumerState<PortfolioAnalysisWebPage> createState() =>
      _PortfolioAnalysisWebPageState();
} 


class _PortfolioAnalysisWebPageState
    extends ConsumerState<PortfolioAnalysisWebPage> {
  String _selectedAnalysisType = 'Performance';
  late final PortfolioAnalyticsRequest _baseAnalyticsRequest;

  @override
  void initState() {
    super.initState();
    _baseAnalyticsRequest = PortfolioAnalyticsRequest(
      coreIdentifiers: CoreIdentifiers(portfolioId: widget.portfolioId),
      featureToggles: const FeatureToggles(
        includeHeatmap: true,
        includeMovers: true,
        includeSectorAllocation: true,
        includeMarketCapAllocation: true,
      ),
      featureConfiguration: const FeatureConfiguration(moversLimit: 10),
      pagination: const Pagination(
        page: 1,
        size: 100,
        sortBy: 'currentValue',
        sortDirection: 'DESC',
        returnAllData: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePortfolioId = context.selectedPortfolioId ?? widget.portfolioId;
    final timeFrameCode = ref.watch(appTimeFrameProvider).code;
    ref.listen(appTimeFrameProvider, (previous, next) {
      if (previous != next) {
        ref.invalidate(portfolioSummaryProvider(activePortfolioId));
        ref.invalidate(portfolioHoldingsProvider(activePortfolioId));
      }
    });
    
    final analyticsRequest = PortfolioAnalyticsRequest(
      coreIdentifiers: CoreIdentifiers(portfolioId: activePortfolioId),
      featureToggles: _baseAnalyticsRequest.featureToggles,
      featureConfiguration: _baseAnalyticsRequest.featureConfiguration,
      pagination: _baseAnalyticsRequest.pagination,
      fromDate: _baseAnalyticsRequest.fromDate,
      toDate: _baseAnalyticsRequest.toDate,
      timeFrame: timeFrameCode,
    );

    final summaryAsync = ref.watch(
      portfolioSummaryProvider(activePortfolioId),
    );
    final analyticsAsync = ref.watch(portfolioAnalyticsProvider(analyticsRequest));
    final holdingsAsync = ref.watch(
      portfolioHoldingsProvider(activePortfolioId),
    );

    return Scaffold(
      body: Column(
        children: [
          // Analysis Controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: _buildAnalysisControls(context),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

          // Main Analysis Content
          Expanded(
            child: Row(
              children: [
                // Left Panel - Charts and Analytics
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Performance Chart Section
                      Expanded(
                        flex: 2,
                        child: _buildPerformanceSection(context, summaryAsync, timeFrameCode)
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 200.ms)
                            .slideX(begin: -0.1, end: 0),
                      ),

                      // Analytics Grid
                      Expanded(
                        flex: 3,
                        child: _buildAnalyticsGrid(
                          context,
                          analyticsAsync,
                          holdingsAsync,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Panel - Insights and Actions
                Container(
                      width: 350,
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: _buildInsightsPanel(context),
                    )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 400.ms)
                    .slideX(begin: 0.1, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisControls(BuildContext context) => Row(
    children: [
      // Analysis Type Selector
      Text(
        'Analysis Type:',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(width: 12),

      ToggleButtons(
        isSelected: [
          _selectedAnalysisType == 'Performance',
          _selectedAnalysisType == 'Risk',
          _selectedAnalysisType == 'Allocation',
          _selectedAnalysisType == 'Comparison',
        ],
        onPressed: (index) {
          final types = ['Performance', 'Risk', 'Allocation', 'Comparison'];
          setState(() {
            _selectedAnalysisType = types[index];
          });
        },
        borderRadius: BorderRadius.circular(8),
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Performance'),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Risk'),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Allocation'),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Comparison'),
          ),
        ],
      ),

      const Spacer(),

      const GlobalTimeFrameBar(),

      const SizedBox(width: 16),

      // Export Button
      ElevatedButton.icon(
        onPressed: () {
          // Handle export
          _showExportDialog(context);
        },
        icon: const Icon(Icons.download),
        label: const Text('Export'),
      ),
    ],
  );

  Widget _buildPerformanceSection(
    BuildContext context,
    AsyncValue<PortfolioSummary> summaryAsync,
    String timeFrameCode,
  ) => Card(
    margin: const EdgeInsets.all(16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Portfolio Performance - $timeFrameCode',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: summaryAsync.when(
              data: (summary) => _buildPerformanceChart(context, summary, timeFrameCode),
              loading: () => _buildPerformanceChartSkeleton(context),
              error: (error, stack) => _buildErrorPlaceholder(
                context,
                'Performance Chart',
                error.toString(),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildPerformanceChart(
    BuildContext context,
    PortfolioSummary summary,
    String timeFrameCode,
  ) => Container(
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Interactive Performance Chart',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Total Return: \$${summary.totalGainLoss.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: summary.totalGainLoss >= 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Time Period: $timeFrameCode',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ],
        ),
      ),
    ),
  );

  Widget _buildAnalyticsGrid(
    BuildContext context,
    AsyncValue<PortfolioAnalytics> analyticsAsync,
    AsyncValue<PortfolioHoldings> holdingsAsync,
  ) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Analytics',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: analyticsAsync.when(
            data: (analytics) => holdingsAsync.when(
              data: (holdings) =>
                  _buildAnalyticsCharts(context, analytics, holdings),
              loading: () => _buildAnalyticsGridSkeleton(context),
              error: (error, stack) =>
                  Center(child: Text('Error loading holdings: $error')),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading analytics',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildAnalyticsCharts(BuildContext context, PortfolioAnalytics analytics, PortfolioHoldings holdings) {
    // Extract allocation data
    final sectorAlloc = analytics.analytics?.sectorAllocation;
    final marketCapAlloc = analytics.analytics?.marketCapAllocation;

    final List<AllocationItem> sectorData =
        sectorAlloc != null && sectorAlloc.sectorWeights.isNotEmpty
        ? sectorAlloc.sectorWeights
              .map<AllocationItem>(
                (sector) => AllocationItem(
                  label: sector.sectorName,
                  value: sector.marketCap,
                  percentage: sector.weightPercentage,
                  count: sector.topStocks.length,
                ),
              )
              .toList()
        : <AllocationItem>[];

    final List<AllocationItem> marketCapData =
        marketCapAlloc != null && marketCapAlloc.segments.isNotEmpty
        ? marketCapAlloc.segments
              .map<AllocationItem>(
                (segment) => AllocationItem(
                  label: segment.segmentName,
                  value: segment.segmentValue,
                  percentage: segment.weightPercentage,
                  count: segment.numberOfStocks,
                ),
              )
              .toList()
        : <AllocationItem>[];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildSectorAllocationCard(
          context,
          sectorData,
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
        _buildMarketCapCard(
          context,
          marketCapData,
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
        _buildTopHoldingsCard(
          context,
          holdings,
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
        _buildRiskMetricsCard(
          context,
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _buildSectorAllocationCard(
    BuildContext context,
    List<AllocationItem> sectorData,
  ) => Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sector Allocation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: sectorData.isEmpty
                ? const Center(child: Text('No sector data'))
                : AnimatedSectorDonutChart(
                    allocations: sectorData,
                    showAnimation: false,
                  ),
          ),
        ],
      ),
    ),
  );

  Widget _buildMarketCapCard(
    BuildContext context,
    List<AllocationItem> marketCapData,
  ) => Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance, color: Colors.purple, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Market Cap Distribution',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: marketCapData.isEmpty
                ? const Center(child: Text('No market cap data'))
                : AnimatedMarketCapChart(
                    allocations: marketCapData,
                    showAnimation: false,
                  ),
          ),
        ],
      ),
    ),
  );

  Widget _buildTopHoldingsCard(BuildContext context, PortfolioHoldings holdings) {
    final topHoldings = holdings.holdings.take(5).toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  'Top Holdings',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: topHoldings.length,
                itemBuilder: (context, index) {
                  final holding = topHoldings[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                holding.symbol,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '\$${holding.currentPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${holding.todayChangePercentage >= 0 ? '+' : ''}${holding.todayChangePercentage.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: holding.todayChangePercentage >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskMetricsCard(BuildContext context) => Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Risk Metrics',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRiskMetricRow('Portfolio Beta', '1.15', Colors.orange),
                _buildRiskMetricRow('Sharpe Ratio', '0.92', Colors.green),
                _buildRiskMetricRow('Volatility', '18.5%', Colors.orange),
                _buildRiskMetricRow('Max Drawdown', '-12.3%', Colors.red),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildRiskMetricRow(String label, String value, Color color) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 12)),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    ],
  );

  Widget _buildInsightsPanel(BuildContext context) => Container(
    color: Theme.of(context).colorScheme.surface,
    child: Column(
      children: [
        // Panel Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'AI Insights',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // Insights Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInsightCard(
                  context,
                  'Portfolio Health',
                  'Your portfolio shows strong diversification across sectors.',
                  Icons.health_and_safety,
                  Colors.green,
                ),
                const SizedBox(height: 16),

                _buildInsightCard(
                  context,
                  'Risk Alert',
                  'Consider rebalancing - Tech allocation is above target.',
                  Icons.warning,
                  Colors.orange,
                ),
                const SizedBox(height: 16),

                _buildInsightCard(
                  context,
                  'Opportunity',
                  'Healthcare sector showing strong momentum this quarter.',
                  Icons.trending_up,
                  Colors.blue,
                ),
                const SizedBox(height: 24),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _buildActionButton(
                  context,
                  'Rebalance Portfolio',
                  Icons.balance,
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  context,
                  'Generate Report',
                  Icons.description,
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  context,
                  'Schedule Review',
                  Icons.calendar_today,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildInsightCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) => Card(
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    ),
  );

  Widget _buildActionButton(BuildContext context, String text, IconData icon) =>
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            // Handle action
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$text - Coming soon!')));
          },
          icon: Icon(icon, size: 16),
          label: Text(text),
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      );

  Widget _buildErrorPlaceholder(
    BuildContext context,
    String title,
    String error,
  ) => Container(
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.red.shade300),
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            'Failed to load $title',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _buildPerformanceChartSkeleton(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
                height: 40,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1200.ms, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                10,
                (index) =>
                    Container(
                          width: 20,
                          height: 50.0 + (index * 10) % 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(
                          duration: 1200.ms,
                          delay: (100 * index).ms,
                          color: Colors.grey.shade300,
                        ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildAnalyticsGridSkeleton(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    children: List.generate(
      4,
      (index) => Card(
        elevation: 2,
        child:
            Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 120,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                  duration: 1200.ms,
                  delay: (200 * index).ms,
                  color: Colors.grey.shade100,
                ),
      ),
    ),
  );

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Analysis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.of(context).pop();
                // Handle PDF export
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as Excel'),
              onTap: () {
                Navigator.of(context).pop();
                // Handle Excel export
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Export as Image'),
              onTap: () {
                Navigator.of(context).pop();
                // Handle image export
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
