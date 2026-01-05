import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/portfolio_overview_data.dart';
import '../base/chart_colors.dart';

/// Animated donut chart for market cap allocation
class AnimatedMarketCapChart extends StatefulWidget {
  const AnimatedMarketCapChart({
    required this.allocations,
    super.key,
    this.onSectionTapped,
    this.showAnimation = true,
  });

  final List<AllocationItem> allocations;
  final ValueChanged<String>? onSectionTapped;
  final bool showAnimation;

  @override
  State<AnimatedMarketCapChart> createState() => _AnimatedMarketCapChartState();
}

class _AnimatedMarketCapChartState extends State<AnimatedMarketCapChart>
    with SingleTickerProviderStateMixin {
  int _touchedIndex = -1;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    if (widget.showAnimation) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.allocations.isEmpty) {
      return const Center(child: Text('No market cap data available'));
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: PieChart(
                    PieChartData(
                      sections: _buildAnimatedSections(),
                      centerSpaceRadius: 80,
                      sectionsSpace: 2,
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex =
                                pieTouchResponse.touchedSection!.touchedSectionIndex;

                            if (event is FlTapUpEvent && _touchedIndex >= 0) {
                              widget.onSectionTapped
                                  ?.call(widget.allocations[_touchedIndex].label);
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildLegend(context),
            ),
          ],
        );
      },
    );
  }

  List<PieChartSectionData> _buildAnimatedSections() {
    return widget.allocations.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isTouched = index == _touchedIndex;
      final color = _getMarketCapColor(item.label);
      
      // Animate from 0 to actual value
      final animatedValue = item.value * _animation.value;
      
      // Highlight touched section
      final radius = isTouched ? 70.0 : 60.0;
      final fontSize = isTouched ? 16.0 : 14.0;

      return PieChartSectionData(
        value: animatedValue,
        title: isTouched ? '${item.percentage.toStringAsFixed(1)}%' : '',
        color: color,
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 2,
            ),
          ],
        ),
      );
    }).toList();
  }

  Color _getMarketCapColor(String segmentName) {
    final colors = {
      'Mega Cap': const Color(0xFF0D47A1),
      'Large Cap': const Color(0xFF2196F3),
      'Mid Cap': const Color(0xFF4CAF50),
      'Small Cap': const Color(0xFFFF9800),
      'Micro Cap': const Color(0xFF9C27B0),
    };
    return colors[segmentName] ?? ChartColors.getColorForIndex(0);
  }

  Widget _buildLegend(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Market Cap',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: widget.allocations.length,
              itemBuilder: (context, index) {
                final item = widget.allocations[index];
                final color = _getMarketCapColor(item.label);
                final isTouched = index == _touchedIndex;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _touchedIndex = index;
                    });
                    widget.onSectionTapped?.call(item.label);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isTouched ? color.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isTouched ? color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isTouched ? 20 : 16,
                          height: isTouched ? 20 : 16,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: isTouched
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.4),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: isTouched ? 13 : 12,
                                  fontWeight: isTouched ? FontWeight.bold : FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '\$${item.value.toStringAsFixed(0)} • ${item.count} stocks',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${item.percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: isTouched ? 13 : 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
