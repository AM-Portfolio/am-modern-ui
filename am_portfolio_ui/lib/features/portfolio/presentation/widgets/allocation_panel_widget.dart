import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../internal/domain/entities/portfolio_analytics.dart';

class AllocationPanelWidget extends StatefulWidget {
  const AllocationPanelWidget({
    super.key,
    this.sectorAllocation,
    this.isLoading = false,
    this.error,
  });
  final SectorAllocation? sectorAllocation;
  final bool isLoading;
  final String? error;

  @override
  State<AllocationPanelWidget> createState() => _AllocationPanelWidgetState();
}

class _AllocationPanelWidgetState extends State<AllocationPanelWidget>
    with TickerProviderStateMixin {
  late final AnimationController _donutController;
  late final Animation<double> _donutAnimation;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _showAllSectors = false;

  @override
  void initState() {
    super.initState();
    _donutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _donutAnimation = CurvedAnimation(
      parent: _donutController,
      curve: Curves.easeOutCubic,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.sectorAllocation != null) {
      _donutController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AllocationPanelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sectorAllocation != null &&
        oldWidget.sectorAllocation != widget.sectorAllocation) {
      _donutController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _donutController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isDark
                ? [
                    const Color(0xFF0D1B2A).withValues(alpha: 0.9),
                    const Color(0xFF0A1628).withValues(alpha: 0.75),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.9),
                    const Color(0xFFF5F7FF).withValues(alpha: 0.8),
                  ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: _isDark ? 0.07 : 0.4),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            // ── Header ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .primaryColor
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.donut_small_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Allocation',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (widget.error != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  color: Theme.of(context).colorScheme.error, size: 48),
              const SizedBox(height: 8),
              Text('Failed to load allocation data',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14)),
              const SizedBox(height: 4),
              Text(widget.error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (widget.sectorAllocation == null ||
        widget.sectorAllocation!.sectorWeights.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.data_usage_outlined, size: 48),
              SizedBox(height: 8),
              Text('No allocation data available',
                  style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      );
    }

    final weights = widget.sectorAllocation!.sectorWeights;
    final visibleWeights = _showAllSectors ? weights : weights.take(5).toList();
    final hasMore = weights.length > 5;

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── SECTION 1: Sector Distribution – Donut View (TOP) ──
        Center(
          child: SizedBox(
            width: 220,
            height: 220,
            child: AnimatedBuilder(
              animation: Listenable.merge([_donutAnimation, _pulseAnimation]),
              builder: (context, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CustomPaint(
                        painter: _GlowingDonutPainter(
                          weights,
                          progress: _donutAnimation.value,
                          pulse: _donutAnimation.value == 1.0 ? _pulseAnimation.value : 1.0,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '100%',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                        ),
                        Text(
                          'Allocated',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _isDark
                                    ? Colors.white.withValues(alpha: 0.45)
                                    : Colors.black.withValues(alpha: 0.45),
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── SECTION 2: Sector Distribution label ──
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Sector Distribution',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _isDark
                      ? Colors.white.withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
          ),
        ),
        const SizedBox(height: 10),

        // ── SECTION 3: Sector bars – scrollable so content never overflows ──
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Column(
                    children: List.generate(visibleWeights.length, (index) {
                      final weight = visibleWeights[index];
                      final colors = _getGradientColors(index);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: colors.first,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          weight.sectorName,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${weight.weightPercentage.toStringAsFixed(1)}%',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: colors.first,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TweenAnimationBuilder<double>(
                              key: ValueKey(weight.sectorName),
                              tween: Tween<double>(begin: 0, end: weight.weightPercentage / 100),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeOutQuart,
                              builder: (context, value, _) {
                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Stack(
                                      children: [
                                        Container(
                                          height: 6,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: _isDark
                                                ? Colors.white.withValues(alpha: 0.08)
                                                : Colors.black.withValues(alpha: 0.07),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                        ),
                                        Container(
                                          height: 6,
                                          width: constraints.maxWidth * value,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(3),
                                            gradient: LinearGradient(
                                              colors: colors,
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: colors.first.withValues(alpha: 0.45),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                if (hasMore) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _showAllSectors = !_showAllSectors;
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _showAllSectors ? 'Show Less' : 'Show ${weights.length - 5} More',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(width: 6),
                          AnimatedRotation(
                            turns: _showAllSectors ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Color> _getGradientColors(int index) {
    const palette = [
      [Color(0xFF00B894), Color(0xFF4ADE80)],
      [Color(0xFFFF7675), Color(0xFFFCA5A5)],
      [Color(0xFF60A5FA), Color(0xFF6C5DD3)],
      [Color(0xFFFBBF24), Color(0xFFFFD700)],
      [Color(0xFFF472B6), Color(0xFFEC4899)],
      [Color(0xFF34D399), Color(0xFF10B981)],
    ];
    final idx = index % palette.length;
    return palette[idx];
  }
}

class _GlowingDonutPainter extends CustomPainter {
  final List<SectorWeight> sectorWeights;
  final double progress;
  final double pulse;

  _GlowingDonutPainter(this.sectorWeights, {this.progress = 1.0, this.pulse = 1.0});

  static const _palette = [
    Color(0xFF00B894),
    Color(0xFFFF7675),
    Color(0xFF60A5FA),
    Color(0xFFFBBF24),
    Color(0xFFF472B6),
    Color(0xFF34D399),
    Color(0xFFA78BFA),
    Color(0xFFFB923C),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (sectorWeights.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = (size.shortestSide / 2) - 8;
    final rect = Rect.fromCircle(center: center, radius: outerRadius);

    const strokeWidth = 24.0;
    const gapAngle = 0.045;
    double startAngle = -math.pi / 2;

    for (int i = 0; i < sectorWeights.length; i++) {
      final weight = sectorWeights[i];
      final color = _palette[i % _palette.length];

      double fullSweep =
          (weight.weightPercentage / 100) * (2 * math.pi);
      if (fullSweep < gapAngle + 0.01) fullSweep = gapAngle + 0.01;

      final animatedSweep = fullSweep * progress;
      final actualSweep =
          (animatedSweep - gapAngle).clamp(0.0, animatedSweep);

      if (actualSweep > 0) {
        // Glow pass
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (strokeWidth + 6) * pulse
          ..strokeCap = StrokeCap.butt
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawArc(rect, startAngle, actualSweep, false, glowPaint);

        // Main arc
        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt;
        canvas.drawArc(rect, startAngle, actualSweep, false, paint);
      }

      startAngle += fullSweep * progress;
    }
  }

  @override
  bool shouldRepaint(covariant _GlowingDonutPainter oldDelegate) =>
      oldDelegate.sectorWeights != sectorWeights ||
      oldDelegate.progress != progress ||
      oldDelegate.pulse != pulse;
}
