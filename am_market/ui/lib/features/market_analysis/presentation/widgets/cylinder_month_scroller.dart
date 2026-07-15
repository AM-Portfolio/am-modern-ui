import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:am_market_common/models/indices_performance_model.dart';
import 'package:am_market_ui/features/market_analysis/presentation/widgets/monthly_performance_card.dart';

/// Unified drum-roll month scroller.
///
/// Uses a single Stack layout in BOTH flat and drum mode.
/// A [_drumFactor] (0→1) interpolates between two item-position formulas:
///
///   FLAT  (drumFactor=0): itemX = offset * itemWidth          (linear, like a scroll)
///   DRUM  (drumFactor=1): itemX = R * sin(offset * θ)         (cylinder arc)
///                         itemZ = R * cos(offset * θ) - R     (depth)
///                         rotY  = -(offset * θ)               (outside-drum face)
///
/// KEY CALIBRATION: R = 2 × itemWidth, θ = 30°
///   → R × sin(30°) = 2W × 0.5 = W = itemWidth
///   → adjacent item's drum X == adjacent item's flat X (seamless transition!)
///   → The lerp causes NO lateral jump when drum activates — only rotation appears.
///
/// BEHAVIOUR:
///   Default: 3 months visible, no 3D. Identical to original SS1/SS2 flat table.
///   Drag start: drum morphs in over 250ms (drumFactor 0→1).
///   Dragging: offset updates continuously → smooth cylinder roll.
///   Drag end: offset snaps to nearest month, then drum morphs out (drumFactor 1→0).
class CylinderMonthScroller extends StatefulWidget {
  final List<String> months;
  final List<String> shortMonths;
  final List<int> sortedYears;
  final Map<int, Map<String, MonthlyIndicesPerformance>> groupedData;
  final double rowHeight;
  final bool isDark;

  const CylinderMonthScroller({
    Key? key,
    required this.months,
    required this.shortMonths,
    required this.sortedYears,
    required this.groupedData,
    required this.rowHeight,
    required this.isDark,
  }) : super(key: key);

  @override
  State<CylinderMonthScroller> createState() => _CylinderMonthScrollerState();
}

class _CylinderMonthScrollerState extends State<CylinderMonthScroller>
    with TickerProviderStateMixin {

  double _offset = 0.0;        // Current fractional month index (0=JAN, 11=DEC)
  double _drumFactor = 0.0;    // 0=flat, 1=full drum cylinder
  double _itemWidth = 110.0;   // Set in build() from LayoutBuilder
  int _lastHapticPage = 0;

  late AnimationController _drumController;  // Activates/deactivates drum morph
  late AnimationController _snapController;  // Snaps _offset to nearest integer

  // ─── Cylinder config ─────────────────────────────────────────────────────
  /// 30° per month step on the cylinder.
  /// With R = 2×itemWidth: R×sin(30°) = itemWidth → drum X == flat X for adjacent items.
  /// This means the morph from flat→drum causes ZERO lateral shift — only rotation appears.
  static const double _anglePerStep = pi / 6.0;   // 30° per month

  /// Drum activation: how fast the cylinder morphs in/out.
  static const Duration _drumInDuration  = Duration(milliseconds: 220);
  static const Duration _drumOutDuration = Duration(milliseconds: 300);

  /// Max perspective depth at full drum factor.
  static const double _maxPerspective = 0.0016;

  /// Render items within ±3 months from center (further items are invisible).
  static const int _cullDistance = 3;

  @override
  void initState() {
    super.initState();

    _drumController = AnimationController(vsync: this)
      ..addListener(() => setState(() => _drumFactor = _drumController.value));

    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void dispose() {
    _drumController.dispose();
    _snapController.dispose();
    super.dispose();
  }

  // ─── Gesture handlers ────────────────────────────────────────────────────

  void _onDragStart(DragStartDetails _) {
    if (_snapController.isAnimating) _snapController.stop();
    // Morph into drum mode
    _drumController.animateTo(
      1.0,
      duration: _drumInDuration,
      curve: Curves.easeOut,
    );
  }

  void _onDragUpdate(DragUpdateDetails d) {
    // 1 month step = 1 itemWidth of drag distance.
    // This maps directly to the visual column width → feels like touching the card.
    setState(() {
      _offset = (_offset - d.delta.dx / _itemWidth)
          .clamp(0.0, widget.months.length - 1.0);
    });
    _maybeHaptic();
  }

  void _onDragEnd(DragEndDetails d) {
    final double vx = d.velocity.pixelsPerSecond.dx;
    int target;
    if (vx.abs() > 350) {
      // Fling: jump one full month in the throw direction
      target = vx < 0
          ? (_offset + 0.5).ceil()
          : (_offset - 0.5).floor();
    } else {
      target = _offset.round();
    }
    target = target.clamp(0, widget.months.length - 1);
    _snapThenDeactivate(target.toDouble());
  }

  void _snapThenDeactivate(double target) {
    if (_snapController.isAnimating) _snapController.stop();

    final double start = _offset;

    void onSnapStatus(AnimationStatus s) {
      if (s == AnimationStatus.completed) {
        _snapController.removeStatusListener(onSnapStatus);
        // Drum morphs back out after snap is done
        _drumController.animateTo(
          0.0,
          duration: _drumOutDuration,
          curve: Curves.easeIn,
        );
      }
    }

    _snapController.addStatusListener(onSnapStatus);

    final Animation<double> anim = Tween<double>(begin: start, end: target)
        .animate(CurvedAnimation(
            parent: _snapController, curve: Curves.easeOutCubic));

    anim.addListener(() {
      setState(() {
        _offset = anim.value.clamp(0.0, widget.months.length - 1.0);
      });
      _maybeHaptic();
    });

    _snapController.forward(from: 0.0);
  }

  void _maybeHaptic() {
    final int page = _offset.round();
    if (page != _lastHapticPage) {
      _lastHapticPage = page;
      HapticFeedback.selectionClick();
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const double headerHeight = 36.0;
    const double spacerHeight = 12.0;
    final double dataHeight =
        widget.sortedYears.length * (widget.rowHeight + 8.0);
    final double totalHeight = headerHeight + spacerHeight + dataHeight;

    return LayoutBuilder(builder: (context, constraints) {
      // Show ~3.2 months at once: container / 3.2
      _itemWidth = constraints.maxWidth / 3.2;

      // Cylinder radius: R = 2 × itemWidth
      // Ensures R × sin(30°) = itemWidth → adjacent drum X == flat X
      final double R = _itemWidth * 2.0;

      // Collect visible items sorted farthest→nearest (so center renders on top)
      final List<MapEntry<int, double>> items = List.generate(
        widget.months.length,
        (i) => MapEntry(i, (i - _offset).abs()),
      )
        ..removeWhere((e) => e.value > _cullDistance + 0.5)
        ..sort((a, b) => b.value.compareTo(a.value));

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: _onDragStart,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: SizedBox(
          height: totalHeight,
          width: double.infinity,
          child: ClipRect(
            child: Stack(
              alignment: Alignment.center,
              children: items
                  .map((e) => _buildItem(context, e.key, R))
                  .toList(),
            ),
          ),
        ),
      );
    });
  }

  // ─── Item rendering ───────────────────────────────────────────────────────

  Widget _buildItem(BuildContext context, int index, double R) {
    final double offset = index - _offset;
    final double angle  = offset * _anglePerStep;  // drum rotation angle

    // ── Flat position (drumFactor=0) ────────────────────────────────────────
    // Items spaced linearly, like a regular horizontal scroll.
    final double flatX = offset * _itemWidth;

    // ── Drum position (drumFactor=1) ─────────────────────────────────────────
    // Items on outside surface of cylinder. R×sin(30°) = itemWidth → seamless lerp.
    final double drumX     = R * sin(angle);
    final double drumZ     = R * cos(angle) - R;    // 0 at front, negative = behind
    final double drumRotY  = -angle;                 // NEGATED → outside-drum face

    // ── Lerp flat → drum based on _drumFactor ────────────────────────────────
    final double tx       = flatX + (drumX - flatX) * _drumFactor;
    final double tz       = drumZ  * _drumFactor;
    final double rotY     = drumRotY * _drumFactor;
    final double persp    = _maxPerspective * _drumFactor;

    // ── Opacity ──────────────────────────────────────────────────────────────
    // Flat: all items fully visible (clipped by ClipRect at edges).
    // Drum: fade based on cos(angle) — items rotating to back become invisible.
    final double drumOpacity = cos(angle).clamp(0.0, 1.0);
    final double opacity = 1.0 - (1.0 - drumOpacity) * _drumFactor;

    final Matrix4 m = Matrix4.identity()
      ..setEntry(3, 2, persp)
      ..translate(tx, 0.0, tz)
      ..rotateY(rotY);

    return Positioned.fill(
      child: Center(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform(
            transform: m,
            alignment: Alignment.center,
            child: SizedBox(
              width: _itemWidth,
              child: _buildMonthColumn(context, index),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Month column content ─────────────────────────────────────────────────

  Widget _buildMonthColumn(BuildContext context, int index) {
    final String shortMonth = widget.shortMonths[index];
    final String fullMonth  = widget.months[index];
    final bool isDark = widget.isDark;

    return Column(
      children: [
        // Month label header
        Container(
          height: 36.0,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E1E32).withOpacity(0.95)
                : Colors.black.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.10)
                    : Colors.black.withOpacity(0.08),
              ),
            ),
          ),
          child: Center(
            child: Text(
              shortMonth,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // One card per year
        ...widget.sortedYears.map((year) {
          final item = widget.groupedData[year]?[fullMonth];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SizedBox(
              height: widget.rowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: item != null
                    ? MonthlyPerformanceCard(data: item, isCompactTable: true)
                    : Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.02)
                              : Colors.black.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
