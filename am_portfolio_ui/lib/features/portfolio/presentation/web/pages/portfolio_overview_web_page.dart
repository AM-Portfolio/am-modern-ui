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
    if (portfolioId != null) {
      final analyticsServiceAsync = ref.watch(portfolioAnalyticsServiceProvider);
      
      return analyticsServiceAsync.when(
        data: (analyticsService) {
          return BlocProvider<PortfolioAnalyticsCubit>(
            create: (context) {
              final cubit = PortfolioAnalyticsCubit(analyticsService);
              cubit.loadSpecificAnalytics(portfolioId!, AnalyticsDataType.sectorAllocation);
              return cubit;
            },
            child: _PortfolioOverviewView(
              userId: userId,
              portfolioId: portfolioId,
              portfolioName: portfolioName,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading analytics service: $error')),
      );
    }

    return _PortfolioOverviewView(
      userId: userId,
      portfolioId: portfolioId,
      portfolioName: portfolioName,
    );
  }
}

class _PortfolioOverviewView extends StatelessWidget {
  const _PortfolioOverviewView({
    required this.userId,
    this.portfolioId,
    this.portfolioName,
  });

  final String userId;
  final String? portfolioId;
  final String? portfolioName;

  @override
  Widget build(BuildContext context) {
    return PortfolioOverviewWidget(
      userId: userId,
      portfolioId: portfolioId,
    );
  }
}
