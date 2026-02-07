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
                      cubit.loadPortfolioById(userId, portfolioId!);
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
    _waitForConnectionAndTrigger();
  }

  void _waitForConnectionAndTrigger() {
    final stompClient = GetIt.instance<AmStompClient>();
    
    // If already connected, trigger immediately
    if (stompClient.isConnected) {
      _sendCalculationRequest(stompClient);
    } else {
      // Otherwise, listen for connection
      debugPrint('PortfolioOverview: Waiting for WebSocket connection...');
      CommonLogger.info('Waiting for WebSocket connection...', tag: 'PortfolioOverviewWebPage');
      
      // Use a one-time subscription to the status stream
      final subscription = stompClient.status.listen(null);
      subscription.onData((status) {
        if (status == StompStatus.connected) {
          debugPrint('PortfolioOverview: Connected! Triggering calculation.');
          _subscribeToUpdates(stompClient);
          _sendCalculationRequest(stompClient);
          subscription.cancel(); // Stop listening after success
        }
      });
    }
  }

  void _subscribeToUpdates(AmStompClient client) {
     debugPrint('PortfolioOverview: Subscribing to /user/queue/portfolio');
     client.subscribe('/user/queue/portfolio');
     
     // Listen to the stream for updates
       client.messages.listen((frame) {
        final destination = frame.headers['destination'];
        if (destination != null && destination.contains('portfolio')) {
          if (frame.body != null) {
            try {
               debugPrint('PortfolioOverview: Received WebSocket Message: ${frame.body}');
               final json = jsonDecode(frame.body!);
               
               debugPrint('PortfolioOverview: Parsed JSON. CurrentValue: ${json['currentValue']}, Investment: ${json['investmentValue']}');
               
               if (mounted) {
                 context.read<PortfolioCubit>().updateSummaryFromSocket(json);
                 CommonLogger.info('Updated portfolio from WebSocket', tag: 'PortfolioOverviewWebPage');
                 
                 // Show a snackbar for visibility as requested
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('Portfolio Updated: ₹${json['currentValue']}'),
                     duration: const Duration(seconds: 2),
                     behavior: SnackBarBehavior.floating,
                   ),
                 );
               }
            } catch (e) {
              debugPrint('PortfolioOverview: Error parsing WebSocket message: $e');
              CommonLogger.error('Failed to parse WS message', error: e, tag: 'PortfolioOverviewWebPage');
            }
          }
        }
      });
  }

  void _sendCalculationRequest(AmStompClient client) {
    try {
      final traceId = const Uuid().v4();
      CommonLogger.info('Triggering Portfolio Calculation [TraceID: $traceId]', tag: 'PortfolioOverviewWebPage');
      
      client.send(
        destination: '/app/portfolio/calculate',
        headers: {'X-Correlation-Id': traceId},
        body: '{"userId": "${widget.userId}"}',
      );
    } catch (e) {
      CommonLogger.error('Failed to send calculation request', error: e, tag: 'PortfolioOverviewWebPage');
    }
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
            ),
          ),
        ],
      ),
    );
  }
}
