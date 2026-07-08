import 'package:flutter/material.dart';
import 'package:am_common/am_common.dart';
import '../../widgets/portfolio_overview_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/portfolio_providers.dart';
import '../../cubit/portfolio_analytics_state.dart';
import '../../cubit/portfolio_analytics_cubit.dart';
import '../../cubit/portfolio_cubit.dart';

/// Web-specific portfolio overview page.
/// It uses the global [PortfolioCubit] provided by GlobalPortfolioWrapper.
class PortfolioOverviewWebPage extends ConsumerWidget {
  const PortfolioOverviewWebPage({
    super.key,
    this.portfolioId,
    this.portfolioName,
  });

  final String? portfolioId;
  final String? portfolioName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the active portfolio ID dynamically so it rebuilds on dropdown change
    final activePortfolioId = context.selectedPortfolioId ?? portfolioId;
    final activePortfolioName = context.selectedPortfolioName ?? portfolioName;

    if (activePortfolioId != null) {
      return _PortfolioOverviewView(
        portfolioId: activePortfolioId,
        portfolioName: activePortfolioName,
      );
    }

    return _PortfolioOverviewView(
      portfolioId: activePortfolioId,
      portfolioName: activePortfolioName,
    );
  }
}

class _PortfolioOverviewView extends StatelessWidget {
  const _PortfolioOverviewView({
    this.portfolioId,
    this.portfolioName,
  });

  final String? portfolioId;
  final String? portfolioName;

  @override
  Widget build(BuildContext context) {
    return PortfolioOverviewWidget(
      portfolioId: portfolioId,
    );
  }
}
