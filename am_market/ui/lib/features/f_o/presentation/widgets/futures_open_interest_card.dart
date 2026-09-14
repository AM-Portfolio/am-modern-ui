import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FuturesOpenInterestCard extends ConsumerStatefulWidget {
  const FuturesOpenInterestCard({super.key});

  @override
  ConsumerState<FuturesOpenInterestCard> createState() => _FuturesOpenInterestCardState();
}

class _FuturesOpenInterestCardState extends ConsumerState<FuturesOpenInterestCard> {
  String _selectedMode = 'OI';
  int? _hoverIndex;

  final List<Map<String, dynamic>> _dataPoints = [
    {'date': '1 Sep', 'oi': '50.10L', 'vol': '16.50L', 'close': '₹2,208.00', 'change': '+1.10%'},
    {'date': '4 Sep', 'oi': '50.45L', 'vol': '17.10L', 'close': '₹2,205.00', 'change': '-0.14%'},
    {'date': '8 Sep', 'oi': '51.20L', 'vol': '17.80L', 'close': '₹2,225.00', 'change': '+0.91%'},
    {'date': '11 Sep', 'oi': '51.80L', 'vol': '18.20L', 'close': '₹2,235.00', 'change': '+0.45%'},
    {'date': '15 Sep', 'oi': '51.95L', 'vol': '18.05L', 'close': '₹2,215.00', 'change': '-0.90%'},
    {'date': '18 Sep', 'oi': '52.10L', 'vol': '18.30L', 'close': '₹2,196.00', 'change': '-0.86%'},
    {'date': '22 Sep', 'oi': '52.25L', 'vol': '18.50L', 'close': '₹2,212.00', 'change': '+0.73%'},
    {'date': '25 Sep', 'oi': '52.40L', 'vol': '18.65L', 'close': '₹2,218.00', 'change': '+0.27%'},
    {'date': '26 Sep', 'oi': '52.49L', 'vol': '18.72L', 'close': '₹2,203.50', 'change': '-0.10%'},
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final marketTheme = context.marketTheme;

    final isOi = _selectedMode == 'OI';
    final cardTitle = isOi ? 'Open Interest' : 'Volume';

    final mainValueStr = isOi ? '52,48,750' : '18,72,300';
    final pChangeStr = isOi ? '+2.34%' : '+1.15%';
    final subText = isOi ? 'vs. previous 51,31,200' : 'vs. previous 18,51,000';
    final currStr = isOi ? '52.49L' : '18.72L';
    final prevStr = isOi ? '51.31L' : '18.51L';
    final changeValStr = isOi ? '+1.17L' : '+0.21L';

    final infoMessage = isOi
        ? 'Open Interest (OI) represents total active unsettled derivative contracts. Rising OI with price indicates bullish build-up.'
        : 'Trading Volume represents total contracts traded during the session. High volume confirms strong market participation.';

    final hoveredItem = _hoverIndex != null && _hoverIndex! < _dataPoints.length
        ? _dataPoints[_hoverIndex!]
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.5),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic Header Title & Info Tooltip
          Row(
            children: [
              Text(
                cardTitle,
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: infoMessage,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ModuleColors.market.withValues(alpha: 0.6)),
                ),
                textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                child: Icon(Icons.info_outline_rounded, color: colors.textSecondary, size: 16),
              ),
              const Spacer(),
              _buildModeToggle('OI', isOi, colors),
              const SizedBox(width: 4),
              _buildModeToggle('Volume', !isOi, colors),
            ],
          ),
          const SizedBox(height: 12),

          // Main Readout
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(mainValueStr, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 22)),
              const SizedBox(width: 8),
              Text(pChangeStr, style: TextStyle(color: marketTheme.positive, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 2),
          Text(subText, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 10),

          // Hover Tooltip Header Badge
          if (hoveredItem != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: ModuleColors.market.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: ModuleColors.market.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${hoveredItem['date']} · ${isOi ? 'OI: ${hoveredItem['oi']}' : 'Vol: ${hoveredItem['vol']}'} · Close: ${hoveredItem['close']}',
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11),
              ),
            ),

          // Interactive Graph Canvas
          LayoutBuilder(
            builder: (context, constraints) {
              return MouseRegion(
                onHover: (event) {
                  final width = constraints.maxWidth - 30;
                  if (width > 0) {
                    final idx = ((event.localPosition.dx - 30) / width * _dataPoints.length).floor().clamp(0, _dataPoints.length - 1);
                    if (_hoverIndex != idx) setState(() => _hoverIndex = idx);
                  }
                },
                onExit: (_) => setState(() => _hoverIndex = null),
                child: Container(
                  height: 140,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomPaint(
                    size: const Size(double.infinity, 140),
                    painter: _OiDualAxisPainter(
                      marketTheme: marketTheme,
                      colors: colors,
                      isOi: isOi,
                      hoverIndex: _hoverIndex,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(isOi ? 'Open Interest' : 'Volume', marketTheme.positive),
              const SizedBox(width: 16),
              _buildLegendItem('Close Price', Colors.purpleAccent),
            ],
          ),
          const SizedBox(height: 14),

          // Metrics Summary Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric(isOi ? 'Current OI' : 'Current Vol', currStr, colors),
              _buildMetric(isOi ? 'Previous OI' : 'Prev Vol', prevStr, colors),
              _buildMetric('Change', changeValStr, colors, color: marketTheme.positive),
              _buildMetric('Change %', pChangeStr, colors, color: marketTheme.positive),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(String label, bool isSelected, AppColorsTheme colors) {
    return InkWell(
      onTap: () => setState(() {
        _selectedMode = label;
        _hoverIndex = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? ModuleColors.market : colors.surface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  Widget _buildMetric(String label, String val, AppColorsTheme colors, {Color? color}) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(color: color ?? colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}

class _OiDualAxisPainter extends CustomPainter {
  _OiDualAxisPainter({
    required this.marketTheme,
    required this.colors,
    required this.isOi,
    this.hoverIndex,
  });

  final MarketThemeExtension marketTheme;
  final AppColorsTheme colors;
  final bool isOi;
  final int? hoverIndex;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 30.0;
    const bottomPadding = 20.0;
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    final textStyle = TextStyle(color: colors.textSecondary, fontSize: 9);

    final yLevels = isOi ? ['60M', '40M', '20M', '0'] : ['2.4M', '1.8M', '1.2M', '0'];
    final gridPaint = Paint()
      ..color = colors.border.withValues(alpha: 0.2)
      ..strokeWidth = 0.8;

    for (int i = 0; i < yLevels.length; i++) {
      final y = (i / (yLevels.length - 1)) * (chartHeight - 16) + 8;
      canvas.drawLine(Offset(leftPadding, y), Offset(size.width, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: yLevels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - tp.height / 2));
    }

    final dates = ['1 Sep', '8 Sep', '15 Sep', '22 Sep', '26 Sep'];
    for (int i = 0; i < dates.length; i++) {
      final x = leftPadding + (i / (dates.length - 1)) * (chartWidth - 20);
      final tp = TextPainter(
        text: TextSpan(text: dates[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chartHeight + 4));
    }

    final oiHeights = isOi
        ? [35.0, 45.0, 60.0, 55.0, 70.0, 85.0, 75.0, 80.0, 90.0]
        : [25.0, 35.0, 50.0, 45.0, 55.0, 65.0, 60.0, 70.0, 75.0];

    final numBars = oiHeights.length;
    final barWidth = (chartWidth - 20) / numBars - 6;

    for (int i = 0; i < numBars; i++) {
      final x = leftPadding + 10 + i * (barWidth + 6);
      final h = oiHeights[i];
      final isHovered = hoverIndex == i;

      final barPaint = Paint()
        ..color = isHovered
            ? ModuleColors.market
            : marketTheme.positive.withValues(alpha: 0.7);

      canvas.drawRect(Rect.fromLTRB(x, chartHeight - h, x + barWidth, chartHeight), barPaint);

      if (isHovered) {
        canvas.drawLine(
          Offset(x + barWidth / 2, 0),
          Offset(x + barWidth / 2, chartHeight),
          Paint()..color = Colors.white.withValues(alpha: 0.4)..strokeWidth = 1,
        );
      }
    }

    final linePaint = Paint()
      ..color = Colors.purpleAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(leftPadding + 10, chartHeight - 30);
    path.quadraticBezierTo(size.width * 0.4, chartHeight - 55, size.width * 0.7, chartHeight - 45);
    path.quadraticBezierTo(size.width * 0.85, chartHeight - 80, size.width - 15, chartHeight - 95);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _OiDualAxisPainter oldDelegate) =>
      oldDelegate.isOi != isOi || oldDelegate.hoverIndex != hoverIndex;
}
