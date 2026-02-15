import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:get_it/get_it.dart';
import 'package:am_common/am_common.dart';

import 'package:am_portfolio_ui/features/portfolio/presentation/cubit/portfolio_analytics_state.dart';
import '../../widgets/portfolio_overview_widget.dart';
// import '../../../../basket/presentation/widgets/basket_explorer.dart'; // Removed as per request to move it
import '../../widgets/gmail_sync/gmail_connect_button.dart';

import 'package:am_design_system/am_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/portfolio_providers.dart';
import '../../cubit/portfolio_analytics_cubit.dart';
import '../../cubit/portfolio_cubit.dart';

/// Web-specific portfolio overview page
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
    // Watch both services
    final analyticsServiceAsync = ref.watch(portfolioAnalyticsServiceProvider);
    final portfolioServiceAsync = ref.watch(portfolioServiceProvider);

    // If we have a portfolio ID, we act as a provider source
    if (portfolioId != null) {
      return analyticsServiceAsync.when(
        data: (analyticsService) {
          return portfolioServiceAsync.when(
            data: (portfolioService) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider<PortfolioAnalyticsCubit>(
                    create: (context) {
                      final cubit = PortfolioAnalyticsCubit(analyticsService);
                      cubit.loadSpecificAnalytics(portfolioId!, AnalyticsDataType.sectorAllocation);
                      return cubit;
                    },
                  ),
                  BlocProvider<PortfolioCubit>(
                    create: (context) {
                      final cubit = PortfolioCubit(portfolioService);
                      cubit.loadPortfolioSummaryOnly(userId, portfolioId!);
                      return cubit;
                    },
                  ),
                ],
                child: _PortfolioOverviewView(
                  userId: userId,
                  portfolioId: portfolioId,
                  portfolioName: portfolioName,
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error loading portfolio service: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
           CommonLogger.error(
            'Failed to load analytics service',
            tag: 'PortfolioOverviewWebPage',
            error: error,
            stackTrace: stack,
          );
          return Center(child: Text('Error loading dependencies: $error'));
        },
      );
    }

    // Fallback if no portfolio selected (though logically shouldn't happen in this flow)
    return _PortfolioOverviewView(
      userId: userId,
      portfolioId: portfolioId,
      portfolioName: portfolioName,
    );
  }
}

class _PortfolioOverviewView extends StatefulWidget {
  const _PortfolioOverviewView({
    required this.userId,
    this.portfolioId,
    this.portfolioName,
  });

  final String userId;
  final String? portfolioId;
  final String? portfolioName;

  @override
  State<_PortfolioOverviewView> createState() => _PortfolioOverviewViewState();
}

class _PortfolioOverviewViewState extends State<_PortfolioOverviewView> {
  
  @override
  void initState() {
    super.initState();
    CommonLogger.info('PortfolioOverviewWebPage: initState - Subscribing', tag: 'PortfolioOverviewWebPage');
    // Start subscription when page initializes
    context.read<PortfolioCubit>().subscribeToPortfolioUpdates(widget.userId);
  }

  @override
  void dispose() {
    CommonLogger.info('PortfolioOverviewWebPage: dispose - Unsubscribing', tag: 'PortfolioOverviewWebPage');
    // End subscription when page is disposed (navigated away)
    context.read<PortfolioCubit>().unsubscribeFromPortfolioUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  widget.portfolioName ?? 'My Portfolio',
                  style: Theme.of(context).textTheme.headlineMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              const GmailConnectButton(),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PortfolioOverviewWidget(
              userId: widget.userId,
              portfolioId: widget.portfolioId,
            ),
          ),
        ],
      ),
    );
  }
}
