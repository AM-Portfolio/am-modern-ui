import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_state.dart';

/// Portfolio analysis widget showing analytics and insights
class PortfolioAnalysisWidget extends StatelessWidget {
  const PortfolioAnalysisWidget({required this.userId, super.key});
  final String userId;

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

  Widget _buildAllocationChart(BuildContext context, summary) => Card(
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
                    color: Colors.grey.shade100,
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
                  children: [
                    _buildAllocationItem('Technology', 35.2, Colors.blue),
                    _buildAllocationItem('Healthcare', 22.8, Colors.green),
                    _buildAllocationItem('Finance', 18.3, Colors.orange),
                    _buildAllocationItem('Energy', 12.1, Colors.red),
                    _buildAllocationItem('Others', 11.6, Colors.grey),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

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

  Widget _buildPerformanceMetrics(BuildContext context, summary) => Card(
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
              Expanded(child: _buildMetricCard('Sharpe Ratio', '1.42')),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricCard('Beta', '0.95')),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricCard('Alpha', '2.1%')),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricCard('Volatility', '12.3%')),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildMetricCard(String title, String value) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  Widget _buildTopPerformers(BuildContext context, summary) {
    final performers = [
      {'symbol': 'AAPL', 'gain': '+15.2%', 'isPositive': true},
      {'symbol': 'GOOGL', 'gain': '+12.8%', 'isPositive': true},
      {'symbol': 'TSLA', 'gain': '-8.3%', 'isPositive': false},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Performers',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...performers.map(
              (performer) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: performer['isPositive']! as bool
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  child: Text(
                    performer['symbol'].toString(),
                    style: TextStyle(
                      color: performer['isPositive']! as bool
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(performer['symbol'].toString()),
                trailing: Text(
                  performer['gain'].toString(),
                  style: TextStyle(
                    color: performer['isPositive']! as bool
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskAnalysis(BuildContext context, summary) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Risk Analysis', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _buildRiskIndicator('Overall Risk', 0.65, Colors.orange),
          const SizedBox(height: 8),
          _buildRiskIndicator('Market Risk', 0.45, Colors.blue),
          const SizedBox(height: 8),
          _buildRiskIndicator('Concentration Risk', 0.8, Colors.red),
        ],
      ),
    ),
  );

  Widget _buildRiskIndicator(String title, double value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          Text(
            '${(value * 100).toInt()}%',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
      const SizedBox(height: 4),
      LinearProgressIndicator(
        value: value,
        backgroundColor: Colors.grey.shade200,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    ],
  );
}
