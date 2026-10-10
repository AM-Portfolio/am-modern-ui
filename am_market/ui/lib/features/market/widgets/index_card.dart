import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/models/market_data.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';

class IndexCard extends StatelessWidget {
  final StockIndicesMarketData data;
  final bool isSelected;
  final VoidCallback onTap;

  const IndexCard({
    required this.data,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final numberFormat = NumberFormat('#,##,###.##', 'en_IN');
    final accent = ModuleColors.market;

    return Consumer<MarketProvider>(
      builder: (context, provider, child) {
        bool isLoading = false;
        // Keep last known 1D change while non-1D base prices load — never force zeros.
        double displayChange = data.change;
        double displayPChange = data.pChange;
        String timeframeLabel = '';

        if (provider.selectedIndicesTimeframe != '1D') {
          timeframeLabel = ' (${provider.selectedIndicesTimeframe})';
          if (provider.isLoadingBasePrices) {
            isLoading = true;
          }
        }

        final isPositive = displayChange >= 0;
        final changeColor = isLoading
            ? MarketColors.textMuted(context)
            : (isPositive
                ? MarketColors.positive(context)
                : MarketColors.negative(context));

        final displayPChangeFormatted = displayPChange.abs().toStringAsFixed(2);
        final displayChangeFormatted = numberFormat.format(displayChange.abs());
        final sparkline =
            provider.indexSparklines[data.indexSymbol] ?? const <double>[];

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 10,
                vertical: isMobile ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: MarketColors.cardSurface(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      isSelected ? accent : MarketColors.borderDefault(context),
                  width: isSelected ? 1.5 : MarketColors.borderWidth(context),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.22),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.indexSymbol.toUpperCase(),
                          style: TextStyle(
                            fontSize: isMobile ? 9.5 : 10.5,
                            color: MarketColors.textMuted(context),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            height: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isLoading
                              ? '...'
                              : numberFormat.format(data.lastPrice),
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            color: MarketColors.textPrimary(context),
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                            height: 1.1,
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLoading
                              ? 'Loading...'
                              : '${isPositive ? '+' : '-'}$displayChangeFormatted (${isPositive ? '+' : '-'}$displayPChangeFormatted%$timeframeLabel)',
                          style: TextStyle(
                            fontSize: isMobile ? 9.5 : 10.5,
                            color: changeColor,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: isMobile ? 42 : 54,
                    height: isMobile ? 26 : 32,
                    child: sparkline.length >= 2
                        ? CustomPaint(
                            painter: _IndexSparklinePainter(
                              data: sparkline,
                              color: changeColor,
                            ),
                          )
                        : (provider.isLoadingSparklines
                            ? Center(
                                child: SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: changeColor.withValues(alpha: 0.5),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink()),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IndexSparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _IndexSparklinePainter({
    required this.data,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    var maxVal = data.reduce(math.max);
    var minVal = data.reduce(math.min);
    if (maxVal == minVal) {
      maxVal += 1;
      minVal -= 1;
    }

    final stepX = size.width / (data.length - 1);
    final rangeY = maxVal - minVal;

    double getY(double val) =>
        size.height * 0.12 +
        (size.height * 0.76) * (1 - ((val - minVal) / rangeY));

    final path = Path()..moveTo(0, getY(data[0]));
    for (var i = 0; i < data.length - 1; i++) {
      final x1 = i * stepX;
      final y1 = getY(data[i]);
      final x2 = (i + 1) * stepX;
      final y2 = getY(data[i + 1]);
      final cpX = x1 + (x2 - x1) / 2;
      path.cubicTo(cpX, y1, cpX, y2, x2, y2);
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _IndexSparklinePainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}
