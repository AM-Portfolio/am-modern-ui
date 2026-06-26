import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// Helper classes to smoothly animate the Y-axis range
class ChartViewportRange {
  final double minY;
  final double maxY;
  ChartViewportRange(this.minY, this.maxY);
}

class ChartViewportRangeTween extends Tween<ChartViewportRange> {
  ChartViewportRangeTween({super.begin, super.end});

  @override
  ChartViewportRange lerp(double t) {
    final double bMin = begin?.minY ?? -5.0;
    final double eMin = end?.minY ?? -5.0;
    final double bMax = begin?.maxY ?? 5.0;
    final double eMax = end?.maxY ?? 5.0;

    return ChartViewportRange(
      bMin + (eMin - bMin) * t,
      bMax + (eMax - bMax) * t,
    );
  }
}

/// Multi-index chart widget that displays up to 3 indices on a single chart
/// Implements premium interactive horizontal scrolling, center-anchored zooming,
/// safety data-alignment, and throttled, rubber-band animated Y-axis viewport scaling.
class MultiIndexChart extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> historicalData;
  final List<String> selectedIndices;
  final bool isLoading;
  final String? error;
  final bool isBarChart;

  const MultiIndexChart({
    super.key,
    required this.historicalData,
    required this.selectedIndices,
    this.isLoading = false,
    this.error,
    this.isBarChart = false,
  });

  // Color palette for different indices
  static const List<Color> indexColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Green
    Color(0xFFEF4444), // Red
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Violet
  ];

  @override
  State<MultiIndexChart> createState() => _MultiIndexChartState();
}

class _MultiIndexChartState extends State<MultiIndexChart> {
  late ScrollController _scrollController;
  double _zoomScale = 1.0;

  // Viewport-based calculated min/max
  double _viewportMinY = -5.0;
  double _viewportMaxY = 5.0;
  double _currentInterval = 2.0; // [SIP/Absolute Value Optimization] Stores the active interval step

  // Tracked targets to avoid duplicate state sets
  double _targetMinY = -5.0;
  double _targetMaxY = 5.0;

  Timer? _throttleTimer;

  /// [SIP/Absolute Value Optimization] Tracks whether the chart should render absolute price numbers
  /// (Google Finance style) instead of percentage changes.
  bool _showAbsoluteValues = false;
  List<Map<String, dynamic>> _chartData = [];
  List<String> _activeIndices = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _prepareDataAndRecalculate(isInitial: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _throttleTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MultiIndexChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    // [SIP/Absolute Value Optimization] Automatically fallback to Percentage Mode
    // if the user selects more than 2 indices, or toggles to Bar Chart view,
    // as absolute price comparisons are visually invalid under these conditions.
    if (widget.selectedIndices.length > 2 || widget.isBarChart) {
      _showAbsoluteValues = false;
    }

    final dataChanged = widget.historicalData != oldWidget.historicalData ||
        widget.selectedIndices != oldWidget.selectedIndices ||
        widget.isBarChart != oldWidget.isBarChart;

    if (dataChanged) {
      _prepareDataAndRecalculate(resetViewport: true);
    }
  }

  void _onScroll() {
    if (_throttleTimer?.isActive ?? false) return;
    _throttleTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        _recalculateViewport();
      }
    });
  }

  /// 🛡️ Active Indices Safety Filter & Union Alignment
  void _prepareDataAndRecalculate({bool resetViewport = false, bool isInitial = false}) {
    // 1. Safety Filter: Find which selected indices actually have data
    _activeIndices = widget.selectedIndices.where((symbol) {
      final data = widget.historicalData[symbol];
      return data != null && data.isNotEmpty;
    }).toList();

    if (_activeIndices.isEmpty) {
      _chartData = [];
      _targetMinY = -5.0;
      _targetMaxY = 5.0;
      if (!isInitial && mounted) {
        setState(() {
          _viewportMinY = -5.0;
          _viewportMaxY = 5.0;
        });
      }
      return;
    }

    // Determine if the data span is daily or intraday to choose the right normalization format
    bool isIntraday = false;
    try {
      DateTime? minDate;
      DateTime? maxDate;
      for (final symbol in _activeIndices) {
        final data = widget.historicalData[symbol];
        if (data != null && data.isNotEmpty) {
          final first = DateTime.parse(data.first['time'] as String);
          final last = DateTime.parse(data.last['time'] as String);
          if (minDate == null || first.isBefore(minDate)) minDate = first;
          if (maxDate == null || last.isAfter(maxDate)) maxDate = last;
        }
      }
      if (minDate != null && maxDate != null) {
        isIntraday = maxDate.difference(minDate).inDays <= 1;
      }
    } catch (_) {}

    String normalizeTime(String timeStr) {
      try {
        final dt = DateTime.parse(timeStr);
        if (isIntraday) {
          return '${dt.year.toString().padLeft(4, '0')}-'
              '${dt.month.toString().padLeft(2, '0')}-'
              '${dt.day.toString().padLeft(2, '0')}T'
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } else {
          return '${dt.year.toString().padLeft(4, '0')}-'
              '${dt.month.toString().padLeft(2, '0')}-'
              '${dt.day.toString().padLeft(2, '0')}';
        }
      } catch (_) {
        return timeStr;
      }
    }

    // Get Union of all unique timestamps across active indices
    final Set<String> allTimestamps = {};
    for (final symbol in _activeIndices) {
      final data = widget.historicalData[symbol];
      if (data != null) {
        for (final point in data) {
          final time = point['time'] as String;
          allTimestamps.add(normalizeTime(time));
        }
      }
    }

    final sortedTimestamps = allTimestamps.toList()..sort();

    // Baseline prices: Look forward for the first available price for each index (safety baseline)
    final Map<String, double> baselinePrices = {};
    for (final symbol in _activeIndices) {
      final data = widget.historicalData[symbol];
      if (data != null && data.isNotEmpty) {
        for (final timestamp in sortedTimestamps) {
          final matchingPoint = data.firstWhere(
            (p) {
              final pTime = p['time'] as String?;
              return pTime != null && normalizeTime(pTime) == timestamp;
            },
            orElse: () => {},
          );
          if (matchingPoint.isNotEmpty && matchingPoint['close'] != null) {
            baselinePrices[symbol] = (matchingPoint['close'] as num).toDouble();
            break;
          }
        }
      }
    }

    // Build combined points with Union alignment and Short/Long gap handling
    final List<Map<String, dynamic>> combined = [];
    final Map<String, double> lastKnownPrices = {};

    for (final timestamp in sortedTimestamps) {
      final Map<String, dynamic> point = {'time': timestamp};
      bool hasAnyValidValue = false;

      for (final symbol in _activeIndices) {
        final data = widget.historicalData[symbol];
        if (data != null && baselinePrices.containsKey(symbol)) {
          final matchingPoint = data.firstWhere(
            (p) {
              final pTime = p['time'] as String?;
              return pTime != null && normalizeTime(pTime) == timestamp;
            },
            orElse: () => {},
          );

          if (matchingPoint.isNotEmpty && matchingPoint['close'] != null) {
            final price = (matchingPoint['close'] as num).toDouble();
            lastKnownPrices[symbol] = price;

            if (_showAbsoluteValues) {
              // [SIP/Absolute Value Optimization] In Absolute Mode, we store the raw price value directly.
              point[symbol] = price;
            } else {
              // In Percentage Mode, we normalize the price against the baseline to get percentage growth.
              final baseline = baselinePrices[symbol]!;
              final percentChange = ((price - baseline) / baseline) * 100;
              point[symbol] = percentChange;
            }
            hasAnyValidValue = true;
          } else {
            // Gap handling: check if the gap is short (<= 3 days)
            if (lastKnownPrices.containsKey(symbol)) {
              bool isGapShort = true;
              try {
                DateTime? lastDate;
                for (int i = combined.length - 1; i >= 0; i--) {
                  if (combined[i].containsKey(symbol)) {
                    lastDate = DateTime.parse(combined[i]['time'] as String);
                    break;
                  }
                }
                if (lastDate != null) {
                  final currentDate = DateTime.parse(timestamp);
                  final gapDays = currentDate.difference(lastDate).inDays;
                  if (gapDays > 3) {
                    isGapShort = false;
                  }
                }
              } catch (_) {}

              if (isGapShort) {
                // Carry over for short gaps to maintain visual continuity
                final price = lastKnownPrices[symbol]!;
                if (_showAbsoluteValues) {
                  // [SIP/Absolute Value Optimization] Carry over absolute price.
                  point[symbol] = price;
                } else {
                  final baseline = baselinePrices[symbol]!;
                  final percentChange = ((price - baseline) / baseline) * 100;
                  point[symbol] = percentChange;
                }
                hasAnyValidValue = true;
              } else {
                // Long gap (>3 days): leave point[symbol] = null to draw a clean visual line break
              }
            }
          }
        }
      }

      if (hasAnyValidValue) {
        combined.add(point);
      }
    }

    _chartData = combined;

    if (resetViewport || isInitial) {
      _calculateTargetMinMax();
      _viewportMinY = _targetMinY;
      _viewportMaxY = _targetMaxY;

      if (resetViewport && !isInitial) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    } else {
      _recalculateViewport();
    }
  }

  /// [SIP/Absolute Value Optimization] Dynamically calculates the clean Y-axis bounds (minY, maxY)
  /// and major tick interval. Rounds bounds to clean multiples of the interval (e.g., 200, 1000, 10000)
  /// to ensure grid lines and numbers align perfectly without visual clutter, matching Google Finance.
  /// [SIP/Absolute Value Optimization] Dynamically calculates the clean Y-axis bounds (minY, maxY)
  /// and major tick interval. Rounds bounds to clean multiples of the interval (e.g., 200, 1000, 10000)
  /// to ensure grid lines and numbers align perfectly without visual clutter, matching Google Finance.
  /// 
  /// CRITICAL BUG FIX: This method has been unified to use a single logarithmic/milestone interval 
  /// calculator that scales seamlessly from very small percentage changes (0.1%) to very large 
  /// absolute index prices (30,000+). During the 150ms viewport transition animation between 
  /// absolute and percentage mode, the active chart range interpolates across thousands of units.
  /// By using a unified scale, we prevent the "grid-line explosion" bug where the chart would 
  /// attempt to render thousands of grid lines (e.g., 24,000 range divided by a 1.0% interval = 24,000 lines),
  /// which previously froze the UI thread and crashed the browser.
  Map<String, double> _calculateCleanBounds(double minVal, double maxVal) {
    // Return safe default bounds if inputs are invalid or empty
    if (minVal == double.infinity || maxVal == double.negativeInfinity) {
      return {'minY': -5.0, 'maxY': 5.0, 'interval': 2.0};
    }

    // Calculate the raw range of the dataset/viewport
    final double rawRange = maxVal - minVal;
    
    // Target roughly 5 horizontal grid lines/intervals across the viewport height
    final double roughInterval = rawRange / 5;
    
    // Select the best clean milestone step based on the magnitude of the range
    double interval;
    if (roughInterval > 15000) {
      interval = 20000.0;
    } else if (roughInterval > 7500) {
      interval = 10000.0;
    } else if (roughInterval > 3500) {
      interval = 5000.0;
    } else if (roughInterval > 1500) {
      interval = 2000.0;
    } else if (roughInterval > 750) {
      interval = 1000.0;
    } else if (roughInterval > 350) {
      interval = 500.0;
    } else if (roughInterval > 150) {
      interval = 200.0;
    } else if (roughInterval > 75) {
      interval = 100.0;
    } else if (roughInterval > 35) {
      interval = 50.0;
    } else if (roughInterval > 15) {
      interval = 20.0;
    } else if (roughInterval > 7.5) {
      interval = 10.0;
    } else if (roughInterval > 3.5) {
      interval = 5.0;
    } else if (roughInterval > 1.5) {
      interval = 2.0;
    } else if (roughInterval > 0.75) {
      interval = 1.0;
    } else if (roughInterval > 0.35) {
      interval = 0.5;
    } else if (roughInterval > 0.15) {
      interval = 0.2;
    } else {
      interval = 0.1;
    }

    // Round the minimum value down and maximum value up to the nearest multiple of the clean interval,
    // and subtract/add one full interval step to provide a clean visual margin/padding at the top and bottom.
    final double minY = (minVal / interval).floorToDouble() * interval - interval;
    final double maxY = (maxVal / interval).ceilToDouble() * interval + interval;
    
    return {'minY': minY, 'maxY': maxY, 'interval': interval};
  }

  /// 📐 Dynamic Viewport Y-Axis Recalculation (Throttled)
  void _recalculateViewport() {
    if (_chartData.isEmpty || _activeIndices.isEmpty) return;
    if (!_scrollController.hasClients) {
      _calculateTargetMinMax();
      if (mounted) {
        setState(() {
          _viewportMinY = _targetMinY;
          _viewportMaxY = _targetMaxY;
        });
      }
      return;
    }

    final scrollOffset = _scrollController.offset;
    final viewportWidth = _scrollController.position.viewportDimension;

    final double spacing = widget.isBarChart
        ? (_activeIndices.length * 10.0 + 20.0)
        : (30.0 * _zoomScale);

    int startIndex = (scrollOffset / spacing).floor();
    int endIndex = ((scrollOffset + viewportWidth) / spacing).ceil();

    if (startIndex < 0) startIndex = 0;
    if (endIndex >= _chartData.length) endIndex = _chartData.length - 1;
    if (startIndex > endIndex) startIndex = endIndex;

    final visibleSubset = _chartData.sublist(startIndex, endIndex + 1);

    if (visibleSubset.isEmpty) return;

    double minVal = double.infinity;
    double maxVal = double.negativeInfinity;

    for (final point in visibleSubset) {
      for (final symbol in _activeIndices) {
        final val = point[symbol];
        if (val != null) {
          final double dVal = val as double;
          if (dVal < minVal) minVal = dVal;
          if (dVal > maxVal) maxVal = dVal;
        }
      }
    }

    final bounds = _calculateCleanBounds(minVal, maxVal);
    final double computedMinY = bounds['minY']!;
    final double computedMaxY = bounds['maxY']!;
    final double computedInterval = bounds['interval']!;

    if ((computedMinY - _targetMinY).abs() > 0.05 || (computedMaxY - _targetMaxY).abs() > 0.05) {
      _targetMinY = computedMinY;
      _targetMaxY = computedMaxY;
      if (mounted) {
        setState(() {
          _viewportMinY = _targetMinY;
          _viewportMaxY = _targetMaxY;
          _currentInterval = computedInterval;
        });
      }
    }
  }

  void _calculateTargetMinMax() {
    if (_chartData.isEmpty || _activeIndices.isEmpty) {
      _targetMinY = -5.0;
      _targetMaxY = 5.0;
      return;
    }
    double minVal = double.infinity;
    double maxVal = double.negativeInfinity;

    for (final point in _chartData) {
      for (final symbol in _activeIndices) {
        final val = point[symbol];
        if (val != null) {
          final double dVal = val as double;
          if (dVal < minVal) minVal = dVal;
          if (dVal > maxVal) maxVal = dVal;
        }
      }
    }
    
    final bounds = _calculateCleanBounds(minVal, maxVal);
    _targetMinY = bounds['minY']!;
    _targetMaxY = bounds['maxY']!;
    _currentInterval = bounds['interval']!;
  }

  /// 🔍 Center-Anchored Zooming
  void _zoom(double newScale, double viewportWidth) {
    if (newScale < 0.5) newScale = 0.5;
    if (newScale > 3.0) newScale = 3.0;
    if (newScale == _zoomScale) return;

    final oldScale = _zoomScale;
    final oldSpacing = 30.0 * oldScale;
    final newSpacing = 30.0 * newScale;

    double centerIndex = 0.0;
    if (_scrollController.hasClients) {
      final oldScrollOffset = _scrollController.offset;
      centerIndex = (oldScrollOffset + viewportWidth / 2) / oldSpacing;
    }

    setState(() {
      _zoomScale = newScale;
    });

    _prepareDataAndRecalculate();

    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final newScrollOffset = (centerIndex * newSpacing) - (viewportWidth / 2);
          final maxScroll = _scrollController.position.maxScrollExtent;
          _scrollController.jumpTo(newScrollOffset.clamp(0.0, maxScroll));
        }
      });
    }
  }

  /// 🖱️ Mouse Wheel Panning (Normal) & Zoom (Ctrl + Wheel)
  void _handlePointerSignal(PointerSignalEvent event, double viewportWidth) {
    if (event is PointerScrollEvent) {
      final isCtrlPressed = RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.controlLeft) ||
          RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.controlRight) ||
          HardwareKeyboard.instance.isControlPressed;

      if (isCtrlPressed) {
        final double zoomChange = event.scrollDelta.dy > 0 ? -0.1 : 0.1;
        _zoom(_zoomScale + zoomChange, viewportWidth);
      } else {
        if (_scrollController.hasClients) {
          final double newOffset = _scrollController.offset + event.scrollDelta.dy;
          final maxScroll = _scrollController.position.maxScrollExtent;
          _scrollController.jumpTo(newOffset.clamp(0.0, maxScroll));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(color: Color(0xFF00D1FF)),
        ),
      );
    }

    if (widget.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error: ${widget.error}',
            style: const TextStyle(color: Colors.red, fontSize: 14),
          ),
        ),
      );
    }

    if (_activeIndices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Select up to 3 indices with valid data to compare',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_chartData.isEmpty) {
      return Center(
        child: Text(
          'No historical data available',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      );
    }

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegend(context),
              Row(
                children: [
                  // [SIP/Absolute Value Optimization] Y-Axis Mode Toggle Control (Percentage vs. Absolute Values)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _buildToggleSegment(
                          label: '%',
                          isSelected: !_showAbsoluteValues,
                          onTap: () {
                            setState(() {
                              _showAbsoluteValues = false;
                              _prepareDataAndRecalculate(resetViewport: true);
                            });
                          },
                        ),
                        _buildToggleSegment(
                          label: '123',
                          isSelected: _showAbsoluteValues,
                          // Absolute Mode is strictly enabled only for Line Charts and when 1 or 2 indices are compared
                          isEnabled: _activeIndices.length <= 2 && !widget.isBarChart,
                          onTap: () {
                            setState(() {
                              _showAbsoluteValues = true;
                              _prepareDataAndRecalculate(resetViewport: true);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Floating Zoom Controls overlay
                  if (!widget.isBarChart)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.zoom_out, color: Color(0xFF00D1FF)),
                          onPressed: () {
                            if (_scrollController.hasClients) {
                              _zoom(_zoomScale - 0.2, _scrollController.position.viewportDimension);
                            }
                          },
                          tooltip: 'Zoom Out',
                        ),
                    Text(
                      '${(_zoomScale * 100).toInt()}%',
                      style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.zoom_in, color: Color(0xFF00D1FF)),
                      onPressed: () {
                        if (_scrollController.hasClients) {
                          _zoom(_zoomScale + 0.2, _scrollController.position.viewportDimension);
                        }
                      },
                      tooltip: 'Zoom In',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
          const SizedBox(height: 24),
          Expanded(
            child: widget.isBarChart
                ? _buildBarChart(context, _chartData)
                : _buildChart(context, _chartData),
          ),
        ],
      ),
    );
  }

  /// [SIP/Absolute Value Optimization] Builds a single segment button for the Y-Axis mode toggle
  Widget _buildToggleSegment({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    final color = isSelected
        ? const Color(0xFF00D1FF)
        : (isEnabled ? Colors.white70 : Colors.white24);
    final bgColor = isSelected
        ? const Color(0xFF00D1FF).withOpacity(0.15)
        : Colors.transparent;

    return IgnorePointer(
      ignoring: !isEnabled,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: Tooltip(
          message: !isEnabled && label == '123'
              ? (widget.isBarChart
                  ? 'Absolute mode is not supported on Bar Charts'
                  : 'Absolute mode supports up to 2 compared indices')
              : '',
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      children: _activeIndices.asMap().entries.map((entry) {
        final index = entry.key;
        final symbol = entry.value;
        final color = MultiIndexChart.indexColors[index % MultiIndexChart.indexColors.length];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              symbol,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBarChart(BuildContext context, List<Map<String, dynamic>> chartData) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = (_activeIndices.length * 10.0 + 20.0);
        final minWidth = chartData.length * spacing;

        // 🎨 Rubber-band Animated Y-Axis Ticks
        return TweenAnimationBuilder<ChartViewportRange>(
          tween: ChartViewportRangeTween(
            begin: ChartViewportRange(_viewportMinY, _viewportMaxY),
            end: ChartViewportRange(_viewportMinY, _viewportMaxY),
          ),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          builder: (context, range, child) {
            final double chartMinY = range.minY;
            final double chartMaxY = range.maxY;
            
            // [SIP/Absolute Value Optimization] CRITICAL BUG FIX: Dynamically calculate the chart interval
            // using the currently animated range bounds rather than using the static snapped target interval.
            // This prevents the "grid-line explosion" during mode transitions (e.g. going from 24,000 range
            // down to 10 range, which previously caused the chart to attempt to draw 24,000 grid lines and labels,
            // freezing the browser completely).
            final double chartInterval = _calculateCleanBounds(chartMinY, chartMaxY)['interval']!;

            return Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: Listener(
                onPointerSignal: (event) => _handlePointerSignal(event, constraints.maxWidth),
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_scrollController.hasClients) {
                      _scrollController.position.moveTo(_scrollController.offset - details.delta.dx);
                    }
                  },
                  // [Gesture Lock Optimization] Intercept vertical drag components within the chart
                  // boundaries, keeping horizontal swipes perfectly focused inside the chart.
                  onVerticalDragUpdate: (_) {},
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: SizedBox(
                      width: minWidth > constraints.maxWidth ? minWidth : constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: BarChart(
                        key: ValueKey('${_activeIndices.join('-')}_bar_${chartData.length}'),
                        BarChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            drawHorizontalLine: true,
                            horizontalInterval: chartInterval,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: theme.dividerColor.withOpacity(0.15),
                                strokeWidth: 1,
                                dashArray: [4, 4],
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 && index < chartData.length) {
                                    if (chartData.length > 20 && index % (chartData.length ~/ 10) != 0) {
                                      return const SizedBox.shrink();
                                    }

                                    final dateStr = chartData[index]['time'] as String;
                                    try {
                                      final date = DateTime.parse(dateStr);
                                      final fmt = _getDateFormat(chartData);

                                      final interval = (chartData.length > 20) ? (chartData.length ~/ 10) : 1;
                                      final prevIndex = ((index - 1) ~/ interval) * interval;
                                      if (prevIndex >= 0) {
                                        try {
                                          final prevDate = DateTime.parse(chartData[prevIndex]['time'] as String);
                                          if (fmt.format(prevDate) == fmt.format(date)) {
                                            return const SizedBox.shrink();
                                          }
                                        } catch (_) {}
                                      }

                                      return SideTitleWidget(
                                        meta: meta,
                                        space: 8.0,
                                        child: Text(
                                          fmt.format(date),
                                          style: TextStyle(
                                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      return const SizedBox.shrink();
                                    }
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 65, // [SIP/Absolute Value Optimization] Fixed size prevents layout reflows and infinite loops
                                interval: chartInterval,
                                getTitlesWidget: (value, meta) {
                                  if ((value - meta.min).abs() < 0.01 || (value - meta.max).abs() < 0.01) {
                                    return const SizedBox.shrink();
                                  }
                                  return SideTitleWidget(
                                    meta: meta,
                                    space: 8.0,
                                    child: Text(
                                      _showAbsoluteValues 
                                          ? value.toStringAsFixed(0) 
                                          : '${value.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom: BorderSide(color: theme.dividerColor.withOpacity(0.5), width: 1),
                              left: BorderSide(color: theme.dividerColor.withOpacity(0.5), width: 1),
                              top: BorderSide.none,
                              right: BorderSide.none,
                            ),
                          ),
                          minY: chartMinY,
                          maxY: chartMaxY,
                          barGroups: chartData.asMap().entries.map((entry) {
                            final index = entry.key;
                            final point = entry.value;

                            return BarChartGroupData(
                              x: index,
                              barsSpace: 4,
                              barRods: _activeIndices.asMap().entries.map((idxEntry) {
                                final idx = idxEntry.key;
                                final symbol = idxEntry.value;
                                final val = (point[symbol] as num?)?.toDouble() ?? 0.0;
                                final isNegative = val < 0;
                                final color = isNegative ? const Color(0xFFEF4444) : MultiIndexChart.indexColors[idx % MultiIndexChart.indexColors.length];

                                return BarChartRodData(
                                  toY: val,
                                  color: color,
                                  width: 14,
                                  borderRadius: val > 0
                                      ? const BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2))
                                      : const BorderRadius.only(bottomLeft: Radius.circular(2), bottomRight: Radius.circular(2)),
                                  backDrawRodData: BackgroundBarChartRodData(show: true, toY: 0, color: Colors.transparent),
                                );
                              }).toList(),
                            );
                          }).toList(),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final dateStr = chartData[group.x]['time'] as String;
                                final date = DateTime.parse(dateStr);
                                final symbol = _activeIndices[rodIndex];
                                return BarTooltipItem(
                                  '${_getTooltipDateFormat(chartData).format(date)}\n$symbol\n${_showAbsoluteValues ? rod.toY.toStringAsFixed(2) : '${rod.toY >= 0 ? '+' : ''}${rod.toY.toStringAsFixed(2)}%'}',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChart(BuildContext context, List<Map<String, dynamic>> chartData) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = 30.0 * _zoomScale;
        final double chartWidth = chartData.length * spacing;

        // 🎨 Rubber-band Animated Y-Axis Ticks
        return TweenAnimationBuilder<ChartViewportRange>(
          tween: ChartViewportRangeTween(
            begin: ChartViewportRange(_viewportMinY, _viewportMaxY),
            end: ChartViewportRange(_viewportMinY, _viewportMaxY),
          ),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          builder: (context, range, child) {
            final double chartMinY = range.minY;
            final double chartMaxY = range.maxY;
            
            // [SIP/Absolute Value Optimization] CRITICAL BUG FIX: Dynamically calculate the chart interval
            // using the currently animated range bounds rather than using the static snapped target interval.
            // This prevents the "grid-line explosion" during mode transitions (e.g. going from 24,000 range
            // down to 10 range, which previously caused the chart to attempt to draw 24,000 grid lines and labels,
            // freezing the browser completely).
            final double chartInterval = _calculateCleanBounds(chartMinY, chartMaxY)['interval']!;

            return Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: Listener(
                onPointerSignal: (event) => _handlePointerSignal(event, constraints.maxWidth),
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_scrollController.hasClients) {
                      _scrollController.position.moveTo(_scrollController.offset - details.delta.dx);
                    }
                  },
                  // [Gesture Lock Optimization] Intercept vertical drag components within the chart
                  // boundaries, keeping horizontal swipes perfectly focused inside the chart.
                  onVerticalDragUpdate: (_) {},
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: SizedBox(
                      width: chartWidth > constraints.maxWidth ? chartWidth : constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: LineChart(
                        key: ValueKey('${_activeIndices.join('-')}_line_${chartData.length}'),
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            drawHorizontalLine: true,
                            horizontalInterval: chartInterval,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: theme.dividerColor.withOpacity(0.15),
                                strokeWidth: 1,
                                dashArray: [4, 4],
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: (chartData.length / 8).ceilToDouble(),
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 && index < chartData.length) {
                                    final interval = (chartData.length / 8).ceil();
                                    if (index == chartData.length - 1 && interval > 1) {
                                      final lastIntervalTick = ((chartData.length - 1) ~/ interval) * interval;
                                      if (chartData.length - 1 != lastIntervalTick && chartData.length - 1 - lastIntervalTick < interval / 2) {
                                        return const SizedBox.shrink();
                                      }
                                    }

                                    final dateStr = chartData[index]['time'] as String;
                                    try {
                                      final date = DateTime.parse(dateStr);
                                      final fmt = _getDateFormat(chartData);

                                      final prevIndex = ((index - 1) ~/ interval) * interval;
                                      if (prevIndex >= 0) {
                                        try {
                                          final prevDate = DateTime.parse(chartData[prevIndex]['time'] as String);
                                          if (fmt.format(prevDate) == fmt.format(date)) {
                                            return const SizedBox.shrink();
                                          }
                                        } catch (_) {}
                                      }

                                      return SideTitleWidget(
                                        meta: meta,
                                        space: 8.0,
                                        child: Text(
                                          fmt.format(date),
                                          style: TextStyle(
                                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      return const SizedBox.shrink();
                                    }
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 65, // [SIP/Absolute Value Optimization] Fixed size prevents layout reflows and infinite loops
                                interval: chartInterval,
                                getTitlesWidget: (value, meta) {
                                  if ((value - meta.min).abs() < 0.01 || (value - meta.max).abs() < 0.01) {
                                    return const SizedBox.shrink();
                                  }
                                  return SideTitleWidget(
                                    meta: meta,
                                    space: 8.0,
                                    child: Text(
                                      _showAbsoluteValues 
                                          ? value.toStringAsFixed(0) 
                                          : '${value.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom: BorderSide(color: theme.dividerColor.withOpacity(0.5), width: 1),
                              left: BorderSide(color: theme.dividerColor.withOpacity(0.5), width: 1),
                              top: BorderSide.none,
                              right: BorderSide.none,
                            ),
                          ),
                          minX: 0,
                          maxX: chartData.length.toDouble() - 1,
                          minY: chartMinY,
                          maxY: chartMaxY,
                          extraLinesData: _showAbsoluteValues
                              ? const ExtraLinesData(horizontalLines: [])
                              : ExtraLinesData(
                                  horizontalLines: [
                                    HorizontalLine(
                                      y: 0.0,
                                      color: theme.colorScheme.primary.withOpacity(0.35),
                                      strokeWidth: 1.5,
                                      dashArray: [4, 4],
                                      label: HorizontalLineLabel(
                                        show: true,
                                        alignment: Alignment.topRight,
                                        style: TextStyle(
                                          color: theme.colorScheme.primary.withOpacity(0.8),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          lineBarsData: _buildLineBars(chartData),
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final index = spot.x.toInt();
                                  if (index >= 0 && index < chartData.length) {
                                    final dateStr = chartData[index]['time'] as String;
                                    final date = DateTime.parse(dateStr);
                                    final symbol = _activeIndices[spot.barIndex];
                                    final percentChange = spot.y;

                                    return LineTooltipItem(
                                      '${_getTooltipDateFormat(chartData).format(date)}\n$symbol: ${_showAbsoluteValues ? percentChange.toStringAsFixed(2) : '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(2)}%'}',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    );
                                  }
                                  return null;
                                }).toList();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<LineChartBarData> _buildLineBars(List<Map<String, dynamic>> chartData) {
    return _activeIndices.asMap().entries.map((entry) {
      final index = entry.key;
      final symbol = entry.value;
      final color = MultiIndexChart.indexColors[index % MultiIndexChart.indexColors.length];

      final spots = <FlSpot>[];
      for (int i = 0; i < chartData.length; i++) {
        final value = chartData[i][symbol];
        if (value != null) {
          spots.add(FlSpot(i.toDouble(), value as double));
        }
      }

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 2.5,
        isStrokeCapRound: true,
        dotData: FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.3),
              color.withOpacity(0.0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      );
    }).toList();
  }

  DateFormat _getDateFormat(List<Map<String, dynamic>> chartData) {
    if (chartData.isEmpty) return DateFormat('MMM yy');
    try {
      final firstDate = DateTime.parse(chartData.first['time'] as String);
      final lastDate = DateTime.parse(chartData.last['time'] as String);
      final difference = lastDate.difference(firstDate);

      if (difference.inDays <= 1) {
        return DateFormat('HH:mm');
      } else if (difference.inDays <= 7) {
        return DateFormat('E');
      } else if (difference.inDays <= 120) {
        return DateFormat('dd MMM');
      } else {
        return DateFormat('MMM yy');
      }
    } catch (_) {
      return DateFormat('MMM yy');
    }
  }

  DateFormat _getTooltipDateFormat(List<Map<String, dynamic>> chartData) {
    if (chartData.isEmpty) return DateFormat('dd MMM yy');
    try {
      final firstDate = DateTime.parse(chartData.first['time'] as String);
      final lastDate = DateTime.parse(chartData.last['time'] as String);
      final difference = lastDate.difference(firstDate);

      if (difference.inDays <= 7) {
        return DateFormat('dd MMM yy HH:mm');
      }
      return DateFormat('dd MMM yy');
    } catch (_) {
      return DateFormat('dd MMM yy');
    }
  }
}
