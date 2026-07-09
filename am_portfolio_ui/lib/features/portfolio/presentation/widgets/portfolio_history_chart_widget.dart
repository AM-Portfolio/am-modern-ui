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

  // Active chart format toggle (₹ or %)
  ChartFormat _activeFormat = ChartFormat.primary;

  // Custom zoom state managed externally
  double _zoomScale = 1.0;
  void Function(double)? _adjustZoom;

  // Chart range state for end-of-line badges
  double? _chartMinY;
  double? _chartMaxY;

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
          _localSelectedId = context.selectedPortfolioId;
          _localSelectedName = context.selectedPortfolioName;
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
          buildWhen: (prev, curr) => prev.portfolioList != curr.portfolioList || curr is PortfolioLoaded,
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

  /// Color palette — one per broker in a consistent order so the same broker
  /// always gets the same colour regardless of render order.
  static const List<Color> _brokerPalette = [
    Color(0xFF7C5CFC), // Purple  (e.g. Zerodha)
    Color(0xFF00E676), // Green   (e.g. Groww)
    Color(0xFF2979FF), // Blue    (e.g. Dhan)
    Color(0xFFFF6D00), // Orange  (e.g. Angel One)
    Color(0xFFE040FB), // Magenta (5th broker)
    Color(0xFF00BCD4), // Cyan    (6th broker)
  ];

  Widget _buildChart(PortfolioHistoryLoaded state) {
    final bool isAllPortfolios =
        (_localSelectedId ?? context.selectedPortfolioId ?? widget.portfolioId ?? 'all') == 'all';

    // ── Multi-line mode — "All Portfolios" selected ─────────────────────────
    if (isAllPortfolios && _hasMultipleBrokers(state)) {
      return _buildMultiLineChart(state);
    }

    // ── Single-line mode — one portfolio selected ───────────────────────────
    return _buildSingleLineChart(state);
  }

  /// Returns true if the snapshot data contains entries from more than 1 broker.
  bool _hasMultipleBrokers(PortfolioHistoryLoaded state) {
    final brokers = <String>{};
    for (final snap in state.snapshots) {
      for (final p in snap.portfolios) {
        if (p.brokerType != null && p.brokerType!.isNotEmpty) {
          brokers.add(p.brokerType!);
        }
      }
    }
    return brokers.length > 1;
  }

  /// Builds a multi-line chart — one line per broker.
  Widget _buildMultiLineChart(PortfolioHistoryLoaded state) {
    // Collect all unique brokers in stable order
    final List<String> brokers = [];
    for (final snap in state.snapshots) {
      for (final p in snap.portfolios) {
        final b = p.brokerType ?? '';
        if (b.isNotEmpty && !brokers.contains(b)) brokers.add(b);
      }
    }
    brokers.sort();

    // Per-broker: points lists + first-valid tracker for % calc
    final Map<String, List<CommonChartDataPoint>> primaryMap = {
      for (final b in brokers) b: [],
    };
    final Map<String, List<CommonChartDataPoint>> secondaryMap = {
      for (final b in brokers) b: [],
    };
    final Map<String, double?> firstValidMap = {};
    final Map<String, double> lastValidMap = {};

    // Use the longest broker's point count as X axis
    int plotIndex = 0;
    for (final snap in state.snapshots) {
      final label = _formatDate(snap.snapshotDate);
      bool anyValid = false;

      for (final broker in brokers) {
        // Find this broker's entry in this snapshot
        final entry = snap.portfolios.cast<dynamic>().firstWhere(
          (p) => (p.brokerType ?? '') == broker,
          orElse: () => null,
        );
        double value = (entry?.close as double?) ?? 0.0;

        // Zero-dip interpolation per broker
        if (value <= 0.0) {
          value = lastValidMap[broker] ?? 0.0;
          if (value <= 0.0) continue; // skip if no known value yet
        } else {
          lastValidMap[broker] = value;
        }

        firstValidMap[broker] ??= value;
        final firstVal = firstValidMap[broker]!;
        final pct = firstVal > 0 ? ((value - firstVal) / firstVal) * 100 : 0.0;

        primaryMap[broker]!.add(CommonChartDataPoint(
          x: plotIndex.toDouble(),
          y: value,
          xLabel: label,
          yLabel: '₹${_formatNum(value)}',
        ));
        secondaryMap[broker]!.add(CommonChartDataPoint(
          x: plotIndex.toDouble(),
          y: pct,
          xLabel: label,
          yLabel: '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
        ));
        anyValid = true;
      }
      if (anyValid) plotIndex++;
    }

    // Build ChartLineData list — filter out brokers with no valid points
    final List<ChartLineData> primaryLines = [];
    final List<ChartLineData> secondaryLines = [];
    for (int i = 0; i < brokers.length; i++) {
      final broker = brokers[i];
      if (primaryMap[broker]!.isEmpty) continue;
      final color = _brokerPalette[i % _brokerPalette.length];
      // Capitalise broker label
      final label = broker.substring(0, 1).toUpperCase() + broker.substring(1).toLowerCase();
      primaryLines.add(ChartLineData(label: label, points: primaryMap[broker]!, color: color));
      secondaryLines.add(ChartLineData(label: label, points: secondaryMap[broker]!, color: color));
    }

    if (primaryLines.isEmpty) return _buildEmpty();

    final activeLines = _activeFormat == ChartFormat.secondary ? secondaryLines : primaryLines;

    return _buildChartContainer(
      activeLines: activeLines,
      isMultiLine: true,
      allPrimaryLines: primaryLines,
      allSecondaryLines: secondaryLines,
    );
  }

  /// Builds the original single-line area chart.
  Widget _buildSingleLineChart(PortfolioHistoryLoaded state) {
    final List<CommonChartDataPoint> primaryPoints = [];
    final List<CommonChartDataPoint> secondaryPoints = [];

    double? firstValidValue;
    double lastValidValue = 0.0;
    int plotIndex = 0;

    final bool isAllPortfolios =
        (_localSelectedId ?? context.selectedPortfolioId ?? widget.portfolioId ?? 'all') == 'all';

    for (final snap in state.snapshots) {
      double value = isAllPortfolios
          ? (snap.totalUserWealth ?? 0.0)
          : (snap.portfolios.isNotEmpty 
              ? (snap.portfolios.first.close ?? snap.totalUserWealth ?? 0.0) 
              : (snap.totalUserWealth ?? 0.0));

      if (value <= 0.0) {
        if (lastValidValue > 0) {
          value = lastValidValue;
        } else {
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

    if (primaryPoints.isEmpty) return _buildEmpty();

    final activeData = _activeFormat == ChartFormat.secondary ? secondaryPoints : primaryPoints;

    return _buildChartContainer(
      singleData: activeData,
      isMultiLine: false,
    );
  }

  /// Shared chart container (glassmorphism card + controls + chart area).
  Widget _buildChartContainer({
    List<CommonChartDataPoint>? singleData,
    List<ChartLineData>? activeLines,
    bool isMultiLine = false,
    List<ChartLineData>? allPrimaryLines,
    List<ChartLineData>? allSecondaryLines,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 1100;
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
            border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.07 : 0.4)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Top Control Row ────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Multi-line legend (broker color dots)
                  if (isMultiLine && activeLines != null)
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: activeLines.map((line) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 3,
                              decoration: BoxDecoration(
                                color: line.color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              line.label,
                              style: TextStyle(fontSize: 11, color: theme.hintColor),
                            ),
                          ],
                        );
                      }).toList(),
                    )
                  else
                    const SizedBox.shrink(),

                  // Toggle + Zoom controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppSegmentedControl<ChartFormat>(
                        selectedValue: _activeFormat,
                        children: const {
                          ChartFormat.primary: '₹',
                          ChartFormat.secondary: '%',
                        },
                        onValueChanged: (val) {
                          setState(() {
                            _activeFormat = val;
                            // Update multi-line active set when toggle changes
                          });
                        },
                      ),
                      if (isDesktop && _adjustZoom != null) ...[
                        const SizedBox(width: 16),
                        _buildZoomButton(Icons.remove, () => _adjustZoom!(-0.2), isDark),
                        const SizedBox(width: 8),
                        Text('${(_zoomScale * 100).toInt()}%',
                            style: TextStyle(fontSize: 12, color: theme.hintColor)),
                        const SizedBox(width: 8),
                        _buildZoomButton(Icons.add, () => _adjustZoom!(0.2), isDark),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Chart Area ─────────────────────────────────────────────
              LayoutBuilder(
                builder: (context, constraints) {
                  final int dataLen = isMultiLine
                      ? (activeLines?.first.points.length ?? 0)
                      : (singleData?.length ?? 0);
                  final double calculatedWidth = dataLen * 40.0;
                  final bool needsScroll = !isDesktop && (calculatedWidth > constraints.maxWidth);
                  final double chartWidth = needsScroll ? calculatedWidth : constraints.maxWidth;

                  // Resolve the correct lines for the current toggle state in multi-line mode
                  final List<ChartLineData>? resolvedLines = isMultiLine
                      ? (_activeFormat == ChartFormat.secondary ? allSecondaryLines : allPrimaryLines)
                      : null;

                  Widget chartWidget = SizedBox(
                    width: chartWidth,
                    height: widget.height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ChartFactory.area(
                          data: singleData ?? const [],
                          lines: resolvedLines,
                          color: AppColors.primary,
                          config: CommonChartConfig(
                            enableZoom: isDesktop,
                            initialZoomScale: _zoomScale,
                            lockTooltipToTop: false,
                            showGrid: true,
                            showTitles: true,
                            showTooltips: true,
                            onZoomChanged: (scale, adjust) {
                              if (_zoomScale != scale || _adjustZoom != adjust) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) setState(() { _zoomScale = scale; _adjustZoom = adjust; });
                                });
                              }
                            },
                          ),
                          onMinMaxCalculated: (min, max) {
                            if (_chartMinY != min || _chartMaxY != max) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) setState(() { _chartMinY = min; _chartMaxY = max; });
                              });
                            }
                          },
                        ),
                        // End-of-line badges
                        if (_chartMinY != null && _chartMaxY != null) ...[
                          if (isMultiLine && resolvedLines != null)
                            // One badge per broker line, stacked with slight vertical offset if they overlap
                            ...resolvedLines.asMap().entries.map((entry) {
                              return _EndOfLineBadge(
                                lastPoint: entry.value.points.last,
                                minY: _chartMinY!,
                                maxY: _chartMaxY!,
                                chartHeight: widget.height,
                                isSecondary: _activeFormat == ChartFormat.secondary,
                                color: entry.value.color,
                                stackIndex: entry.key,
                              );
                            })
                          else if (singleData != null && singleData.isNotEmpty)
                            _EndOfLineBadge(
                              lastPoint: singleData.last,
                              minY: _chartMinY!,
                              maxY: _chartMaxY!,
                              chartHeight: widget.height,
                              isSecondary: _activeFormat == ChartFormat.secondary,
                            ),
                        ],
                      ],
                    ),
                  );

                  if (needsScroll) {
                    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: chartWidget);
                  }
                  return chartWidget;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildZoomButton(IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: isDark ? Colors.white70 : Colors.black54),
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

class _EndOfLineBadge extends StatelessWidget {
  final CommonChartDataPoint lastPoint;
  final double minY;
  final double maxY;
  final double chartHeight;
  final bool isSecondary;
  /// When set (multi-line mode), this colour overrides the default logic.
  final Color? color;
  /// Used to nudge overlapping badges apart (0 = no offset).
  final int stackIndex;

  const _EndOfLineBadge({
    required this.lastPoint,
    required this.minY,
    required this.maxY,
    required this.chartHeight,
    required this.isSecondary,
    this.color,
    this.stackIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    // fl_chart draws the line area bounded by titles.
    // By default, bottom titles take 30px, top titles take 16px.
    // The actual drawing area is chartHeight - 30 - 16 = chartHeight - 46.
    final double drawingHeight = chartHeight - 46;

    final double range = maxY - minY;
    final double percentFromBottom = range == 0 ? 0.5 : (lastPoint.y - minY) / range;
    final double topPixels = 16 + (drawingHeight * (1 - percentFromBottom));

    // Nudge stacked badges apart by ~22px each so they don't sit directly on top
    final double nudge = stackIndex * 22.0;

    // Resolve badge color
    final Color badgeColor = color ??
        (isSecondary
            ? (lastPoint.y < 0 ? const Color(0xFF4A89FF) : const Color(0xFF00E676))
            : AppColors.primary);

    return Positioned(
      top: (topPixels - 12 + nudge).clamp(0.0, chartHeight - 24),
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(color: badgeColor.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          lastPoint.yLabel ?? lastPoint.y.toStringAsFixed(2),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
