import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/models/indices_performance_model.dart';
import 'package:am_market_ui/features/market_analysis/presentation/widgets/monthly_performance_card.dart';

/// A premium half-cylinder drum-roll horizontal month scroller for mobile.
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

class _CylinderMonthScrollerState extends State<CylinderMonthScroller> {
  late final PageController _pageController;
  double _currentPage = 0.0;
  int _lastSnappedPage = 0;

  static const double _viewportFraction = 0.45;
  static const double _anglePerStep = pi / 4.5;
  static const double _perspective = 0.0014;
  static const double _minScale = 0.62;
  static const double _minOpacity = 0.30;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: _viewportFraction,
      initialPage: 0,
    );
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    final page = _pageController.page ?? 0.0;
    setState(() => _currentPage = page);
    final snapped = page.round();
    if (snapped != _lastSnappedPage) {
      _lastSnappedPage = snapped;
      HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double headerHeight = 36.0;
    const double spacerHeight = 12.0;
    final double dataHeight =
        widget.sortedYears.length * (widget.rowHeight + 8.0);
    final double totalHeight = headerHeight + spacerHeight + dataHeight;

    return SizedBox(
      height: totalHeight,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.months.length,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemBuilder: (context, index) => _buildCylinderPage(context, index),
      ),
    );
  }

  Widget _buildCylinderPage(BuildContext context, int index) {
    final double offset = index - _currentPage;
    final double angle = offset * _anglePerStep;
    final double cosAngle = cos(angle);
    final double scale = cosAngle.clamp(_minScale, 1.0);
    final double opacity = cosAngle.clamp(_minOpacity, 1.0);

    final Matrix4 transform = Matrix4.identity()
      ..setEntry(3, 2, _perspective)
      ..rotateY(angle)
      ..scale(scale, scale, 1.0);

    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: Opacity(
        opacity: opacity,
        child: _buildMonthColumn(context, index),
      ),
    );
  }

  Widget _buildMonthColumn(BuildContext context, int index) {
    final String shortMonth = widget.shortMonths[index];
    final String fullMonth = widget.months[index];
    final isDark = widget.isDark;

    return Column(
      children: [
        Container(
          height: 36.0,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E1E32).withOpacity(0.8)
                : Colors.black.withOpacity(0.04),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08),
                width: 1.0,
              ),
            ),
          ),
          child: Center(
            child: Text(
              shortMonth,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...widget.sortedYears.map((year) {
          final item = widget.groupedData[year]?[fullMonth];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SizedBox(
              height: widget.rowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: item != null
                    ? MonthlyPerformanceCard(data: item, isCompactTable: true)
                    : Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.02)
                              : Colors.black.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(8),
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
