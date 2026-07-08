import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';

import '../../internal/data/dtos/portfolio_snapshot_dto.dart';
import '../../internal/domain/entities/portfolio_list.dart';
import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_history_cubit.dart';
import '../cubit/portfolio_history_state.dart';
import '../cubit/portfolio_state.dart';
import 'global_portfolio_wrapper.dart';

// ignore_for_file: unused_import
export '../../internal/data/dtos/portfolio_snapshot_dto.dart';

/// A self-contained widget that renders the portfolio history chart.
///
/// Features:
/// - Always shows portfolio switcher tabs ([All Portfolios], [Dhan], [Zerodha]…)
/// - Reacts to global portfolio selection changes
/// - Carries forward last known wealth on days with missing data (no zero-dips)
/// - Reloads on both portfolioId and timeFrame changes
class PortfolioHistoryChartWidget extends ConsumerStatefulWidget {
  const PortfolioHistoryChartWidget({
    super.key,
    required this.portfolioId,
    required this.timeFrame,
    this.height = 320,
  });

  final String? portfolioId;
  final TimeFrame timeFrame;
  final double height;

  @override
  ConsumerState<PortfolioHistoryChartWidget> createState() =>
      _PortfolioHistoryChartWidgetState();
}

class _PortfolioHistoryChartWidgetState
    extends ConsumerState<PortfolioHistoryChartWidget> {
  // ── Local State ──────────────────────────────────────────────────────────
  String? _localSelectedId;
  String? _localSelectedName;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _scheduleLoad();
  }

  @override
  void didUpdateWidget(PortfolioHistoryChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload whenever portfolioId OR timeFrame changes
    if (oldWidget.portfolioId != widget.portfolioId ||
        oldWidget.timeFrame != widget.timeFrame) {
      if (oldWidget.portfolioId != widget.portfolioId) {
        _localSelectedId = null;
        _localSelectedName = null;
      }
      context.read<PortfolioHistoryCubit>().invalidate();
      _scheduleLoad();
    }
  }

  /// Schedule load after the current frame so that inherited widgets
  /// (GlobalPortfolioWrapper → context.selectedPortfolioId) are ready.
  void _scheduleLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  void _load() {
    // Chart fetches data based on local selection first, falls back to global
    final selectedId = _localSelectedId ?? context.selectedPortfolioId;
    final id = (selectedId == null || selectedId == 'all')
        ? widget.portfolioId
        : selectedId;
    context.read<PortfolioHistoryCubit>().loadHistory(
      id,
      widget.timeFrame,
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Listen to the global PortfolioCubit so that when the user taps a tab
    // inside the chart (which calls context.selectPortfolio → changes
    // _SelectedPortfolioProvider → triggers PortfolioCubit.loadPortfolioById),
    // we invalidate and reload the chart data automatically.
    return BlocListener<PortfolioCubit, PortfolioState>(
      listenWhen: (prev, curr) {
        if (curr is! PortfolioLoaded) return false;
        if (prev is PortfolioLoaded) {
          return prev.portfolioId != curr.portfolioId;
        }
        return true;
      },
      listener: (context, state) {
        // Global portfolio changed. Reset local selection so chart matches global.
        setState(() {
          _localSelectedId = null;
          _localSelectedName = null;
        });
        context.read<PortfolioHistoryCubit>().invalidate();
        _load();
      },
      child: BlocBuilder<PortfolioHistoryCubit, PortfolioHistoryState>(
        builder: (context, state) {
          if (state is PortfolioHistoryLoading) return _buildShimmer();
          if (state is PortfolioHistoryError) return _buildError(state.message);
          if (state is PortfolioHistoryLoaded) return _buildContent(state);
          return _buildShimmer();
        },
      ),
    );
  }

  // ── Portfolio Tab Switcher ───────────────────────────────────────────────

  /// Builds tabs from the global portfolio list.
  /// Uses a [Builder] so that [ctx.selectedPortfolioId] is resolved against
  /// the [_SelectedPortfolioProvider] InheritedWidget and updates whenever
  /// a tab is tapped—without relying on a BlocBuilder to refresh the highlight.
  Widget _buildPortfolioTabs() {
    return Builder(
      builder: (ctx) {
        return BlocBuilder<PortfolioCubit, PortfolioState>(
          buildWhen: (prev, curr) => prev.portfolioList != curr.portfolioList,
          builder: (bCtx, state) {
            final portfolios = state.portfolioList?.portfolios ?? [];
            if (portfolios.isEmpty) return const SizedBox.shrink();

            // Always prepend an "All Portfolios" aggregate tab
            final allItem = PortfolioItem(
              portfolioId: 'all',
              portfolioName: 'All Portfolios',
            );
            final items = <PortfolioItem>[allItem, ...portfolios];

            // Read from local state first, fallback to context
            final currentId =
                _localSelectedId ?? ctx.selectedPortfolioId ?? widget.portfolioId ?? 'all';

            return SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final item = items[i];
                  final isSelected = currentId == item.portfolioId;

                  return GestureDetector(
                    onTap: () {
                      if (!isSelected) {
                        setState(() {
                          _localSelectedId = item.portfolioId;
                          _localSelectedName = item.portfolioName;
                        });
                        _load(); // Only reload the chart's data
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.withOpacity(0.35),
                        ),
                      ),
                      child: Text(
                        item.portfolioName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // ── Chart Content ────────────────────────────────────────────────────────

  Widget _buildContent(PortfolioHistoryLoaded state) {
    if (state.snapshots.isEmpty) return _buildEmpty();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPortfolioTabs(),
        const SizedBox(height: 12),
        _buildChart(state),
      ],
    );
  }

  // ── Chart Rendering ──────────────────────────────────────────────────────

  Widget _buildChart(PortfolioHistoryLoaded state) {
    final List<CommonChartDataPoint> primaryPoints = [];
    final List<CommonChartDataPoint> secondaryPoints = [];

    double? firstValidValue;
    double lastValidValue = 0.0;
    int plotIndex = 0;

    for (final snap in state.snapshots) {
      double value = snap.totalUserWealth ?? 0.0;

      // ── Zero-dip interpolation ──────────────────────────────────────────
      // The backend returns 0.0 when the sync failed or there was no data
      // for that day. We carry forward the last known valid value so the
      // chart stays flat on bad days instead of dipping to zero.
      if (value <= 0.0) {
        if (lastValidValue > 0) {
          value = lastValidValue; // carry forward
        } else {
          // No valid value yet → skip this point entirely
          continue;
        }
      } else {
        lastValidValue = value;
      }

      firstValidValue ??= value;

      final pct = (firstValidValue > 0)
          ? ((value - firstValidValue) / firstValidValue) * 100
          : 0.0;

      final label = _formatDate(snap.snapshotDate);

      primaryPoints.add(CommonChartDataPoint(
        x: plotIndex.toDouble(),
        y: value,
        xLabel: label,
        yLabel: '₹${_formatNum(value)}',
      ));

      secondaryPoints.add(CommonChartDataPoint(
        x: plotIndex.toDouble(),
        y: pct,
        xLabel: label,
        yLabel: '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
      ));

      plotIndex++;
    }

    // All snapshots had zero/missing data
    if (primaryPoints.isEmpty) return _buildEmpty();

    // Use locally selected name if available, otherwise global
    final chartTitle = _localSelectedName ??
        context.selectedPortfolioName ??
        'Portfolio Journey';

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    final Color cardBase = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFFFFFFF);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cardBase.withValues(alpha: isDark ? 0.55 : 0.9),
                cardBase.withValues(alpha: isDark ? 0.3 : 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.07 : 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CommonPerformanceChart(
            title: chartTitle,
            primaryData: primaryPoints,
            secondaryData: secondaryPoints,
            primaryToggleLabel: '₹',
            secondaryToggleLabel: '%',
            height: widget.height,
            showGrid: true,
            enableScrolling: isMobile, // ChartFactory Zoom wrapper handles scrolling on web, standard touch on mobile
            useCard: false,
            isAreaChart: true,
            config: CommonChartConfig(
              enableZoom: !isMobile,
              initialZoomScale: isMobile ? 1.0 : 0.5,
              lockTooltipToTop: true,
              showGrid: true,
              showTitles: true,
              showTooltips: true,
            ),
          ),
        ),
      ),
    );
  }

  // ── Utility Helpers ──────────────────────────────────────────────────────

  /// Formats a raw ISO date string (e.g. "2026-06-28") to "Jun 28"
  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return raw;
    }
  }

  /// Formats a raw rupee value to a compact string:
  ///   ≥ 1 Cr  → "1.23Cr"
  ///   ≥ 1 L   → "8.65L"
  ///   else    → "99500"
  String _formatNum(double value) {
    if (value >= 1e7) return '${(value / 1e7).toStringAsFixed(2)}Cr';
    if (value >= 1e5) return '${(value / 1e5).toStringAsFixed(2)}L';
    return value.toStringAsFixed(0);
  }

  // ── Loading / Error / Empty States ───────────────────────────────────────

  Widget _buildShimmer() => SizedBox(
        height: widget.height + 50,
        child: const Center(child: CircularProgressIndicator()),
      );

  Widget _buildError(String msg) => SizedBox(
        height: widget.height,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bar_chart_rounded, size: 40, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                'Could not load history',
                style: TextStyle(color: Colors.grey[600]),
              ),
              TextButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmpty() => SizedBox(
        height: widget.height,
        child: const Center(
          child: Text(
            'No history yet.\nCheck back after market close.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
}
