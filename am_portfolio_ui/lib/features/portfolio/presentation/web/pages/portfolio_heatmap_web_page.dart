import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../providers/portfolio_providers.dart';
import '../../cubit/portfolio_analytics_cubit.dart';
import '../../cubit/portfolio_heatmap_cubit.dart';
import '../../widgets/portfolio_heatmap_widget.dart';

/// Web-specific portfolio heatmap page.
/// Self-contained with its own providers to support direct linking.
class PortfolioHeatmapWebPage extends ConsumerWidget {
  const PortfolioHeatmapWebPage({
    required this.userId,
    super.key,
    this.portfolioId,
    this.portfolioName,
  });

  final String userId;
  final String? portfolioId;
  final String? portfolioName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (portfolioId == null) {
      return const Center(child: Text('Please select a portfolio'));
    }

    final analyticsServiceAsync = ref.watch(portfolioAnalyticsServiceProvider);

    return analyticsServiceAsync.when(
      data: (analyticsService) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => PortfolioAnalyticsCubit(analyticsService),
            ),
            BlocProvider(
              create: (context) => PortfolioHeatmapCubit(),
            ),
          ],
          child: _PortfolioHeatmapView(
            userId: userId,
            portfolioId: portfolioId!,
            portfolioName: portfolioName,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        CommonLogger.error(
          'Failed to load analytics service',
          tag: 'PortfolioHeatmapWebPage',
          error: error,
          stackTrace: stack,
        );
        return Center(child: Text('Error loading dependencies: $error'));
      },
    );
  }
}

class _PortfolioHeatmapView extends StatelessWidget {
  const _PortfolioHeatmapView({
    required this.userId,
    required this.portfolioId,
    this.portfolioName,
  });

  final String userId;
  final String portfolioId;
  final String? portfolioName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Portfolio Heatmap',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (portfolioName != null) ...[
                const SizedBox(width: 8),
                Text(
                  '($portfolioName)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PortfolioHeatmapWidget(
              userId: userId,
              portfolioId: portfolioId,
              portfolioName: portfolioName,
              config: PortfolioHeatmapConfig.web,
            ),
          ),
        ],
      ),
    );
  }
}
