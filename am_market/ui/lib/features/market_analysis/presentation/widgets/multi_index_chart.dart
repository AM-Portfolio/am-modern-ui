import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';

/// Wins the gesture arena against parent [PageView] / scroll navigators so
/// vertical drags on the chart do not switch Market Data pages.
class _EagerVerticalDragRecognizer extends VerticalDragGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}

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
  final void Function(String symbol)? onRemoveIndex;

  const MultiIndexChart({
    super.key,
    required this.historicalData,
    required this.selectedIndices,
    this.isLoading = false,
    this.error,
    this.isBarChart = false,
    this.onRemoveIndex,
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
  double _zoomScale = 0.5;
  double _pinchBaseScale = 0.5;
  double _lastChartViewportWidth = 300;
  bool _isPinching = false;

  bool _showAbsoluteValues = false;
  List<Map<String, dynamic>> _chartData = [];
  List<String> _activeIndices = [];
  Set<String> _hiddenIndices = {}; // Track indices hidden by the user

  /// [SIP/Absolute Value Optimization] Helper getter to verify if the chart meets all safety conditions
  /// required to enable Multi-Label Y-Axis scaling. This requires Absolute Mode to be active, at least 2
  /// compared indices, the line chart view active, and non-infinite Y-bounds.
  bool get _useMultiYAxis =>
      _showAbsoluteValues &&
      _activeIndices.length >= 2 &&
      !widget.isBarChart;

  /// Narrow left gutter so the plot sits flush toward the left.
  /// Multi-axis uses stacked labels (not "24K | 58K" side-by-side).
  double _leftAxisReserve(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    if (compact) {
      if (_useMultiYAxis) return 36.0;
      return _showAbsoluteValues ? 34.0 : 32.0;
    }
    if (!_useMultiYAxis) {
      return _showAbsoluteValues ? 44.0 : 38.0;
    }
    return 40.0;
  }

  Widget _leftAxisTitle(TitleMeta meta, Widget child) {
    return SideTitleWidget(
      meta: meta,
      space: 2,
      child: child,
    );
  }

  String _formatAxisTick(double value) {
    if (!_showAbsoluteValues) {
      return '${value.toStringAsFixed(1)}%';
    }
    final abs = value.abs();
    if (abs >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildLeftAxisLabel({
    required BuildContext context,
    required TitleMeta meta,
    required double value,
    required Map<String, double> cleanMin,
    required Map<String, double> cleanMax,
  }) {
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 700;

    if (_useMultiYAxis && _activeIndices.isNotEmpty) {
      final String firstSymbol = _activeIndices.first;
      final double denominator0 =
          cleanMax[firstSymbol]! - cleanMin[firstSymbol]!;
      final List<Widget> rows = [];

      for (int i = 0; i < _activeIndices.length; i++) {
        final String symbol = _activeIndices[i];
        double tickVal = value;
        if (i > 0) {
          final double denI = cleanMax[symbol]! - cleanMin[symbol]!;
          tickVal = denominator0.abs() < 0.01
              ? cleanMin[symbol]!
              : cleanMin[symbol]! +
                  (value - cleanMin[firstSymbol]!) / denominator0 * denI;
        }
        final color = MultiIndexChart
            .indexColors[i % MultiIndexChart.indexColors.length];
        rows.add(
          Text(
            _formatAxisTick(tickVal),
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: compact ? 8.5 : 9.5,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        );
      }

      return _leftAxisTitle(
        meta,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: rows,
        ),
      );
    }

    return _leftAxisTitle(
      meta,
      Text(
        _formatAxisTick(value),
        textAlign: TextAlign.right,
        style: TextStyle(
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.75),
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w500,
          height: 1.1,
        ),
      ),
    );
  }

  /// Returns true when the chart is scrolled to (or near) the right edge,
  /// meaning the user is viewing the most recent data points.
  /// Pills are only meaningful when the latest data is visible.
  bool get _isViewingRecentData {
    if (!_scrollController.hasClients) return true;
    final pos = _scrollController.position;
    if (pos.maxScrollExtent < 1.0) return true; // chart fits entirely in viewport
    return (pos.maxScrollExtent - pos.pixels) < 40.0;
  }

  DateTime? _parseFlexibleDateTime(String str) {
    final parsed = DateTime.tryParse(str);
    if (parsed != null) return parsed;

    // Handle epoch milliseconds (e.g. 1682492067689)
    final ms = int.tryParse(str);
    if (ms != null) {
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }

    // Separate date and time parts to preserve intraday hours/minutes
    try {
      final spaceParts = str.split(' ');
      final datePart = spaceParts[0];
      final timePart = spaceParts.length > 1 ? spaceParts[1] : '';

      final dateSubparts = datePart.split(RegExp(r'[-/]'));
      if (dateSubparts.length >= 3) {
        final int? first = int.tryParse(dateSubparts[0]);
        final int? second = int.tryParse(dateSubparts[1]);
        final int? third = int.tryParse(dateSubparts[2]);

        if (first != null && second != null && third != null) {
          int year = 0;
          int month = 0;
          int day = 0;
          if (first > 1000) {
            year = first;
            month = second;
            day = third;
          } else if (third > 1000) {
            year = third;
            month = second;
            day = first;
          }

          if (year > 1000) {
            int hour = 0;
            int minute = 0;
            int secondVal = 0;
            if (timePart.isNotEmpty) {
              final timeSubparts = timePart.split(':');
              if (timeSubparts.length >= 2) {
                hour = int.tryParse(timeSubparts[0]) ?? 0;
                minute = int.tryParse(timeSubparts[1]) ?? 0;
                if (timeSubparts.length >= 3) {
                  secondVal = int.tryParse(timeSubparts[2]) ?? 0;
                }
              }
            }
            return DateTime(year, month, day, hour, minute, secondVal);
          }
        }
      }
    } catch (_) {}

    return null;
  }

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
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MultiIndexChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Automatically fallback to Percentage Mode on Bar Chart view
    if (widget.isBarChart) {
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
    if (mounted) {
      setState(() {});
    }
  }

  /// 🛡️ Active Indices Safety Filter & Union Alignment
  void _prepareDataAndRecalculate(
      {bool resetViewport = false, bool isInitial = false}) {
    // 1. Safety Filter: Find which selected indices actually have data
    _activeIndices = widget.selectedIndices.where((symbol) {
      final data = widget.historicalData[symbol];
      return data != null && data.isNotEmpty;
    }).toList();

    if (_activeIndices.isEmpty) {
      _chartData = [];
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
        final dt = _parseFlexibleDateTime(timeStr);
        if (dt == null) return timeStr;
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
          if (matchingPoint.isNotEmpty) {
            final pVal = matchingPoint['close'] ??
                matchingPoint['price'] ??
                matchingPoint['lastPrice'] ??
                matchingPoint['value'];
            if (pVal != null) {
              baselinePrices[symbol] = (pVal as num).toDouble();
              break;
            }
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

          if (matchingPoint.isNotEmpty) {
            final pVal = matchingPoint['close'] ??
                matchingPoint['price'] ??
                matchingPoint['lastPrice'] ??
                matchingPoint['value'];
            if (pVal != null) {
              final price = (pVal as num).toDouble();
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
            }
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
      if (resetViewport && !isInitial) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
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

    // Snap to clean ticks with a light margin (~½ interval) so the series
    // fills the plot instead of floating in the vertical middle.
    final double pad = interval * 0.5;
    final double minY =
        (minVal / interval).floorToDouble() * interval - pad;
    final double maxY =
        (maxVal / interval).ceilToDouble() * interval + pad;

    return {'minY': minY, 'maxY': maxY, 'interval': interval};
  }

  // Viewport calculations are now performed inline during build for absolute consistency.
  Map<String, dynamic> _calculateVisibleViewport(
      List<Map<String, dynamic>> chartData, double spacing, double viewportWidth) {
    double scrollOffset = 0.0;
    if (_scrollController.hasClients) {
      scrollOffset = _scrollController.offset;
    }

    int startIndex = (scrollOffset / spacing).floor();
    int endIndex = ((scrollOffset + viewportWidth) / spacing).ceil();

    if (startIndex < 0) startIndex = 0;
    if (endIndex >= chartData.length) endIndex = chartData.length - 1;
    if (startIndex > endIndex) startIndex = endIndex;

    final visibleData = chartData.sublist(startIndex, endIndex + 1);

    final Map<String, double> cleanMin = {};
    final Map<String, double> cleanMax = {};
    final Map<String, double> cleanInterval = {};

    final bool isMulti = _showAbsoluteValues && !widget.isBarChart;

    for (final symbol in _activeIndices) {
      double minVal = double.infinity;
      double maxVal = double.negativeInfinity;

      for (final point in visibleData) {
        final val = point[symbol];
        if (val != null) {
          final double dVal = val as double;
          if (dVal < minVal) minVal = dVal;
          if (dVal > maxVal) maxVal = dVal;
        }
      }

      if (!isMulti) {
        double globalMin = double.infinity;
        double globalMax = double.negativeInfinity;
        for (final sym in _activeIndices) {
          for (final point in visibleData) {
            final val = point[sym];
            if (val != null) {
              final double dVal = val as double;
              if (dVal < globalMin) globalMin = dVal;
              if (dVal > globalMax) globalMax = dVal;
            }
          }
        }
        final bounds = _calculateCleanBounds(globalMin, globalMax);
        for (final sym in _activeIndices) {
          cleanMin[sym] = bounds['minY']!;
          cleanMax[sym] = bounds['maxY']!;
          cleanInterval[sym] = bounds['interval']!;
        }
        break;
      } else {
        if (minVal != double.infinity && maxVal != double.negativeInfinity) {
          final bounds = _calculateCleanBounds(minVal, maxVal);
          cleanMin[symbol] = bounds['minY']!;
          cleanMax[symbol] = bounds['maxY']!;
          cleanInterval[symbol] = bounds['interval']!;
        } else {
          cleanMin[symbol] = -5.0;
          cleanMax[symbol] = 5.0;
          cleanInterval[symbol] = 2.0;
        }
      }
    }

    return {
      'visibleData': visibleData,
      'startIndex': startIndex,
      'endIndex': endIndex,
      'cleanMin': cleanMin,
      'cleanMax': cleanMax,
      'cleanInterval': cleanInterval,
    };
  }

  /// 🔍 Center-Anchored Zooming
  void _zoom(double newScale, [double? viewportWidth]) {
    final vw = viewportWidth ?? _lastChartViewportWidth;
    if (newScale < 0.35) newScale = 0.35;
    if (newScale > 3.0) newScale = 3.0;
    if ((newScale - _zoomScale).abs() < 0.001) return;

    final oldScale = _zoomScale;
    final oldSpacing = 30.0 * oldScale;
    final newSpacing = 30.0 * newScale;

    double centerIndex = 0.0;
    if (_scrollController.hasClients) {
      final oldScrollOffset = _scrollController.offset;
      centerIndex = (oldScrollOffset + vw / 2) / oldSpacing;
    }

    setState(() {
      _zoomScale = newScale;
    });

    _prepareDataAndRecalculate();

    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final newScrollOffset = (centerIndex * newSpacing) - (vw / 2);
          final maxScroll = _scrollController.position.maxScrollExtent;
          _scrollController.jumpTo(newScrollOffset.clamp(0.0, maxScroll));
        }
      });
    }
  }

  void _panBy(double dx) {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    // Nothing to pan until zoomed in enough for overflow.
    if (maxScroll <= 0) return;
    final newOffset = (_scrollController.offset - dx).clamp(0.0, maxScroll);
    _scrollController.jumpTo(newOffset);
  }

  /// Pinch zoom + horizontal pan. Blocks parent vertical PageView from
  /// stealing drags that start on the chart.
  Widget _wrapChartGestures({
    required double viewportWidth,
    required Widget child,
  }) {
    _lastChartViewportWidth = viewportWidth;

    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        // Absorb vertical drags so Dashboard ↔ Market Analysis does not switch.
        _EagerVerticalDragRecognizer:
            GestureRecognizerFactoryWithHandlers<_EagerVerticalDragRecognizer>(
          () => _EagerVerticalDragRecognizer(),
          (_EagerVerticalDragRecognizer instance) {
            instance
              ..onStart = (_) {}
              ..onUpdate = (_) {}
              ..onEnd = (_) {};
          },
        ),
        ScaleGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
          () => ScaleGestureRecognizer(),
          (ScaleGestureRecognizer instance) {
            instance
              ..onStart = (details) {
                _pinchBaseScale = _zoomScale;
                _isPinching = details.pointerCount >= 2;
              }
              ..onUpdate = (details) {
                if (details.pointerCount >= 2) {
                  _isPinching = true;
                  _zoom(
                    _pinchBaseScale * details.scale,
                    viewportWidth,
                  );
                } else if (details.focalPointDelta.dx.abs() > 0.5) {
                  // One-finger horizontal pan of the timeline
                  _panBy(details.focalPointDelta.dx);
                }
              }
              ..onEnd = (_) {
                _isPinching = false;
              };
          },
        ),
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerSignal: (event) =>
            _handlePointerSignal(event, viewportWidth),
        child: child,
      ),
    );
  }

  /// 🖱️ Mouse Wheel Panning (Normal) & Zoom (Ctrl + Wheel)
  void _handlePointerSignal(PointerSignalEvent event, double viewportWidth) {
    if (event is PointerScrollEvent) {
      final isCtrlPressed = RawKeyboard.instance.keysPressed
              .contains(LogicalKeyboardKey.controlLeft) ||
          RawKeyboard.instance.keysPressed
              .contains(LogicalKeyboardKey.controlRight) ||
          HardwareKeyboard.instance.isControlPressed;

      if (isCtrlPressed) {
        final double zoomChange = event.scrollDelta.dy > 0 ? -0.1 : 0.1;
        _zoom(_zoomScale + zoomChange, viewportWidth);
      } else {
        if (_scrollController.hasClients) {
          // Inverted DY so that scrolling down moves the timeline left, 
          // and added DX for trackpad horizontal support.
          final double newOffset =
              _scrollController.offset - event.scrollDelta.dy + event.scrollDelta.dx;
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
                'Select up to 5 indices with valid data to compare',
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
    final isCompact = MediaQuery.sizeOf(context).width < 700;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 4 : 24,
        isCompact ? 10 : 24,
        isCompact ? 8 : 24,
        isCompact ? 10 : 24,
      ),
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
          // Legend + %/123 toggles — wrap on narrow screens to avoid overflow.
          if (isCompact) ...[
            _buildLegend(context),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildUnitToggle(context),
                const Spacer(),
                if (!widget.isBarChart) _buildZoomControls(theme),
              ],
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildLegend(context)),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildUnitToggle(context),
                    const SizedBox(width: 8),
                    if (!widget.isBarChart) _buildZoomControls(theme),
                  ],
                ),
              ],
            ),
          SizedBox(height: isCompact ? 8 : 24),
          Expanded(
            child: widget.isBarChart
                ? _buildBarChart(context, _chartData)
                : _buildChart(context, _chartData),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitToggle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: (Theme.of(context).brightness == Brightness.dark)
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
            isEnabled: !widget.isBarChart,
            onTap: () {
              setState(() {
                _showAbsoluteValues = true;
                _prepareDataAndRecalculate(resetViewport: true);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildZoomControls(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(Icons.zoom_out, color: Color(0xFF00D1FF), size: 22),
          onPressed: () => _zoom(_zoomScale - 0.2),
          tooltip: 'Zoom Out',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            '${(_zoomScale * 100).toInt()}%',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(Icons.zoom_in, color: Color(0xFF00D1FF), size: 22),
          onPressed: () => _zoom(_zoomScale + 0.2),
          tooltip: 'Zoom In',
        ),
      ],
    );
  }

  /// [SIP/Absolute Value Optimization] Builds a single segment button for the Y-Axis mode toggle
  Widget _buildToggleSegment({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected
        ? const Color(0xFF00D1FF)
        : (isEnabled 
            ? (isDark ? Colors.white70 : Colors.black87) 
            : (isDark ? Colors.white24 : Colors.black26));
    final bgColor = isSelected
        ? const Color(0xFF00D1FF).withOpacity(0.15)
        : Colors.transparent;

    return IgnorePointer(
      ignoring: !isEnabled,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: Tooltip(
          message: !isEnabled && label == '123'
              ? 'Absolute mode is not supported on Bar Charts'
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
    final isCompact = MediaQuery.sizeOf(context).width < 700;
    return Wrap(
      spacing: isCompact ? 12 : 24,
      runSpacing: 8,
      children: _activeIndices.asMap().entries.map((entry) {
        final index = entry.key;
        final symbol = entry.value;
        final color = MultiIndexChart
            .indexColors[index % MultiIndexChart.indexColors.length];
        final isHidden = _hiddenIndices.contains(symbol);

        return AmClickCapsule(
          triggerOnHover: true,
          popupContent: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isHidden ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    if (isHidden) {
                      _hiddenIndices.remove(symbol);
                    } else {
                      _hiddenIndices.add(symbol);
                    }
                  });
                },
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  if (widget.onRemoveIndex != null) {
                    widget.onRemoveIndex!(symbol);
                  }
                },
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isCompact ? 12 : 16,
                height: 3,
                decoration: BoxDecoration(
                  color: isHidden ? Colors.grey : color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                symbol,
                style: TextStyle(
                  color: isHidden
                      ? Colors.grey
                      : theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                  decoration: isHidden ? TextDecoration.lineThrough : null,
                  fontSize: isCompact ? 11 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBarChart(
      BuildContext context, List<Map<String, dynamic>> chartData) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = (_activeIndices.length * 10.0 + 20.0);
        final double chartWidth = chartData.length * spacing;
        final double viewportWidth = constraints.maxWidth - _leftAxisReserve(context);

        final viewportInfo = _calculateVisibleViewport(chartData, spacing, viewportWidth);
        final List<Map<String, dynamic>> visibleData = viewportInfo['visibleData'];
        final int startIndex = viewportInfo['startIndex'];
        final Map<String, double> cleanMin = viewportInfo['cleanMin'];
        final Map<String, double> cleanMax = viewportInfo['cleanMax'];

        final String firstSymbol = _activeIndices.isNotEmpty ? _activeIndices.first : '';
        final double targetMin = cleanMin[firstSymbol] ?? -5.0;
        final double targetMax = cleanMax[firstSymbol] ?? 5.0;

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TweenAnimationBuilder<ChartViewportRange>(
                tween: ChartViewportRangeTween(
                  begin: ChartViewportRange(targetMin, targetMax),
                  end: ChartViewportRange(targetMin, targetMax),
                ),
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                builder: (context, range, child) {
                  final double chartMinY = range.minY;
                  final double chartMaxY = range.maxY;
                  final double chartInterval = _calculateCleanBounds(chartMinY, chartMaxY)['interval']!;

                  return _wrapChartGestures(
                    viewportWidth: constraints.maxWidth - _leftAxisReserve(context),
                    child: BarChart(
                        key: ValueKey(
                            '${_activeIndices.join('-')}_bar_${visibleData.length}'),
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
                            rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  final originalIndex = startIndex + index;
                                  if (originalIndex >= 0 && originalIndex < chartData.length) {
                                    if (chartData.length > 20 &&
                                        originalIndex % (chartData.length ~/ 10) != 0) {
                                      return const SizedBox.shrink();
                                    }

                                    final dateStr =
                                        chartData[originalIndex]['time'] as String;
                                    try {
                                      final date = DateTime.parse(dateStr);
                                      final fmt = _getDateFormat(chartData);

                                      final interval = (chartData.length > 20)
                                          ? (chartData.length ~/ 10)
                                          : 1;
                                      final prevIndex =
                                          ((originalIndex - 1) ~/ interval) * interval;
                                      if (prevIndex >= 0) {
                                        try {
                                          final prevDate = DateTime.parse(
                                              chartData[prevIndex]['time']
                                                  as String);
                                          if (fmt.format(prevDate) ==
                                              fmt.format(date)) {
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
                                            color: theme
                                                .textTheme.bodySmall?.color
                                                ?.withOpacity(0.6),
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
                                reservedSize: _leftAxisReserve(context),
                                interval: chartInterval,
                                getTitlesWidget: (value, meta) {
                                  if ((value - meta.min).abs() < 0.01 ||
                                      (value - meta.max).abs() < 0.01) {
                                    return const SizedBox.shrink();
                                  }
                                  return _buildLeftAxisLabel(
                                    context: context,
                                    meta: meta,
                                    value: value,
                                    cleanMin: cleanMin,
                                    cleanMax: cleanMax,
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom: BorderSide(
                                  color: theme.dividerColor.withOpacity(0.5),
                                  width: 1),
                              left: BorderSide(
                                  color: theme.dividerColor.withOpacity(0.5),
                                  width: 1),
                              top: BorderSide.none,
                              right: BorderSide.none,
                            ),
                          ),
                          minY: chartMinY,
                          maxY: chartMaxY,
                          barGroups: visibleData.asMap().entries.map((entry) {
                            final index = entry.key;
                            final point = entry.value;

                            return BarChartGroupData(
                              x: index,
                              barsSpace: 4,
                              barRods: _activeIndices
                                  .asMap()
                                  .entries
                                  .where((entry) => !_hiddenIndices.contains(entry.value))
                                  .map((idxEntry) {
                                final idx = idxEntry.key;
                                final symbol = idxEntry.value;
                                final val =
                                    (point[symbol] as num?)?.toDouble() ?? 0.0;
                                final isNegative = val < 0;
                                final color = isNegative
                                    ? const Color(0xFFEF4444)
                                    : MultiIndexChart.indexColors[idx %
                                        MultiIndexChart.indexColors.length];

                                return BarChartRodData(
                                  toY: val,
                                  color: color,
                                  width: 14,
                                  borderRadius: val > 0
                                      ? const BorderRadius.only(
                                          topLeft: Radius.circular(2),
                                          topRight: Radius.circular(2))
                                      : const BorderRadius.only(
                                          bottomLeft: Radius.circular(2),
                                          bottomRight: Radius.circular(2)),
                                  backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: 0,
                                      color: Colors.transparent),
                                );
                              }).toList(),
                            );
                          }).toList(),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              fitInsideHorizontally: true,
                              fitInsideVertically: true,
                              getTooltipColor: (_) =>
                                  theme.cardColor.withOpacity(0.6),
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                final originalIndex = startIndex + group.x;
                                final dateStr =
                                    chartData[originalIndex]['time'] as String;
                                final date = DateTime.parse(dateStr);
                                final visibleIndices = _activeIndices.where((s) => !_hiddenIndices.contains(s)).toList();
                                final symbol = visibleIndices[rodIndex];
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
                  );
                },
              ),
            ),
            _buildDummyScrollView(chartWidth),
          ],
        );
      },
    );
  }

  Widget _buildChart(
      BuildContext context, List<Map<String, dynamic>> chartData) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = 30.0 * _zoomScale;
        final double chartWidth = chartData.length * spacing;
        final double viewportWidth = constraints.maxWidth - _leftAxisReserve(context);

        final viewportInfo = _calculateVisibleViewport(chartData, spacing, viewportWidth);
        final List<Map<String, dynamic>> visibleData = viewportInfo['visibleData'];
        final int startIndex = viewportInfo['startIndex'];
        final int endIndex = viewportInfo['endIndex'];
        final Map<String, double> cleanMin = viewportInfo['cleanMin'];
        final Map<String, double> cleanMax = viewportInfo['cleanMax'];

        final String firstSymbol = _activeIndices.isNotEmpty ? _activeIndices.first : '';
        final double targetMin = cleanMin[firstSymbol] ?? -5.0;
        final double targetMax = cleanMax[firstSymbol] ?? 5.0;

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TweenAnimationBuilder<ChartViewportRange>(
                tween: ChartViewportRangeTween(
                  begin: ChartViewportRange(targetMin, targetMax),
                  end: ChartViewportRange(targetMin, targetMax),
                ),
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                builder: (context, range, child) {
                  final double chartMinY = range.minY;
                  final double chartMaxY = range.maxY;
                  final double chartInterval = _calculateCleanBounds(chartMinY, chartMaxY)['interval']!;

                  return _wrapChartGestures(
                    viewportWidth:
                        constraints.maxWidth - _leftAxisReserve(context),
                    child: LineChart(
                        key: ValueKey(
                            '${_activeIndices.join('-')}_line_${visibleData.length}'),
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
                            rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: (visibleData.length / 8).ceilToDouble(),
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  final originalIndex = startIndex + index;
                                  if (originalIndex >= 0 && originalIndex < chartData.length) {
                                    final interval = (visibleData.length / 8).ceil();
                                    if (index == visibleData.length - 1 &&
                                        interval > 1) {
                                      final lastIntervalTick =
                                          ((visibleData.length - 1) ~/ interval) *
                                              interval;
                                      if (visibleData.length - 1 !=
                                              lastIntervalTick &&
                                          visibleData.length -
                                                  1 -
                                                  lastIntervalTick <
                                              interval / 2) {
                                        return const SizedBox.shrink();
                                      }
                                    }

                                    final dateStr =
                                        chartData[originalIndex]['time'] as String;
                                    try {
                                      final date = DateTime.parse(dateStr);
                                      final fmt = _getDateFormat(chartData);

                                      final prevIndex =
                                          ((originalIndex - 1) ~/ interval) * interval;
                                      if (prevIndex >= 0) {
                                        try {
                                          final prevDate = DateTime.parse(
                                              chartData[prevIndex]['time']
                                                  as String);
                                          if (fmt.format(prevDate) ==
                                              fmt.format(date)) {
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
                                            color: theme
                                                .textTheme.bodySmall?.color
                                                ?.withOpacity(0.6),
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
                                reservedSize: _leftAxisReserve(context),
                                interval: chartInterval,
                                getTitlesWidget: (value, meta) {
                                  if ((value - meta.min).abs() < 0.01 ||
                                      (value - meta.max).abs() < 0.01) {
                                    return const SizedBox.shrink();
                                  }
                                  return _buildLeftAxisLabel(
                                    context: context,
                                    meta: meta,
                                    value: value,
                                    cleanMin: cleanMin,
                                    cleanMax: cleanMax,
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom: BorderSide(
                                  color: theme.dividerColor.withOpacity(0.5),
                                  width: 1),
                              left: BorderSide(
                                  color: theme.dividerColor.withOpacity(0.5),
                                  width: 1),
                              top: BorderSide.none,
                              right: BorderSide.none,
                            ),
                          ),
                          minX: 0,
                          maxX: visibleData.length.toDouble() - 1,
                          minY: chartMinY,
                          maxY: chartMaxY,
                          extraLinesData: ExtraLinesData(
                            horizontalLines: [
                              if (!_showAbsoluteValues)
                                HorizontalLine(
                                  y: 0.0,
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.35),
                                  strokeWidth: 1.5,
                                  dashArray: [4, 4],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    alignment: Alignment.topRight,
                                    style: TextStyle(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.8),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ..._activeIndices.asMap().entries.where((e) => !_hiddenIndices.contains(e.value)).map((entry) {
                                final index = entry.key;
                                final symbol = entry.value;
                                final val = visibleData.last[symbol];
                                if (val == null) {
                                  return HorizontalLine(y: 0, strokeWidth: 0);
                                }

                                final double originalY = val as double;
                                final Color color =
                                    MultiIndexChart.indexColors[index %
                                        MultiIndexChart.indexColors.length];

                                double drawY = originalY;
                                if (_useMultiYAxis && index > 0 && index < _activeIndices.length) {
                                  final String firstSymbol = _activeIndices.first;
                                  final double denom = cleanMax[symbol]! - cleanMin[symbol]!;
                                  final double range0 = cleanMax[firstSymbol]! - cleanMin[firstSymbol]!;
                                  drawY = denom.abs() < 0.01
                                      ? cleanMin[firstSymbol]!
                                      : cleanMin[firstSymbol]! +
                                          (originalY - cleanMin[symbol]!) /
                                              denom *
                                              range0;
                                }

                                return HorizontalLine(
                                  y: drawY,
                                  color: color.withOpacity(0.35),
                                  strokeWidth: 1,
                                  dashArray: [3, 3],
                                );
                              }).toList(),
                            ],
                          ),
                          lineBarsData: _buildLineBars(visibleData, cleanMin, cleanMax),
                          lineTouchData: LineTouchData(
                            enabled: true,
                            handleBuiltInTouches: true,
                            touchTooltipData: LineTouchTooltipData(
                              fitInsideHorizontally: true,
                              fitInsideVertically: true,
                              getTooltipColor: (touchedSpot) =>
                                  theme.cardColor.withOpacity(0.6),
                              getTooltipItems: (touchedSpots) {
                                if (touchedSpots.isEmpty) {
                                  return [];
                                }

                                // Stable order by series, shared timestamp once at top.
                                final spots = List<LineBarSpot>.from(touchedSpots)
                                  ..sort((a, b) =>
                                      a.barIndex.compareTo(b.barIndex));

                                final firstSpot = spots.first;
                                final originalIndex =
                                    startIndex + firstSpot.x.toInt();
                                if (originalIndex < 0 ||
                                    originalIndex >= chartData.length) {
                                  return [];
                                }

                                final dateStr =
                                    chartData[originalIndex]['time'] as String;
                                final date = DateTime.parse(dateStr);
                                final dateLabel = _getTooltipDateFormat(
                                  chartData,
                                ).format(date);
                                final visibleIndices = _activeIndices
                                    .where((s) => !_hiddenIndices.contains(s))
                                    .toList();
                                final muted = theme
                                        .textTheme.bodySmall?.color
                                        ?.withOpacity(0.75) ??
                                    Colors.grey;

                                return spots.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final spot = entry.value;
                                  if (spot.barIndex < 0 ||
                                      spot.barIndex >=
                                          visibleIndices.length) {
                                    return LineTooltipItem(
                                      '',
                                      const TextStyle(fontSize: 0),
                                    );
                                  }
                                  final symbol =
                                      visibleIndices[spot.barIndex];

                                  double displayVal = spot.y;
                                  final int barIdx = spot.barIndex;
                                  if (_useMultiYAxis &&
                                      barIdx > 0 &&
                                      barIdx < _activeIndices.length) {
                                    final String firstSymbol =
                                        _activeIndices.first;
                                    final String currentSymbol =
                                        _activeIndices[barIdx];
                                    final double denominator0 =
                                        cleanMax[firstSymbol]! -
                                            cleanMin[firstSymbol]!;
                                    final double denIdx =
                                        cleanMax[currentSymbol]! -
                                            cleanMin[currentSymbol]!;
                                    displayVal = denominator0.abs() < 0.01
                                        ? cleanMin[currentSymbol]!
                                        : cleanMin[currentSymbol]! +
                                            (spot.y -
                                                    cleanMin[firstSymbol]!) /
                                                denominator0 *
                                                denIdx;
                                  }

                                  final valueText = _showAbsoluteValues
                                      ? displayVal.toStringAsFixed(2)
                                      : '${displayVal >= 0 ? '+' : ''}${displayVal.toStringAsFixed(2)}%';
                                  final seriesColor = MultiIndexChart
                                      .indexColors[spot.barIndex %
                                          MultiIndexChart.indexColors.length];

                                  if (i == 0) {
                                    return LineTooltipItem(
                                      '$dateLabel\n',
                                      TextStyle(
                                        color: muted,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '$symbol  $valueText',
                                          style: TextStyle(
                                            color: seriesColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  return LineTooltipItem(
                                    '$symbol  $valueText',
                                    TextStyle(
                                      color: seriesColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                        ),
                      ),
                  );
                },
              ),
            ),
            _buildDummyScrollView(chartWidth),
            _buildPricePills(context, chartData, constraints, cleanMin, cleanMax, endIndex == chartData.length - 1),
          ],
        );
      },
    );
  }

  List<LineChartBarData> _buildLineBars(List<Map<String, dynamic>> visibleData, Map<String, double> cleanMin, Map<String, double> cleanMax) {
    return _activeIndices.asMap().entries.where((entry) => !_hiddenIndices.contains(entry.value)).map((entry) {
      final index = entry.key;
      final symbol = entry.value;
      final color = MultiIndexChart
          .indexColors[index % MultiIndexChart.indexColors.length];

      final spots = <FlSpot>[];
      for (int i = 0; i < visibleData.length; i++) {
        final value = visibleData[i][symbol];
        if (value != null) {
          final double originalY = value as double;

          if (_useMultiYAxis && index > 0 && index < _activeIndices.length) {
            final String firstSymbol = _activeIndices.first;
            final double denominator = cleanMax[symbol]! - cleanMin[symbol]!;
            final double range0 = cleanMax[firstSymbol]! - cleanMin[firstSymbol]!;
            final double scaledY = denominator.abs() < 0.01
                ? cleanMin[firstSymbol]!
                : cleanMin[firstSymbol]! +
                    (originalY - cleanMin[symbol]!) / denominator * range0;

            spots.add(FlSpot(i.toDouble(), scaledY));
          } else {
            spots.add(FlSpot(i.toDouble(), originalY));
          }
        }
      }

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 2.5,
        isStrokeCapRound: true,
        shadow: Shadow(
          color: color.withOpacity(0.35),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
        dotData: FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.25),
              color.withOpacity(0.0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildPricePills(
    BuildContext context,
    List<Map<String, dynamic>> chartData,
    BoxConstraints constraints,
    Map<String, double> cleanMin,
    Map<String, double> cleanMax,
    bool showPills,
  ) {
    if (!showPills) return const SizedBox.shrink();
    if (chartData.isEmpty || _activeIndices.isEmpty) return const SizedBox.shrink();

    const double bottomReserved = 30.0;
    final double plotHeight = constraints.maxHeight - bottomReserved;
    final List<Map<String, dynamic>> pillData = [];

    for (int i = 0; i < _activeIndices.length; i++) {
      final String symbol = _activeIndices[i];
      final dynamic rawVal = chartData.last[symbol];
      if (rawVal == null) continue;

      final double originalY = rawVal as double;
      final Color color = MultiIndexChart.indexColors[
          i % MultiIndexChart.indexColors.length];

      double drawY = originalY;
      if (_useMultiYAxis && i > 0 && i < _activeIndices.length) {
        final String firstSymbol = _activeIndices.first;
        final double denom = cleanMax[symbol]! - cleanMin[symbol]!;
        final double range0 = cleanMax[firstSymbol]! - cleanMin[firstSymbol]!;
        drawY = denom.abs() < 0.01
            ? cleanMin[firstSymbol]!
            : cleanMin[firstSymbol]! + (originalY - cleanMin[symbol]!) / denom * range0;
      }

      final String firstSymbol = _activeIndices.isNotEmpty ? _activeIndices.first : '';
      final double minY = cleanMin[firstSymbol] ?? -5.0;
      final double maxY = cleanMax[firstSymbol] ?? 5.0;
      final double yRange = maxY - minY;
      final double topFraction =
          yRange.abs() < 0.01 ? 0.5 : (maxY - drawY) / yRange;
      final double topOffset = (topFraction * plotHeight).clamp(2.0, plotHeight - 22.0);

      final String labelText = _showAbsoluteValues
          ? originalY.toStringAsFixed(2)
          : '${originalY >= 0 ? '+' : ''}${originalY.toStringAsFixed(2)}%';

      pillData.add({
        'topOffset': topOffset,
        'color': color,
        'label': labelText,
      });
    }

    if (pillData.isEmpty) return const SizedBox.shrink();

    pillData.sort(
        (a, b) => (a['topOffset'] as double).compareTo(b['topOffset'] as double));
    const double minPillGap = 24.0;
    for (int i = 1; i < pillData.length; i++) {
      final double prev = pillData[i - 1]['topOffset'] as double;
      final double curr = pillData[i]['topOffset'] as double;
      if (curr - prev < minPillGap) {
        pillData[i]['topOffset'] = (prev + minPillGap).clamp(2.0, plotHeight - 22.0);
      }
    }

    return Stack(
      children: pillData.map((pill) {
        final Color color = pill['color'] as Color;
        final String label = pill['label'] as String;
        final double top = pill['topOffset'] as double;

        return Positioned(
          right: 0,
          top: top,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.55),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDummyScrollView(double chartWidth) {
    return Positioned(
      bottom: 0,
      left: _leftAxisReserve(context),
      right: 0,
      height: 12,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            width: chartWidth,
            height: 1,
          ),
        ),
      ),
    );
  }

  DateFormat _getDateFormat(List<Map<String, dynamic>> chartData) {
    if (chartData.isEmpty) return DateFormat('MMM yy');
    try {
      final firstDate = _parseFlexibleDateTime(chartData.first['time'] as String);
      final lastDate = _parseFlexibleDateTime(chartData.last['time'] as String);
      if (firstDate == null || lastDate == null) return DateFormat('MMM yy');
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
      final firstDate = _parseFlexibleDateTime(chartData.first['time'] as String);
      final lastDate = _parseFlexibleDateTime(chartData.last['time'] as String);
      if (firstDate == null || lastDate == null) return DateFormat('dd MMM yy');
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
