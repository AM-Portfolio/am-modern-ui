import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:am_common/am_common.dart';
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
  BuildContext? _portfolioBlocContext;
  bool _portfolioServiceMarked = false;
  bool _portfolioListMarked = false;

  String? _portfolioIdFromUrl(BuildContext context) {
    final params = GoRouterState.of(context).pathParameters;
    final id = params['portfolioId'];
    if (id != null && id.isNotEmpty) return id;
    return null;
  }

  bool get _portfolioDetailFetchAllowed =>
      widget.streamingTab == 'Portfolio' || widget.streamingTab == 'Trade';

  bool get _portfolioListNeeded =>
      _portfolioDetailFetchAllowed || _portfolioIdFromUrl(context) != null;

  void _rememberPortfolioSelection(
    String id,
    String name, {
    bool notifyUrl = true,
  }) {
    if (_selectedPortfolioId == id && _selectedPortfolioName == name) return;

    setState(() {
      _selectedPortfolioId = id;
      _selectedPortfolioName = name;
    });

    context.selectPortfolio(id, name);

    if (notifyUrl) {
      widget.onPortfolioChanged?.call(id, name);
    }
  }

  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _isInit = false;
      final inheritedId = context.selectedPortfolioId;
      final inheritedName = context.selectedPortfolioName;
      if (inheritedId != null) {
        _selectedPortfolioId = inheritedId;
        _selectedPortfolioName = inheritedName;
      }
    }
  }

  void _selectPortfolio(
    BuildContext innerContext,
    String id,
    String name, {
    bool notifyUrl = true,
  }) {
    _rememberPortfolioSelection(id, name, notifyUrl: notifyUrl);

    if (!_portfolioDetailFetchAllowed) return;

    try {
      final cubit = innerContext.read<PortfolioCubit>();
      if (id == 'all') {
        cubit.loadAllPortfolios();
      } else {
        if (_portfolioStreamingAllowed) {
          cubit.subscribeToPortfolioUpdates(
            portfolioId: id,
            forceResubscribe: true,
          );
        }
        cubit.loadPortfolioById(id);
      }
    } catch (_) {
      // PortfolioCubit not ready yet — selection stored for when service loads.
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

    if (urlId.startsWith('mock-')) {
      final fallback = portfolios.first;
      _selectPortfolio(
        innerContext,
        fallback.portfolioId,
        fallback.portfolioName,
      );
      return;
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
        final cubit = _readPortfolioCubit();
        if (cubit != null) _syncPortfolioStreaming(cubit);
      });
    }
  }

  PortfolioCubit? _readPortfolioCubit() {
    final innerContext = _portfolioBlocContext;
    if (innerContext == null) return null;
    try {
      return innerContext.read<PortfolioCubit>();
    } catch (_) {
      return null;
    }
  }

  void _syncPortfolioStreaming(PortfolioCubit cubit) {
    cubit.setPortfolioStreamingAllowed(_portfolioStreamingAllowed);

    if (!_portfolioDetailFetchAllowed) return;

    final hasList = cubit.state is PortfolioListLoaded ||
        cubit.state.portfolioList != null;

    if (_portfolioListNeeded && !hasList && cubit.state is! PortfolioListLoading) {
      cubit.loadPortfoliosList();
    }

    if (_selectedPortfolioId != null) {
      if (_selectedPortfolioId == 'all') {
        cubit.loadAllPortfolios();
      } else {
        if (_portfolioStreamingAllowed) {
          cubit.subscribeToPortfolioUpdates(
            portfolioId: _selectedPortfolioId,
            forceResubscribe: true,
          );
        }
        cubit.loadPortfolioById(_selectedPortfolioId!);
      }
    } else if (hasList &&
        cubit.state.portfolioList!.portfolios.isNotEmpty) {
      final inner = _portfolioBlocContext;
      if (inner == null) return;
      final first = cubit.state.portfolioList!.portfolios.first;
      _selectPortfolio(inner, first.portfolioId, first.portfolioName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final portfolioServiceAsync = ref.watch(portfolioServiceProvider);
    final analyticsServiceAsync = ref.watch(portfolioAnalyticsServiceProvider);
    final remoteDataSourceAsync = ref.watch(portfolioRemoteDataSourceProvider);
    final urlPortfolioId = _portfolioIdFromUrl(context);
    final shellChild = widget.child;

    final isLoading = portfolioServiceAsync.isLoading ||
        analyticsServiceAsync.isLoading ||
        remoteDataSourceAsync.isLoading;
    if (isLoading) {
      return shellChild;
    }

    final hasError = portfolioServiceAsync.hasError ||
        analyticsServiceAsync.hasError ||
        remoteDataSourceAsync.hasError;
    if (hasError) {
      return shellChild;
    }

    final service = portfolioServiceAsync.requireValue;
    final analyticsService = analyticsServiceAsync.requireValue;
    final remoteDataSource = remoteDataSourceAsync.requireValue;

    if (!_portfolioServiceMarked) {
      _portfolioServiceMarked = true;
      BootTrace.instance.mark('portfolio_service_ready');
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<PortfolioCubit>(
          create: (context) {
            final cubit = PortfolioCubit(service);
            cubit.setPortfolioStreamingAllowed(_portfolioStreamingAllowed);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _syncPortfolioStreaming(cubit);
            });
            return cubit;
          },
        ),
        BlocProvider<PortfolioAnalyticsCubit>(
          create: (context) => PortfolioAnalyticsCubit(analyticsService),
        ),
        BlocProvider<PortfolioHistoryCubit>(
          create: (context) => PortfolioHistoryCubit(remoteDataSource),
        ),
      ],
      child: Builder(
        builder: (innerContext) {
          _portfolioBlocContext = innerContext;
          return BlocListener<PortfolioCubit, PortfolioState>(
            listener: (context, state) {
              if (state is PortfolioListLoaded) {
                if (!_portfolioListMarked) {
                  _portfolioListMarked = true;
                  BootTrace.instance.mark('portfolio_list_done');
                }
                if (urlPortfolioId != null) {
                  _validateUrlPortfolio(innerContext, state);
                  return;
                }

                if (_selectedPortfolioId != null &&
                    _portfolioDetailFetchAllowed) {
                  _selectPortfolio(
                    innerContext,
                    _selectedPortfolioId!,
                    _selectedPortfolioName ??
                        state.portfolioList!.portfolios
                            .firstWhere(
                              (p) => p.portfolioId == _selectedPortfolioId,
                              orElse: () =>
                                  state.portfolioList!.portfolios.first,
                            )
                            .portfolioName,
                    notifyUrl: false,
                  );
                  return;
                }

                if (_selectedPortfolioId == null &&
                    state.portfolioList!.portfolios.isNotEmpty) {
                  final first = state.portfolioList!.portfolios.first;
                  if (_portfolioDetailFetchAllowed) {
                    _selectPortfolio(
                      innerContext,
                      first.portfolioId,
                      first.portfolioName,
                    );
                  } else {
                    _rememberPortfolioSelection(
                      first.portfolioId,
                      first.portfolioName,
                    );
                  }
                }
              }
            },
            child: shellChild,
          );
        },
      ),
    );
  }
}
