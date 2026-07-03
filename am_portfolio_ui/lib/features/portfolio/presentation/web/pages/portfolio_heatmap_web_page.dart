import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../providers/portfolio_providers.dart';
import '../../cubit/portfolio_analytics_cubit.dart';
import '../../cubit/portfolio_heatmap_cubit.dart';
import '../../widgets/portfolio_heatmap_widget.dart';
import '../../widgets/global_portfolio_wrapper.dart';

/// Web-specific portfolio heatmap page.
/// Self-contained with its own providers to support direct linking.
class PortfolioHeatmapWebPage extends ConsumerWidget {
  const PortfolioHeatmapWebPage({
    super.key,
    this.portfolioId,
    this.portfolioName,
  });

  final String? portfolioId;
  final String? portfolioName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePortfolioId = context.selectedPortfolioId ?? portfolioId;
    final activePortfolioName = context.selectedPortfolioName ?? portfolioName;

    if (activePortfolioId == null) {
      return const Center(child: Text('Please select a portfolio'));
    }

    return BlocProvider(
      key: ValueKey(activePortfolioId), // Force recreation of heatmap cubit
      create: (context) => PortfolioHeatmapCubit(
        context.read<PortfolioAnalyticsCubit>(),
      ),
      child: _PortfolioHeatmapView(
        portfolioId: activePortfolioId,
        portfolioName: activePortfolioName,
      ),
    );
  }
}

class _PortfolioHeatmapView extends StatelessWidget {
  const _PortfolioHeatmapView({
    required this.portfolioId,
    this.portfolioName,
  });

  final String portfolioId;
  final String? portfolioName;

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder ensures PortfolioHeatmapWidget always has a bounded height.
    // Without this the `Expanded` inside it resolves to 0 on the web scaffold.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.of(context).size.height,
          child: PortfolioHeatmapWidget(
            portfolioId: portfolioId,
            portfolioName: portfolioName,
            config: PortfolioHeatmapConfig.web,
          ),
        );
      },
    );
  }
}
