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
/// - Compact transparent portfolio dropdown (All Portfolios + brokers)
/// - Reacts to global portfolio selection changes
/// - Carries forward last known wealth on days with missing data (no zero-dips)
/// - Reloads on both portfolioId and timeFrame changes
class PortfolioHistoryChartWidget extends ConsumerStatefulWidget {
  const PortfolioHistoryChartWidget({
    super.key,
    required this.portfolioId,
    required this.timeFrame,
    this.height = 320,
    this.onPeriodStats,
  });

  final String? portfolioId;
  final TimeFrame timeFrame;
  final double height;
  final void Function(double start, double end)? onPeriodStats;

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

  void _handleZoomAdjust(double delta) {
    setState(() {
      _zoomScale = (_zoomScale + delta).clamp(1.0, 5.0);
    });
  }

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

  // ── Portfolio Dropdown Switcher ──────────────────────────────────────────

  /// Compact transparent dropdown (matches mobile timeframe styling).
  Widget _buildPortfolioTabs() {
    return Builder(
      builder: (ctx) {
        return BlocBuilder<PortfolioCubit, PortfolioState>(
          buildWhen: (prev, curr) =>
              prev.portfolioList != curr.portfolioList || curr is PortfolioLoaded,
          builder: (bCtx, state) {
            final portfolios = state.portfolioList?.portfolios ?? [];
            if (portfolios.isEmpty) return const SizedBox.shrink();

            final items = <PortfolioItem>[
              const PortfolioItem(
                portfolioId: 'all',
                portfolioName: 'All Portfolios',
              ),
              ...portfolios,
            ];

            final currentId = _localSelectedId ??
                ctx.selectedPortfolioId ??
                widget.portfolioId ??
                'all';
            final hasSelection = items.any((p) => p.portfolioId == currentId);
            final selectedId = hasSelection ? currentId : 'all';
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 148),
              child: CustomDropdown<String>(
                value: selectedId,
                height: 32,
                isExpanded: true,
                fontSize: 12,
                iconSize: 16,
                borderRadius: 10,
                menuMaxHeight: 148,
                primaryColor: AppColors.primary,
                backgroundColor:
                    isDark ? Colors.white.withValues(alpha: 0.06) : null,
                borderColor:
                    isDark ? Colors.white.withValues(alpha: 0.1) : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                items: items
                    .map(
                      (p) => p.portfolioId.toSimpleDropdownItem(
                        text: p.portfolioName,
                        fontSize: 12,
                      ),
                    )
                    .toList(),
                onChanged: (id) {
                  if (id == null || id == selectedId) return;
                  String name = 'All Portfolios';
                  for (final p in items) {
                    if (p.portfolioId == id) {
                      name = p.portfolioName;
                      break;
                    }
                  }
                  setState(() {
                    _localSelectedId = id;
                    _localSelectedName = name;
                  });
                  _load();
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

    return _buildChart(state);
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
    // 1. Pad data to stretch X-axis for young portfolios
    final paddedSnapshots = _padSnapshots(state.snapshots, widget.timeFrame);

    // Collect all unique brokers in stable order
    final List<String> brokers = [];
    for (final snap in paddedSnapshots) {
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

    final String tfCode = widget.timeFrame.code;
    final thinnedSnapshots = _thinSnapshots(paddedSnapshots, tfCode);

    // Use the longest broker's point count as X axis
    int plotIndex = 0;
    String? lastPeriodUnit;
    for (final snap in thinnedSnapshots) {
      final label = _getXLabel(snap.snapshotDate, tfCode, lastPeriodUnit);
      if (label.isNotEmpty) {
        lastPeriodUnit = _getPeriodUnit(snap.snapshotDate, tfCode);
      }
      bool anyValid = false;

      for (final broker in brokers) {
        // Find this broker's entry in this snapshot
        final entry = snap.portfolios.cast<dynamic>().firstWhere(
          (p) => (p.brokerType ?? '') == broker,
          orElse: () => null,
        );
        double value = (entry?.close as double?) ?? 0.0;

        if (snap.totalUserWealth?.isNaN == true) {
          value = double.nan;
        } else if (value <= 0.0) {
          value = lastValidMap[broker] ?? 0.0;
          if (value <= 0.0) {
            value = double.nan; // Still keep point as a gap if no previous valid value
          }
        } else {
          lastValidMap[broker] = value;
        }

        if (!value.isNaN) {
          firstValidMap[broker] ??= value;
        }
        final firstVal = firstValidMap[broker] ?? 0.0;
        final pct = (firstVal > 0 && !value.isNaN) ? ((value - firstVal) / firstVal) * 100 : 0.0;

        primaryMap[broker]!.add(CommonChartDataPoint(
          x: plotIndex.toDouble(),
          y: value,
          xLabel: label,
          yLabel: value.isNaN ? '' : '₹${_formatNum(value)}',
        ));
        secondaryMap[broker]!.add(CommonChartDataPoint(
          x: plotIndex.toDouble(),
          y: value.isNaN ? double.nan : pct,
          xLabel: label,
          yLabel: value.isNaN ? '' : '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
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

    final firstLine = primaryLines.first;
    if (firstLine.points.isNotEmpty) {
      final start = firstLine.points.first.y;
      final end = firstLine.points.last.y;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onPeriodStats?.call(start, end);
      });
    }

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

    final String tfCode = widget.timeFrame.code;
    
    // 1. Pad data to stretch X-axis for young portfolios
    final paddedSnapshots = _padSnapshots(state.snapshots, widget.timeFrame);
    final thinnedSnapshots = _thinSnapshots(paddedSnapshots, tfCode);

    String? lastPeriodUnit;
    for (final snap in thinnedSnapshots) {
      // Extract value — preserve NaN from padding snapshots
      final rawWealth = snap.totalUserWealth;
      double value;
      if (rawWealth != null && rawWealth.isNaN) {
        value = double.nan;
      } else if (isAllPortfolios) {
        value = rawWealth ?? 0.0;
      } else {
        value = snap.portfolios.isNotEmpty
            ? (snap.portfolios.first.close ?? rawWealth ?? 0.0)
            : (rawWealth ?? 0.0);
      }

      if (value.isNaN) {
        // It's a padding point, keep the gap but increment index
        final label = _getXLabel(snap.snapshotDate, tfCode, lastPeriodUnit);
        if (label.isNotEmpty) lastPeriodUnit = _getPeriodUnit(snap.snapshotDate, tfCode);
        
        primaryPoints.add(CommonChartDataPoint(
          x: plotIndex.toDouble(),
          y: double.nan,
          xLabel: label,
          yLabel: '',
        ));
        secondaryPoints.add(CommonChartDataPoint(
          x: plotIndex.toDouble(),
          y: double.nan,
          xLabel: label,
          yLabel: '',
        ));
        plotIndex++;
        continue;
      }

      if (value <= 0.0) {
        if (lastValidValue > 0) {
          value = lastValidValue;
        } else {
          // If no previous valid value, treat as gap
          value = double.nan;
        }
      } else {
        lastValidValue = value;
      }

      if (!value.isNaN) {
        firstValidValue ??= value;
      }
      
      final pct = (firstValidValue != null && firstValidValue! > 0 && !value.isNaN)
          ? ((value - firstValidValue!) / firstValidValue!) * 100
          : 0.0;
          
      final label = _getXLabel(snap.snapshotDate, tfCode, lastPeriodUnit);
      if (label.isNotEmpty) {
        lastPeriodUnit = _getPeriodUnit(snap.snapshotDate, tfCode);
      }

      primaryPoints.add(CommonChartDataPoint(
        x: plotIndex.toDouble(),
        y: value,
        xLabel: label,
        yLabel: value.isNaN ? '' : '₹${_formatNum(value)}',
      ));
      secondaryPoints.add(CommonChartDataPoint(
        x: plotIndex.toDouble(),
        y: value.isNaN ? double.nan : pct,
        xLabel: label,
        yLabel: value.isNaN ? '' : '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
      ));
      plotIndex++;
    }

    if (primaryPoints.isEmpty) return _buildEmpty();

    final activeData = _activeFormat == ChartFormat.secondary ? secondaryPoints : primaryPoints;

    if (primaryPoints.isNotEmpty) {
      final start = primaryPoints.first.y;
      final end = primaryPoints.last.y;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onPeriodStats?.call(start, end);
      });
    }

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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildPortfolioTabs(),
                  const Spacer(),
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
                          });
                        },
                      ),
                      if (isDesktop) ...[
                        const SizedBox(width: 16),
                        _buildZoomButton(Icons.remove, () => _handleZoomAdjust(-0.2), isDark),
                        const SizedBox(width: 8),
                        Text('${(_zoomScale * 100).toInt()}%',
                            style: TextStyle(fontSize: 12, color: theme.hintColor)),
                        const SizedBox(width: 8),
                        _buildZoomButton(Icons.add, () => _handleZoomAdjust(0.2), isDark),
                      ],
                    ],
                  ),
                ],
              ),
              if (isMultiLine && activeLines != null) ...[
                const SizedBox(height: 10),
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
                ),
              ],
              const SizedBox(height: 16),
              // ── Chart Area ─────────────────────────────────────────────
              LayoutBuilder(
                builder: (context, constraints) {
                  final int dataLen = isMultiLine
                      ? (activeLines?.first.points.length ?? 0)
                      : (singleData?.length ?? 0);
                  final double baseWidth = dataLen * 40.0;
                  final double calculatedWidth = (baseWidth * _zoomScale).clamp(constraints.maxWidth, double.infinity);
                  final bool needsScroll = calculatedWidth > constraints.maxWidth;
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
                            xInterval: 1, // Evaluate every index so our sparse labels are shown
                            enableZoom: false,
                            lockTooltipToTop: false,
                            showGrid: true,
                            showTitles: true,
                            showTooltips: true,
                            formatYLabel: (val) {
                              if (val == 0) return '0';
                              final showPercentage = _activeFormat == ChartFormat.secondary;
                              if (showPercentage) {
                                return '${val.toStringAsFixed(2)}%';
                              } else {
                                if (val.abs() < 10) return val.toStringAsFixed(2);
                                if (val.abs() >= 1e7) return '${(val / 1e7).toStringAsFixed(2)}Cr';
                                if (val.abs() >= 1e5) return '${(val / 1e5).toStringAsFixed(2)}L';
                                return val.toInt().toString();
                              }
                            },
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

  int _isoWeekNumber(DateTime date) {
    int dayOfYear = int.parse(DateFormat("D").format(date));
    int woy = ((dayOfYear - date.weekday + 10) / 7).floor();
    if (woy < 1) {
      woy = 52;
    } else if (woy > 52) {
      woy = 1;
    }
    return woy;
  }

  List<PortfolioSnapshotDto> _keepLastPerGroup<T extends PortfolioSnapshotDto>(List<T> raw, String Function(T) groupBy) {
    if (raw.isEmpty) return raw;
    final map = <String, PortfolioSnapshotDto>{};
    for (final item in raw) {
      final key = groupBy(item);
      final existing = map[key];
      // Prefer real data over NaN padding — only overwrite if new item is not NaN
      // OR there is no existing entry yet
      final itemIsNaN = item.totalUserWealth?.isNaN == true;
      final existingIsNaN = existing?.totalUserWealth?.isNaN == true;
      if (existing == null || existingIsNaN || !itemIsNaN) {
        map[key] = item;
      }
    }
    return map.values.toList();
  }

  /// Pads the start of the snapshots list with dummy points so the X-axis
  /// perfectly reflects the selected timeframe, even if the portfolio is brand new.
  List<PortfolioSnapshotDto> _padSnapshots(List<PortfolioSnapshotDto> raw, TimeFrame tf) {
    if (raw.isEmpty || tf == TimeFrame.all) return raw;
    final startDate = tf.dateRange.start;
    final firstRealDate = DateTime.tryParse(raw.first.snapshotDate ?? '');
    
    if (firstRealDate != null && firstRealDate.isAfter(startDate)) {
      final startDay = DateTime(startDate.year, startDate.month, startDate.day);
      final firstDay = DateTime(firstRealDate.year, firstRealDate.month, firstRealDate.day);
      final daysToPad = firstDay.difference(startDay).inDays;
      
      if (daysToPad > 0) {
        final padding = <PortfolioSnapshotDto>[];
        for (int i = 0; i < daysToPad; i++) {
          final d = startDate.add(Duration(days: i));
          final isShortTimeframe = tf == TimeFrame.oneDay || tf == TimeFrame.oneWeek;
          padding.add(PortfolioSnapshotDto(
            snapshotDate: d.toIso8601String(),
            totalUserWealth: isShortTimeframe ? raw.first.totalUserWealth : double.nan,
            portfolios: isShortTimeframe ? raw.first.portfolios : [], // empty for padding on long timeframes
          ));
        }
        return [...padding, ...raw];
      }
    }
    return raw;
  }

  List<PortfolioSnapshotDto> _thinSnapshots(List<PortfolioSnapshotDto> raw, String code) {
    if (raw.length < 30) return raw;

    switch (code) {
      case '1Y':
      case '3Y':
      case '5Y':
      case 'All':
        return _keepLastPerGroup(raw, (s) {
          final dt = DateTime.tryParse(s.snapshotDate ?? '');
          if (dt == null) return '?';
          final week = _isoWeekNumber(dt);
          return '${dt.year}-$week';
        });
      case '6M':
      case 'YTD':
        return _keepLastPerGroup(raw, (s) {
          final dt = DateTime.tryParse(s.snapshotDate ?? '');
          if (dt == null) return '?';
          final week = _isoWeekNumber(dt);
          return '${dt.year}-${(week / 2).floor()}';
        });
      default:
        return raw;
    }
  }

  /// Returns the "deduplication key" for a date at a given timeframe.
  /// Used to detect when a new period boundary has been crossed.
  String _getPeriodUnit(String? raw, String tfCode) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      switch (tfCode) {
        case '1D':
          return '${dt.year}-${dt.month}-${dt.day}-${dt.hour}';
        case '1W':
          return '${dt.year}-${dt.month}-${dt.day}';
        case '1M':
          // Label every ~7 days: use the week-of-month as the key
          return '${dt.year}-${dt.month}-${(dt.day / 7).floor()}';
        case '3M':
        case '6M':
        case 'YTD':
        case '1Y':
          return '${dt.year}-${dt.month}';
        case '3Y':
        case '5Y':
        case 'All':
          return '${dt.year}';
        default:
          return '${dt.year}-${dt.month}';
      }
    } catch (_) {
      return '';
    }
  }

  /// Returns the X-axis label for this data point, or an EMPTY STRING if the
  /// label should be suppressed (i.e., the same period unit as the last label).
  ///
  /// Rules by timeframe:
  ///  1D   → label every new hour:     "9 AM", "11 AM"
  ///  1W   → label every new day:      "Mon 7", "Tue 8"
  ///  1M   → label every ~7 days:      "Jun 27", "Jul 4"
  ///  3M   → label every new month:    "Jun", "Jul", "Aug"
  ///  6M   → label every new month:    "Jan", "Feb", …
  ///  1Y   → label every new month:    "Jun '26", "Jul '26"
  ///  3Y/5Y → label every new year:   "2024", "2025", "2026"
  String _getXLabel(String? raw, String tfCode, String? lastPeriodUnit) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      final currentUnit = _getPeriodUnit(raw, tfCode);

      // Suppress duplicate labels — show only when period unit changes
      if (currentUnit == lastPeriodUnit && lastPeriodUnit != null) return '';

      switch (tfCode) {
        case '1D':
          return DateFormat('h a').format(dt);        // "9 AM"
        case '1W':
          return DateFormat('EEE d').format(dt);      // "Mon 7"
        case '1M':
          return DateFormat('MMM d').format(dt);      // "Jun 27"
        case '3M':
        case '6M':
        case 'YTD':
          return DateFormat('MMM').format(dt);        // "Jun"
        case '1Y':
          return DateFormat("MMM ''yy").format(dt);   // "Jun '26"
        case '3Y':
        case '5Y':
        case 'All':
          return DateFormat('yyyy').format(dt);       // "2026"
        default:
          return DateFormat('MMM d').format(dt);
      }
    } catch (_) {
      return raw ?? '';
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
    // By default, top titles take 16px, bottom titles take 14px.
    // The actual drawing area is chartHeight - 14 - 16 = chartHeight - 30.
    final double drawingHeight = chartHeight - 30;

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
