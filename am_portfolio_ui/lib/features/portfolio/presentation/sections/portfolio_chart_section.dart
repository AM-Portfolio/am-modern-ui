import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/portfolio_providers.dart';
import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_history_cubit.dart';
import '../cubit/portfolio_intraday_cubit.dart';
import '../cubit/portfolio_state.dart';
import '../widgets/portfolio_history_chart_widget.dart';

/// Self-contained portfolio wealth chart block for Portfolio Overview or Dashboard embed.
///
/// Provides [PortfolioHistoryCubit], [PortfolioIntradayCubit], and a scoped
/// [PortfolioCubit] (list + selection) when not already in the tree.
class PortfolioChartSection extends ConsumerStatefulWidget {
  const PortfolioChartSection({
    super.key,
    this.portfolioId,
    this.height = 360,
    this.embedMode = false,
    this.showPortfolioDropdown = true,
    this.showCandleToggle = true,
    this.showFormatToggle = true,
  });

  final String? portfolioId;
  final double height;
  final bool embedMode;
  final bool showPortfolioDropdown;
  final bool showCandleToggle;
  final bool showFormatToggle;

  @override
  ConsumerState<PortfolioChartSection> createState() =>
      _PortfolioChartSectionState();
}

class _PortfolioChartSectionState extends ConsumerState<PortfolioChartSection> {
  bool _portfolioLoaded = false;

  String _effectivePortfolioId(BuildContext context) {
    if (widget.portfolioId != null && widget.portfolioId!.isNotEmpty) {
      return widget.portfolioId!;
    }
    final selected = context.selectedPortfolioId;
    if (selected != null && selected.isNotEmpty) return selected;
    return 'all';
  }

  @override
  Widget build(BuildContext context) {
    final remoteAsync = ref.watch(portfolioRemoteDataSourceProvider);
    final serviceAsync = ref.watch(portfolioServiceProvider);

    return remoteAsync.when(
      loading: () => SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'Failed to load portfolio chart',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
      data: (remoteDataSource) {
        return serviceAsync.when(
          loading: () => SizedBox(
            height: widget.height,
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => SizedBox(
            height: widget.height,
            child: Center(
              child: Text(
                'Failed to load portfolio services',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
          data: (service) {
            final existingCubit = _tryReadPortfolioCubit(context);
            final existingHistory = _tryReadHistoryCubit(context);
            final existingIntraday = _tryReadIntradayCubit(context);
            if (existingCubit != null) {
              return _ChartProviders(
                remoteDataSource: remoteDataSource,
                portfolioCubit: existingCubit,
                historyCubit: existingHistory,
                intradayCubit: existingIntraday,
                child: _PortfolioChartSectionBody(
                  portfolioId: widget.portfolioId,
                  height: widget.height,
                  embedMode: widget.embedMode,
                  showPortfolioDropdown: widget.showPortfolioDropdown,
                  showCandleToggle: widget.showCandleToggle,
                  showFormatToggle: widget.showFormatToggle,
                  resolvePortfolioId: _effectivePortfolioId,
                ),
              );
            }

            return BlocProvider(
              create: (_) {
                final cubit = PortfolioCubit(service)
                  ..setPortfolioStreamingAllowed(false);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (cubit.isClosed) return;
                  cubit.loadPortfoliosList();
                });
                return cubit;
              },
              child: BlocListener<PortfolioCubit, PortfolioState>(
                listenWhen: (prev, curr) =>
                    curr is PortfolioListLoaded && !_portfolioLoaded,
                listener: (context, state) {
                  if (state is! PortfolioListLoaded || _portfolioLoaded) return;
                  _portfolioLoaded = true;
                  final id = _effectivePortfolioId(context);
                  final cubit = context.read<PortfolioCubit>();
                  if (id == 'all') {
                    cubit.loadAllPortfolios();
                  } else {
                    cubit.loadPortfolioById(id);
                  }
                },
                child: _ChartProviders(
                  remoteDataSource: remoteDataSource,
                  historyCubit: existingHistory,
                  intradayCubit: existingIntraday,
                  child: _PortfolioChartSectionBody(
                    portfolioId: widget.portfolioId,
                    height: widget.height,
                    embedMode: widget.embedMode,
                    showPortfolioDropdown: widget.showPortfolioDropdown,
                    showCandleToggle: widget.showCandleToggle,
                    showFormatToggle: widget.showFormatToggle,
                    resolvePortfolioId: _effectivePortfolioId,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  PortfolioCubit? _tryReadPortfolioCubit(BuildContext context) {
    try {
      return context.read<PortfolioCubit>();
    } catch (_) {
      return null;
    }
  }

  PortfolioHistoryCubit? _tryReadHistoryCubit(BuildContext context) {
    try {
      return context.read<PortfolioHistoryCubit>();
    } catch (_) {
      return null;
    }
  }

  PortfolioIntradayCubit? _tryReadIntradayCubit(BuildContext context) {
    try {
      return context.read<PortfolioIntradayCubit>();
    } catch (_) {
      return null;
    }
  }
}

class _ChartProviders extends StatelessWidget {
  const _ChartProviders({
    required this.remoteDataSource,
    required this.child,
    this.portfolioCubit,
    this.historyCubit,
    this.intradayCubit,
  });

  final dynamic remoteDataSource;
  final Widget child;
  final PortfolioCubit? portfolioCubit;
  final PortfolioHistoryCubit? historyCubit;
  final PortfolioIntradayCubit? intradayCubit;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        if (portfolioCubit != null)
          BlocProvider<PortfolioCubit>.value(value: portfolioCubit!),
        if (historyCubit != null)
          BlocProvider<PortfolioHistoryCubit>.value(value: historyCubit!)
        else
          BlocProvider<PortfolioHistoryCubit>(
            create: (_) => PortfolioHistoryCubit(remoteDataSource),
          ),
        if (intradayCubit != null)
          BlocProvider<PortfolioIntradayCubit>.value(value: intradayCubit!)
        else
          BlocProvider<PortfolioIntradayCubit>(
            create: (_) => PortfolioIntradayCubit(remoteDataSource),
          ),
      ],
      child: child,
    );
  }
}

class _PortfolioChartSectionBody extends ConsumerWidget {
  const _PortfolioChartSectionBody({
    required this.portfolioId,
    required this.height,
    required this.embedMode,
    required this.showPortfolioDropdown,
    required this.showCandleToggle,
    required this.showFormatToggle,
    required this.resolvePortfolioId,
  });

  final String? portfolioId;
  final double height;
  final bool embedMode;
  final bool showPortfolioDropdown;
  final bool showCandleToggle;
  final bool showFormatToggle;
  final String Function(BuildContext context) resolvePortfolioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFrame = ref.watch(appTimeFrameProvider);
    final effectiveId = resolvePortfolioId(context);

    ref.listen(appTimeFrameProvider, (previous, next) {
      if (previous != next) {
        try {
          context.read<PortfolioCubit>().setTimeFrame(next.code);
        } catch (_) {}
      }
    });

    return PortfolioHistoryChartWidget(
      key: ValueKey('portfolio_chart_${effectiveId}_${timeFrame.code}'),
      portfolioId: effectiveId,
      timeFrame: timeFrame,
      height: height,
      embedMode: embedMode,
      showPortfolioDropdown: showPortfolioDropdown,
      showCandleToggle: showCandleToggle,
      showFormatToggle: showFormatToggle,
    );
  }
}
