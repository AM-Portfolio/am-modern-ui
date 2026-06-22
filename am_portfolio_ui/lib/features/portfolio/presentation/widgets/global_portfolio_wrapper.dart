import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/am_common.dart';
import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_state.dart';
import '../../providers/portfolio_providers.dart';

/// A wrapper that provides a global [PortfolioCubit] and handles
/// initial portfolio selection. Sync is now handled at the root level.
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

    return portfolioServiceAsync.when(
      data: (service) {
        return BlocProvider<PortfolioCubit>(
          create: (context) {
            final cubit = PortfolioCubit(service);
            cubit.setPortfolioStreamingAllowed(_portfolioStreamingAllowed);
            cubit.loadPortfoliosList();
            return cubit;
          },
          child: Builder(
            builder: (innerContext) => BlocListener<PortfolioCubit, PortfolioState>(
              listener: (context, state) {
                if (state is PortfolioListLoaded &&
                    _selectedPortfolioId == null) {
                  if (state.portfolioList!.portfolios.isNotEmpty) {
                    final first = state.portfolioList!.portfolios.first;
                    setState(() {
                      _selectedPortfolioId = first.portfolioId;
                      _selectedPortfolioName = first.portfolioName;
                    });

                    _maybeSubscribe(
                      innerContext.read<PortfolioCubit>(),
                      first.portfolioId,
                    );

                    if (_portfolioStreamingAllowed) {
                      innerContext
                          .read<PortfolioCubit>()
                          .loadPortfolioById(first.portfolioId);
                    }

                    widget.onPortfolioChanged?.call(
                      first.portfolioId,
                      first.portfolioName,
                    );
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
                  final cubit = innerContext.read<PortfolioCubit>();
                  _maybeSubscribe(cubit, id);
                  if (_portfolioStreamingAllowed) {
                    cubit.loadPortfolioById(id);
                  }

                  widget.onPortfolioChanged?.call(id, name);
                },
                child: widget.child,
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
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
