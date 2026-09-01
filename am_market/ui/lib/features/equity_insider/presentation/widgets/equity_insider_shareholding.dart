import 'dart:math';
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_sdk/market/api.dart';

class EquityInsiderShareholding extends StatefulWidget {
  final FundamentalRatiosResponse data;

  const EquityInsiderShareholding({super.key, required this.data});

  @override
  State<EquityInsiderShareholding> createState() => _EquityInsiderShareholdingState();
}

class _EquityInsiderShareholdingState extends State<EquityInsiderShareholding> {
  int _hoveredIndex = -1;
  int _activeIndex = -1;
  Offset? _tooltipPos;

  List<_SliceData> _getSlices() {
    final raw = widget.data.shareholding;
    if (raw == null || raw.isEmpty) return [];
    
    final latest = raw.first;
    if (latest is! Map) return [];

    double _val(String key) {
      final v = latest[key];
      if (v is num) return v.toDouble();
      if (v is String) {
        final clean = v.replaceAll(RegExp(r'[^\d.-]'), '');
        return double.tryParse(clean) ?? 0.0;
      }
      return 0.0;
    }

    return [
      _SliceData(
        name: 'Promoters',
        pct: _val('promotersPercent'),
        color: const Color(0xFF00C896),
      ),
      _SliceData(
        name: 'FII / Foreign',
        pct: _val('fiiPercent'),
        color: const Color(0xFF38BDF8),
      ),
      _SliceData(
        name: 'Mutual Funds',
        pct: _val('mutualFundsPercent'),
        color: const Color(0xFFA78BFA),
      ),
      _SliceData(
        name: 'Retail / Public',
        pct: _val('retailAndOtherPercent'),
        color: const Color(0xFF64748B),
      ),
      _SliceData(
        name: 'DII / Others',
        pct: _val('diiPercent'),
        color: const Color(0xFF475569),
      ),
    ].where((s) => s.pct > 0).toList();
  }

  void _onHover(int index, Offset? pos) {
    setState(() {
      _hoveredIndex = index;
      _tooltipPos = pos;
    });
  }

  void _onClick(int index) {
    setState(() {
      _activeIndex = _activeIndex == index ? -1 : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final slices = _getSlices();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Shareholding pattern — Latest'),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardColor,
            border: Border.all(color: context.borderColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: slices.isEmpty
              ? Center(
                  child: Text('No shareholding data available',
                      style: TextStyle(color: context.textTertiary, fontSize: 12)))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 500;
                    if (isMobile) {
                      return Column(
                        children: [
                          _buildChart(slices),
                          const SizedBox(height: 24),
                          _buildLegend(slices),
                        ],
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 220, child: _buildChart(slices)),
                        const SizedBox(width: 60),
                        SizedBox(width: 250, child: _buildLegend(slices)),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
              color: context.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: context.borderColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<_SliceData> slices) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 220,
          height: 180,
          child: MouseRegion(
            onHover: (e) {
              final idx = _hitTest(e.localPosition, slices);
              _onHover(idx, e.localPosition);
            },
            onExit: (_) => _onHover(-1, null),
            cursor: _hoveredIndex >= 0 ? SystemMouseCursors.click : SystemMouseCursors.basic,
            child: GestureDetector(
              onTapUp: (d) {
                final idx = _hitTest(d.localPosition, slices);
                if (idx >= 0) _onClick(idx);
              },
              child: CustomPaint(
                painter: _EllipticalPiePainter(
                  slices: slices,
                  hoveredIndex: _hoveredIndex,
                  activeIndex: _activeIndex,
                  bgColor: context.cardColor,
                ),
              ),
            ),
          ),
        ),
        if (_hoveredIndex >= 0 && _tooltipPos != null)
          Positioned(
            left: _tooltipPos!.dx - 50,
            top: _tooltipPos!.dy + 15,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.backgroundColor,
                  border: Border.all(color: context.borderColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${slices[_hoveredIndex].name} · ${slices[_hoveredIndex].pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLegend(List<_SliceData> slices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(slices.length, (i) {
        final s = slices[i];
        final isHovered = _hoveredIndex == i;
        final isActive = _activeIndex == i;

        return MouseRegion(
          onEnter: (_) => _onHover(i, null),
          onExit: (_) => _onHover(-1, null),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _onClick(i),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: (isHovered || isActive)
                    ? context.borderColor.withOpacity(0.5)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: s.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.name,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '${s.pct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  int _hitTest(Offset pos, List<_SliceData> slices) {
    final cx = 110.0;
    final cy = 90.0;
    final rx = 90.0;
    final ry = 40.0;

    final dx = pos.dx - cx;
    final dy = pos.dy - cy;

    if (pow(dx / rx, 2) + pow(dy / ry, 2) > 1) return -1;

    double a = atan2(dy, dx);
    if (a < -pi / 2) a += pi * 2;

    double c = -pi / 2;
    double totalPct = slices.fold(0, (sum, s) => sum + s.pct);
    if (totalPct == 0) return -1;

    for (int i = 0; i < slices.length; i++) {
      double span = (slices[i].pct / totalPct) * pi * 2;
      if (a >= c && a < c + span) return i;
      c += span;
    }
    return -1;
  }
}

class _SliceData {
  final String name;
  final double pct;
  final Color color;
  _SliceData({required this.name, required this.pct, required this.color});
}

class _EllipticalPiePainter extends CustomPainter {
  final List<_SliceData> slices;
  final int hoveredIndex;
  final int activeIndex;
  final Color bgColor;

  _EllipticalPiePainter({
    required this.slices,
    required this.hoveredIndex,
    required this.activeIndex,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 5; // shift up slightly for depth
    final rx = 90.0;
    final ry = 40.0;
    final depth = 15.0;

    double totalPct = slices.fold(0, (sum, s) => sum + s.pct);
    if (totalPct == 0) return;

    List<_AngleData> angles = [];
    double s = -pi / 2;
    for (int i = 0; i < slices.length; i++) {
      double e = s + (slices[i].pct / totalPct) * pi * 2;
      angles.add(_AngleData(s, e));
      s = e;
    }

    // Draw slices back-to-front
    List<int> order = List.generate(slices.length, (i) => i);
    order.sort((a, b) {
      double midA = (angles[a].s + angles[a].e) / 2;
      double midB = (angles[b].s + angles[b].e) / 2;
      return sin(midA).compareTo(sin(midB));
    });

    for (int i in order) {
      if (i != hoveredIndex && i != activeIndex) {
        _drawSlice(canvas, cx, cy, rx, ry, depth, angles[i], slices[i], false);
      }
    }

    if (hoveredIndex >= 0 && hoveredIndex != activeIndex) {
      _drawSlice(canvas, cx, cy, rx, ry, depth, angles[hoveredIndex], slices[hoveredIndex], true);
    }
    if (activeIndex >= 0) {
      _drawSlice(canvas, cx, cy, rx, ry, depth, angles[activeIndex], slices[activeIndex], true);
    }
  }

  void _drawSlice(Canvas canvas, double cx, double cy, double rx, double ry, double depth, _AngleData ang, _SliceData slice, bool lift) {
    final mid = (ang.s + ang.e) / 2;
    final lx = lift ? cos(mid) * 8 : 0.0;
    final ly = lift ? sin(mid) * 5 : 0.0;

    final basePaint = Paint()
      ..color = slice.color.withOpacity(0.8)
      ..style = PaintingStyle.fill;
      
    final topPaint = Paint()
      ..color = slice.color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw depth (cylinder wall)
    if (sin(mid) > -0.15) {
      final path = Path();
      // Wait, standard canvas ellipse might not be perfect for partial arc + lines. 
      // Manually approximating or just drawing bottom arc and connecting lines.
      path.addArc(Rect.fromCenter(center: Offset(cx + lx, cy + depth + ly), width: rx * 2, height: ry * 2), ang.s, ang.e - ang.s);
      path.lineTo(cx + cos(ang.e) * rx + lx, cy + sin(ang.e) * ry + ly);
      path.arcTo(Rect.fromCenter(center: Offset(cx + lx, cy + ly), width: rx * 2, height: ry * 2), ang.e, ang.s - ang.e, false);
      path.lineTo(cx + cos(ang.s) * rx + lx, cy + sin(ang.s) * ry + depth + ly);
      path.close();
      canvas.drawPath(path, basePaint);
    }

    // Draw top face
    final topPath = Path();
    topPath.moveTo(cx + lx, cy + ly);
    topPath.arcTo(Rect.fromCenter(center: Offset(cx + lx, cy + ly), width: rx * 2, height: ry * 2), ang.s, ang.e - ang.s, false);
    topPath.close();
    
    canvas.drawPath(topPath, topPaint);
    canvas.drawPath(topPath, borderPaint);

    if (lift) {
      final textSpan = TextSpan(
        text: '${slice.pct.toStringAsFixed(1)}%',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();
      
      final tx = cx + cos(mid) * rx * 0.6 + lx - tp.width / 2;
      final ty = cy + sin(mid) * ry * 0.6 + ly - tp.height / 2;
      tp.paint(canvas, Offset(tx, ty));
    }
  }

  @override
  bool shouldRepaint(covariant _EllipticalPiePainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex ||
           oldDelegate.activeIndex != activeIndex ||
           oldDelegate.bgColor != bgColor;
  }
}

class _AngleData {
  final double s;
  final double e;
  _AngleData(this.s, this.e);
}
