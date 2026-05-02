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
  final String userId;
  final Function(String, String)? onPortfolioChanged;

  const GlobalPortfolioWrapper({
    required this.child,
    required this.userId,
    this.onPortfolioChanged,
    super.key,
  });

  @override
  ConsumerState<GlobalPortfolioWrapper> createState() => _GlobalPortfolioWrapperState();
}

class _GlobalPortfolioWrapperState extends ConsumerState<GlobalPortfolioWrapper> {
  String? _selectedPortfolioId;
  String? _selectedPortfolioName;

  @override
  Widget build(BuildContext context) {
    final portfolioServiceAsync = ref.watch(portfolioServiceProvider);
    
    return portfolioServiceAsync.when(
      data: (service) {
        return BlocProvider<PortfolioCubit>(
          create: (context) {
            final cubit = PortfolioCubit(service);
            cubit.loadPortfoliosList(widget.userId);
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
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
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
    return context.dependOnInheritedWidgetOfExactType<_SelectedPortfolioProvider>();
  }

  @override
  bool updateShouldNotify(_SelectedPortfolioProvider oldWidget) {
    return oldWidget.selectedId != selectedId || oldWidget.selectedName != selectedName;
  }
}

extension PortfolioSelectionExtension on BuildContext {
  String? get selectedPortfolioId => _SelectedPortfolioProvider.of(this)?.selectedId;
  String? get selectedPortfolioName => _SelectedPortfolioProvider.of(this)?.selectedName;
  void selectPortfolio(String id, String name) => _SelectedPortfolioProvider.of(this)?.onSelect(id, name);
}
