import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_state.dart';
import '../cubit/portfolio_analytics_cubit.dart';
import '../cubit/portfolio_history_cubit.dart';
import '../../providers/portfolio_providers.dart';

/// A wrapper that provides a global [PortfolioCubit] and handles
/// initial portfolio selection synced with URL path parameters.
class GlobalPortfolioWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final Function(String, String)? onPortfolioChanged;
  /// Active app-shell tab title (e.g. `Dashboard`, `Portfolio`).
  final String streamingTab;

  const GlobalPortfolioWrapper({
    required this.child,
    this.onPortfolioChanged,
    this.streamingTab = 'Dashboard',
    super.key,
  });

  @override
  ConsumerState<GlobalPortfolioWrapper> createState() =>
      _GlobalPortfolioWrapperState();
}

class _GlobalPortfolioWrapperState
    extends ConsumerState<GlobalPortfolioWrapper> {
  String? _selectedPortfolioId;
  String? _selectedPortfolioName;
  String? _validatedUrlPortfolioId;

  String? _portfolioIdFromUrl(BuildContext context) {
    final params = GoRouterState.of(context).pathParameters;
    final id = params['portfolioId'];
    if (id != null && id.isNotEmpty) return id;
    return null;
  }

  void _selectPortfolio(
    BuildContext innerContext,
    String id,
    String name, {
    bool notifyUrl = true,
  }) {
    if (_selectedPortfolioId == id && _selectedPortfolioName == name) return;

    setState(() {
      _selectedPortfolioId = id;
      _selectedPortfolioName = name;
    });

    if (id == 'all') {
      innerContext.read<PortfolioCubit>().loadAllPortfolios();
    } else {
      innerContext.read<PortfolioCubit>().subscribeToPortfolioUpdates(
            portfolioId: id,
            forceResubscribe: true,
          );
      innerContext.read<PortfolioCubit>().loadPortfolioById(id);
    }

    if (notifyUrl) {
      widget.onPortfolioChanged?.call(id, name);
    }
  }

  void _validateUrlPortfolio(
    BuildContext innerContext,
    PortfolioListLoaded state,
  ) {
    final urlId = _portfolioIdFromUrl(context);
    if (urlId == null || _validatedUrlPortfolioId == urlId) return;

    _validatedUrlPortfolioId = urlId;
    final portfolios = state.portfolioList!.portfolios;
    if (portfolios.isEmpty) return;

    if (urlId == 'all') {
      _selectPortfolio(innerContext, 'all', 'All Portfolios', notifyUrl: false);
      return;
    }

    for (final p in portfolios) {
      if (p.portfolioId == urlId) {
        _selectPortfolio(innerContext, p.portfolioId, p.portfolioName, notifyUrl: false);
        return;
      }
    }

    final fallback = portfolios.first;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Portfolio not found or access denied. Showing default.'),
        ),
      );
    }
    _selectPortfolio(
      innerContext,
      fallback.portfolioId,
      fallback.portfolioName,
    );
  }

  bool get _portfolioStreamingAllowed => widget.streamingTab == 'Portfolio';

  @override
  void didUpdateWidget(GlobalPortfolioWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamingTab != widget.streamingTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final cubit = _tryReadCubit();
        if (cubit != null) _syncPortfolioStreaming(cubit);
      });
    }
  }

  PortfolioCubit? _tryReadCubit() {
    try {
      return context.read<PortfolioCubit>();
    } catch (_) {
      return null;
    }
  }

  void _syncPortfolioStreaming(PortfolioCubit cubit) {
    cubit.setPortfolioStreamingAllowed(_portfolioStreamingAllowed);
    if (_portfolioStreamingAllowed && _selectedPortfolioId != null) {
      cubit.subscribeToPortfolioUpdates(
        portfolioId: _selectedPortfolioId,
        forceResubscribe: true,
      );
      cubit.loadPortfolioById(_selectedPortfolioId!);
    }
  }

  void _maybeSubscribe(PortfolioCubit cubit, String portfolioId) {
    if (!_portfolioStreamingAllowed) return;
    cubit.subscribeToPortfolioUpdates(
      portfolioId: portfolioId,
      forceResubscribe: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final portfolioServiceAsync = ref.watch(portfolioServiceProvider);
    final analyticsServiceAsync = ref.watch(portfolioAnalyticsServiceProvider);
    final urlPortfolioId = _portfolioIdFromUrl(context);

    if (portfolioServiceAsync.isLoading || analyticsServiceAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (portfolioServiceAsync.hasError) {
      return Scaffold(body: Center(child: Text('Error: ${portfolioServiceAsync.error}')));
    }
    if (analyticsServiceAsync.hasError) {
      return Scaffold(body: Center(child: Text('Error: ${analyticsServiceAsync.error}')));
    }

    final service = portfolioServiceAsync.value!;
    final analyticsService = analyticsServiceAsync.value!;

    return MultiBlocProvider(
      providers: [
        BlocProvider<PortfolioCubit>(
          create: (context) {
            final cubit = PortfolioCubit(service);
            cubit.setPortfolioStreamingAllowed(_portfolioStreamingAllowed);
            cubit.loadPortfoliosList();
            return cubit;
          },
        ),
        BlocProvider<PortfolioAnalyticsCubit>(
          create: (context) => PortfolioAnalyticsCubit(analyticsService),
        ),
        BlocProvider<PortfolioHistoryCubit>(
          create: (context) => PortfolioHistoryCubit(
            ref.read(portfolioRemoteDataSourceProvider).requireValue,
          ),
        ),
      ],
      child: Builder(
        builder: (innerContext) => BlocListener<PortfolioCubit, PortfolioState>(
          listener: (context, state) {
            if (state is PortfolioListLoaded) {
              if (urlPortfolioId != null) {
                _validateUrlPortfolio(innerContext, state);
                return;
              }

              if (_selectedPortfolioId == null &&
                  state.portfolioList!.portfolios.isNotEmpty) {
                final first = state.portfolioList!.portfolios.first;
                _selectPortfolio(
                  innerContext,
                  first.portfolioId,
                  first.portfolioName,
                );
              }
            }
          },
          child: _SelectedPortfolioProvider(
            selectedId: _selectedPortfolioId,
            selectedName: _selectedPortfolioName,
            onSelect: (id, name) =>
                _selectPortfolio(innerContext, id, name, notifyUrl: true),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

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
    return context
        .dependOnInheritedWidgetOfExactType<_SelectedPortfolioProvider>();
  }

  @override
  bool updateShouldNotify(_SelectedPortfolioProvider oldWidget) {
    return oldWidget.selectedId != selectedId ||
        oldWidget.selectedName != selectedName;
  }
}

extension PortfolioSelectionExtension on BuildContext {
  String? get selectedPortfolioId =>
      _SelectedPortfolioProvider.of(this)?.selectedId;
  String? get selectedPortfolioName =>
      _SelectedPortfolioProvider.of(this)?.selectedName;
  void selectPortfolio(String id, String name) =>
      _SelectedPortfolioProvider.of(this)?.onSelect(id, name);
}
