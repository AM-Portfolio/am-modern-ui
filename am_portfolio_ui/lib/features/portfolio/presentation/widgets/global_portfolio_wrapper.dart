import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_state.dart';
import '../../providers/portfolio_providers.dart';
import '../../internal/domain/entities/portfolio_list.dart';
import 'package:am_common/am_common.dart';
import 'package:am_common/am_common.dart' show AmStompClient, SecureStorageService;
import 'package:get_it/get_it.dart';
import 'gmail_sync/gmail_connect_button.dart';

/// Wraps the authenticated part of the app to provide PortfolioCubit globally
class GlobalPortfolioWrapper extends ConsumerStatefulWidget {
  const GlobalPortfolioWrapper({
    required this.userId,
    required this.child,
    this.onPortfolioChanged,
    super.key,
  });

  final String userId;
  final Widget child;
  final Function(String, String)? onPortfolioChanged;

  @override
  ConsumerState<GlobalPortfolioWrapper> createState() => _GlobalPortfolioWrapperState();
}

class _GlobalPortfolioWrapperState extends ConsumerState<GlobalPortfolioWrapper> {
  // We can track selection here or rely on Cubit if we enhance it.
  // For now, let's track it here to pass down to AppShell if needed, 
  // OR just let the Cubit state be the source of truth if we used it that way.
  // But PortfolioCubit state is simpler (ListLoaded).  
  // So we'll maintain the "Selected" state here or in a separate provider.
  // Actually, keeping it simple: This wrapper JUST initializes the Cubit.
  // Selection logic can be handled by the AppShell or a shared provider.
  // Let's keep the "auto-select first" logic here.
  
  String? _selectedPortfolioId;
  String? _selectedPortfolioName;

  @override
  void initState() {
    super.initState();
    // Connection is now managed centrally by StompConnectionCubit in AppShell
  }

  @override
  void dispose() {
    try {
      final stompClient = GetIt.instance<AmStompClient>();
      if (stompClient.isConnected && _selectedPortfolioId != null) {
        final body = '{"userId": "${widget.userId}", "portfolioId": "$_selectedPortfolioId"}';
        CommonLogger.info('Sending unsubscribe command for portfolio: $_selectedPortfolioId', tag: 'GlobalPortfolioWrapper');
        stompClient.send(
          destination: '/app/portfolio/unsubscribe',
          body: body,
        );
      }
    } catch (e) {
      CommonLogger.error('Failed to send unsubscribe command', error: e, tag: 'GlobalPortfolioWrapper');
    }
    super.dispose();
  }

  void _triggerPortfolioCalculation(String portfolioId) {
    try {
      final stompClient = GetIt.instance<AmStompClient>();
      if (stompClient.isConnected) {
        final traceId = const Uuid().v4();
        final body = '{"userId": "${widget.userId}", "portfolioId": "$portfolioId"}';
        
        CommonLogger.info('Triggering calculation for portfolio: $portfolioId', tag: 'GlobalPortfolioWrapper');
        
        stompClient.send(
          destination: '/app/portfolio/subscribe',
          headers: {'X-Correlation-Id': traceId},
          body: body,
        );
      } else {
        CommonLogger.warning('Cannot trigger calculation: WebSocket not connected', tag: 'GlobalPortfolioWrapper');
      }
    } catch (e) {
      CommonLogger.error('Failed to trigger portfolio calculation', error: e, tag: 'GlobalPortfolioWrapper');
    }
  }

  @override
  Widget build(BuildContext context) {
    CommonLogger.debug('Building GlobalPortfolioWrapper with userId: ${widget.userId}', tag: 'GlobalPortfolioWrapper');
    final portfolioServiceAsync = ref.watch(portfolioServiceProvider);
    
    CommonLogger.debug('PortfolioServiceAsync state: $portfolioServiceAsync', tag: 'GlobalPortfolioWrapper');

    return portfolioServiceAsync.when(
      data: (service) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) {
               final cubit = PortfolioCubit(service);
               cubit.loadPortfoliosList(widget.userId);
               return cubit;
            },
          ),
        ],
        child: MultiBlocListener(
          listeners: [
            // Listen for Portfolio List loading
            BlocListener<PortfolioCubit, PortfolioState>(
              listener: (context, state) {
                if (state is PortfolioListLoaded && _selectedPortfolioId == null) {
                  if (state.portfolioList.portfolios.isNotEmpty) {
                     final first = state.portfolioList.portfolios.first;
                     setState(() {
                       _selectedPortfolioId = first.portfolioId;
                       _selectedPortfolioName = first.portfolioName;
                     });
                     // Trigger calculation if connected, otherwise the Connection Listener below will handle it
                     _triggerPortfolioCalculation(first.portfolioId);
                     widget.onPortfolioChanged?.call(first.portfolioId, first.portfolioName);
                  }
                }
              },
            ),
            // Listen for WebSocket Connection Success
            BlocListener<StompConnectionCubit, StompConnectionState>(
              listener: (context, state) {
                if (state is StompConnected && _selectedPortfolioId != null) {
                  CommonLogger.info('WebSocket Connected! Re-triggering portfolio calculation...', tag: 'GlobalPortfolioWrapper');
                  _triggerPortfolioCalculation(_selectedPortfolioId!);
                }
              },
            ),
          ],
          child: _SelectedPortfolioProvider(
            selectedId: _selectedPortfolioId,
            selectedName: _selectedPortfolioName,
            onSelect: (id, name) {
               setState(() {
                 _selectedPortfolioId = id;
                 _selectedPortfolioName = name;
               });
               _triggerPortfolioCalculation(id);
               widget.onPortfolioChanged?.call(id, name);
            },
            child: widget.child, 
          ),
        ),
      ),
      loading: () {
        CommonLogger.debug('Portfolio Service is LOADING...', tag: 'GlobalPortfolioWrapper');
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing Portfolio Service...'),
              ],
            ),
          ),
        );
      },
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Failed to initialize portfolio service: $err')),
      ),
    );
  }
}

// InheritedWidget or similar to pass selection down safely?
// Actually, using an InheritedWidget allows deep descendants (AppShell) to access selection
class _SelectedPortfolioProvider extends InheritedWidget {
  final String? selectedId;
  final String? selectedName;
  final Function(String, String) onSelect;

  const _SelectedPortfolioProvider({
    required this.selectedId,
    required this.selectedName,
    required this.onSelect,
    required super.child,
  });

  static _SelectedPortfolioProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_SelectedPortfolioProvider>();
  }

  @override
  bool updateShouldNotify(_SelectedPortfolioProvider oldWidget) {
    return selectedId != oldWidget.selectedId || selectedName != oldWidget.selectedName;
  }
}

// Public extension for easier access
extension PortfolioSelectionContext on BuildContext {
  String? get selectedPortfolioId => _SelectedPortfolioProvider.of(this)?.selectedId;
  String? get selectedPortfolioName => _SelectedPortfolioProvider.of(this)?.selectedName;
  void selectPortfolio(String id, String name) => _SelectedPortfolioProvider.of(this)?.onSelect(id, name);
}

