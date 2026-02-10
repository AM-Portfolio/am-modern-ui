import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_state.dart';
import '../../providers/portfolio_providers.dart';
import '../../internal/domain/entities/portfolio_list.dart';
import 'package:am_common/core/utils/logger.dart';
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
    _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    try {
      final secureStorage = GetIt.instance<SecureStorageService>();
      final token = await secureStorage.getAccessToken();
      
      if (token != null) {
        final stompClient = GetIt.instance<AmStompClient>();
        // Ensure configured (already done in main, but safe to check or re-config if needed)
        // main.dart configures the URL.
        
        CommonLogger.info('Initializing WebSocket connection with user token...', tag: 'GlobalPortfolioWrapper');
        debugPrint('GlobalPortfolioWrapper: Initializing WebSocket connection with token: ${token.substring(0, 10)}...');
        stompClient.connect(
          headers: {'Authorization': 'Bearer $token'},
          onConnect: (frame) { 
             CommonLogger.info('STOMP: Connected successfully', tag: 'GlobalPortfolioWrapper');
             debugPrint('GlobalPortfolioWrapper: STOMP Connected successfully!');
             debugPrint('GlobalPortfolioWrapper: STOMP Headers: ${frame.headers}');
             CommonLogger.info('STOMP Session: ${frame.headers}', tag: 'GlobalPortfolioWrapper');
             
             // Trigger initial calculation
             final traceId = const Uuid().v4();
             stompClient.send(
               destination: '/app/portfolio/calculate',
               headers: {'X-Correlation-Id': traceId},
               body: '{"userId": "${widget.userId}"}', 
             );
          },
          onWebSocketError: (err) {
             CommonLogger.error('STOMP Error', error: err, tag: 'GlobalPortfolioWrapper');
             debugPrint('GlobalPortfolioWrapper: STOMP Error: $err');
          },
        );
      } else {
        CommonLogger.warning('No access token found for WebSocket connection', tag: 'GlobalPortfolioWrapper');
      }
    } catch (e) {
      CommonLogger.error('Failed to connect WebSocket', error: e, tag: 'GlobalPortfolioWrapper');
    }
  }

  @override
  void dispose() {
    // Optionally disconnect on logout/dispose
    GetIt.instance<AmStompClient>().disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    CommonLogger.debug('Building GlobalPortfolioWrapper with userId: ${widget.userId}', tag: 'GlobalPortfolioWrapper');
    final portfolioServiceAsync = ref.watch(portfolioServiceProvider);
    
    CommonLogger.debug('PortfolioServiceAsync state: $portfolioServiceAsync', tag: 'GlobalPortfolioWrapper');

    return portfolioServiceAsync.when(
      data: (service) => BlocProvider(
        create: (context) {
           final cubit = PortfolioCubit(service);
           cubit.loadPortfoliosList(widget.userId);
           // Subscription will be handled by individual pages that need real-time updates
           return cubit;
        },
        child: BlocListener<PortfolioCubit, PortfolioState>(
          listener: (context, state) {
            if (state is PortfolioListLoaded && _selectedPortfolioId == null) {
              if (state.portfolioList.portfolios.isNotEmpty) {
                 final first = state.portfolioList.portfolios.first;
                 setState(() {
                   _selectedPortfolioId = first.portfolioId;
                   _selectedPortfolioName = first.portfolioName;
                 });
                 widget.onPortfolioChanged?.call(first.portfolioId, first.portfolioName);
              }
            }
          },
          child: _SelectedPortfolioProvider(
            selectedId: _selectedPortfolioId,
            selectedName: _selectedPortfolioName,
            onSelect: (id, name) {
               setState(() {
                 _selectedPortfolioId = id;
                 _selectedPortfolioName = name;
               });
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
