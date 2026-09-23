import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../internal/domain/entities/portfolio_summary.dart';
import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_state.dart';

/// Portfolio analysis widget showing analytics and insights
class PortfolioAnalysisWidget extends StatelessWidget {
  const PortfolioAnalysisWidget({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PortfolioCubit, PortfolioState>(
        builder: (context, state) {
          if (state is PortfolioLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PortfolioError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: context.statusError,
                  ),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<PortfolioCubit>().loadPortfolio(),
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
                    'Portfolio Analysis',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  _buildAllocationChart(context, state.summary),
                  const SizedBox(height: 24),
                  _buildPerformanceMetrics(context, state.summary),
                  const SizedBox(height: 24),
                  _buildTopPerformers(context, state.summary),
                  const SizedBox(height: 24),
                  _buildRiskAnalysis(context, state.summary),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      );

  Widget _buildAllocationChart(BuildContext context, PortfolioSummary summary) {
    final colors = [
      Colors.blue,
      context.marketPositive,
      Colors.orange,
      context.marketNegative,
      ModuleColors.portfolio,
      Colors.teal,
      context.statusNeutral,
    ];
    final allocations = summary.sectorAllocation;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sector Allocation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('Pie Chart\n(Sector Allocation)'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: allocations.isEmpty
                        ? [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No sector data available',
                                style: TextStyle(
                                  color: context.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ]
                        : List.generate(
                            allocations.length,
                            (index) {
                              final allocation = allocations[index];
                              final color = colors[index % colors.length];
                              return _buildAllocationItem(
                                allocation.sector,
                                allocation.percentage,
                                color,
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllocationItem(String sector, double percentage, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(sector, style: const TextStyle(fontSize: 12))),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      );

  Widget _buildPerformanceMetrics(
    BuildContext context,
    PortfolioSummary summary,
  ) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance Metrics',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildMetricCard(context, 'Sharpe Ratio', '1.42')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricCard(context, 'Beta', '0.95')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricCard(context, 'Alpha', '2.1%')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricCard(context, 'Volatility', '12.3%')),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildMetricCard(BuildContext context, String title, String value) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, color: context.textTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  Widget _buildTopPerformers(BuildContext context, PortfolioSummary summary) {
    final allPerformers = <TopPerformer>[
      ...summary.topPerformers,
      ...summary.worstPerformers,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top & Worst Performers',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (allPerformers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No performance data available',
                    style: TextStyle(color: context.textTertiary),
                  ),
                ),
              )
            else
              ...allPerformers.map(
                (performer) {
                  final isPositive = performer.gainLossPercentage >= 0;
                  final gainText =
                      '${isPositive ? "+" : ""}${performer.gainLossPercentage.toStringAsFixed(2)}%';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPositive
                          ? context.marketPositive.withValues(alpha: 0.15)
                          : context.marketNegative.withValues(alpha: 0.15),
                      child: Text(
                        performer.symbol,
                        style: TextStyle(
                          color: isPositive
                              ? context.marketPositive
                              : context.marketNegative,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(performer.symbol),
                    subtitle: Text(performer.companyName),
                    trailing: Text(
                      gainText,
                      style: TextStyle(
                        color: isPositive ? context.marketPositive : context.marketNegative,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskAnalysis(BuildContext context, PortfolioSummary summary) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Risk Analysis',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _buildRiskIndicator(context, 'Overall Risk', 0.65, Colors.orange),
              const SizedBox(height: 8),
              _buildRiskIndicator(context, 'Market Risk', 0.45, Colors.blue),
              const SizedBox(height: 8),
              _buildRiskIndicator(context, 'Concentration Risk', 0.8, context.statusError),
            ],
          ),
        ),
      );

  Widget _buildRiskIndicator(BuildContext context, String title, double value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 14)),
              Text(
                '${(value * 100).toInt()}%',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value,
            backgroundColor: context.borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      );
}
