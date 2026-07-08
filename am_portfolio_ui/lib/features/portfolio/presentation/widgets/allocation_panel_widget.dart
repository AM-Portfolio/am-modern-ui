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
  late final AnimationController _hoverController;
  late final Animation<double> _hoverAnimation;
  
  bool _showAllSectors = false;
  int? _hoveredIndex;
  int? _previousHoveredIndex;

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
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _hoverAnimation = CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
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
      _hoveredIndex = null;
      _previousHoveredIndex = null;
      _hoverController.reset();
    }
  }

  @override
  void dispose() {
    _donutController.dispose();
    _pulseController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(Offset localPosition, List<SectorWeight> weights) {
    final center = const Offset(110, 110);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);

    if (dist < 68 || dist > 115) {
      _onHoverExit();
      return;
    }

    double totalWeight = weights.fold(0.0, (sum, item) => sum + item.weightPercentage);
    if (totalWeight <= 0) totalWeight = 100.0;

    double angle = math.atan2(dy, dx);
    angle = (angle + math.pi / 2 + 2 * math.pi) % (2 * math.pi);

    double cumulative = 0;
    for (int i = 0; i < weights.length; i++) {
      double normalizedWeight = (weights[i].weightPercentage / totalWeight) * 100;
      cumulative += (normalizedWeight / 100) * (2 * math.pi);
      
      if (angle <= cumulative) {
        if (_hoveredIndex != i) {
          setState(() {
            _previousHoveredIndex = _hoveredIndex;
            _hoveredIndex = i;
          });
          _hoverController.forward(from: 0);
        }
        return;
      }
    }
    _onHoverExit();
  }

  void _onHoverExit() {
    if (_hoveredIndex != null) {
      setState(() {
        _previousHoveredIndex = _hoveredIndex;
        _hoveredIndex = null;
      });
      _hoverController.forward(from: 0).then((_) {
        if (mounted && _hoveredIndex == null) {
          setState(() {
            _previousHoveredIndex = null;
          });
        }
      });
    }
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
    final visibleWeights = weights;
    final hasMore = false;

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
              animation: Listenable.merge([_donutAnimation, _pulseAnimation, _hoverAnimation]),
              builder: (context, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    MouseRegion(
                      onHover: (event) => _onHover(event.localPosition, weights),
                      onExit: (_) => _onHoverExit(),
                      child: GestureDetector(
                        onTapDown: (d) => _onHover(d.localPosition, weights),
                        onTapUp: (d) => _onHover(d.localPosition, weights),
                        onPanUpdate: (d) => _onHover(d.localPosition, weights),
                        onPanEnd: (_) => _onHoverExit(),
                        child: SizedBox(
                          width: 220,
                          height: 220,
                          child: CustomPaint(
                            painter: _GlowingDonutPainter(
                              weights,
                              progress: _donutAnimation.value,
                              pulse: _pulseAnimation.value,
                              hoveredIndex: _hoveredIndex,
                              previousHoveredIndex: _previousHoveredIndex,
                              hoverProgress: _hoverAnimation.value,
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _hoverAnimation,
                      builder: (context, _) {
                        double hoverProgress = _hoverAnimation.value;
                        
                        double defaultOpacity;
                        if (_hoveredIndex != null && _previousHoveredIndex == null) {
                          defaultOpacity = 1.0 - hoverProgress;
                        } else if (_hoveredIndex == null && _previousHoveredIndex != null) {
                          defaultOpacity = hoverProgress;
                        } else if (_hoveredIndex == null && _previousHoveredIndex == null) {
                          defaultOpacity = 1.0;
                        } else {
                          defaultOpacity = 0.0;
                        }

                        return Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: defaultOpacity,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Sectors',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                  ),
                                  Text(
                                    'Tap to explore',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: _isDark
                                              ? Colors.white.withValues(alpha: 0.45)
                                              : Colors.black.withValues(alpha: 0.45),
                                          fontSize: 12,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (_hoveredIndex != null)
                              Opacity(
                                opacity: hoverProgress,
                                child: _buildCenterText(_hoveredIndex!, weights),
                              ),
                            if (_previousHoveredIndex != null)
                              Opacity(
                                opacity: 1.0 - hoverProgress,
                                child: _buildCenterText(_previousHoveredIndex!, weights),
                              ),
                          ],
                        );
                      },
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
    final color = _kPalette[index % _kPalette.length];
    return [color, color.withValues(alpha: 0.8)];
  }

  Widget _buildCenterText(int index, List<SectorWeight> weights) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${weights[index].weightPercentage.toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: _kPalette[index % _kPalette.length],
              ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            weights[index].sectorName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.black.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

const List<Color> _kPalette = [
  Color(0xFF00B894),
  Color(0xFFFF7675),
  Color(0xFF60A5FA),
  Color(0xFFFBBF24),
  Color(0xFFF472B6),
  Color(0xFF34D399),
  Color(0xFFA78BFA),
  Color(0xFFFB923C),
];

class _GlowingDonutPainter extends CustomPainter {
  final List<SectorWeight> sectorWeights;
  final double progress;
  final double pulse;
  final int? hoveredIndex;
  final int? previousHoveredIndex;
  final double hoverProgress;

  _GlowingDonutPainter(
    this.sectorWeights, {
    this.progress = 1.0,
    this.pulse = 0.0,
    this.hoveredIndex,
    this.previousHoveredIndex,
    this.hoverProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (sectorWeights.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (size.shortestSide / 2) - 14;

    const gapAngle = 0.045;
    double startAngle = -math.pi / 2;

    double totalWeight = sectorWeights.fold(0.0, (sum, item) => sum + item.weightPercentage);
    if (totalWeight <= 0) totalWeight = 100.0;

    for (int i = 0; i < sectorWeights.length; i++) {
      final weight = sectorWeights[i];
      final color = _kPalette[i % _kPalette.length];
      
      double getTargetColorAlpha(int? activeHover) {
        if (activeHover == null) return 1.0;
        if (i == activeHover) return 1.0;
        return 0.35;
      }
      
      double getTargetGlowAlpha(int? activeHover) {
        if (activeHover == null) return 0.3;
        if (i == activeHover) return 0.65;
        return 0.1;
      }
      
      double getTargetHoverProg(int? activeHover) {
        if (activeHover == null) return 0.0;
        if (i == activeHover) return 1.0;
        return 0.0;
      }

      double startColorAlpha = getTargetColorAlpha(previousHoveredIndex);
      double endColorAlpha = getTargetColorAlpha(hoveredIndex);
      double colorAlpha = startColorAlpha + (endColorAlpha - startColorAlpha) * hoverProgress;

      double startGlowAlpha = getTargetGlowAlpha(previousHoveredIndex);
      double endGlowAlpha = getTargetGlowAlpha(hoveredIndex);
      double glowAlpha = startGlowAlpha + (endGlowAlpha - startGlowAlpha) * hoverProgress;

      double startProg = getTargetHoverProg(previousHoveredIndex);
      double endProg = getTargetHoverProg(hoveredIndex);
      double currentHoverProg = startProg + (endProg - startProg) * hoverProgress;
      
      bool isIdle = hoveredIndex == null && (previousHoveredIndex == null || hoverProgress >= 0.99);
      final double currentPulse = (i == 0 && isIdle && progress > 0.98) ? pulse : 0.0;

      final double outerRadius = baseRadius + (8 * currentHoverProg) + (2 * currentPulse);
      final double strokeWidth = 24.0 + (4 * currentHoverProg) + (1 * currentPulse);
      
      final rect = Rect.fromCircle(center: center, radius: outerRadius);

      double normalizedWeight = (weight.weightPercentage / totalWeight) * 100;
      double fullSweep = (normalizedWeight / 100) * (2 * math.pi);
      if (fullSweep < gapAngle + 0.01) fullSweep = gapAngle + 0.01;

      final animatedSweep = fullSweep * progress;
      final actualSweep = (animatedSweep - gapAngle).clamp(0.0, animatedSweep);

      if (actualSweep > 0) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: glowAlpha * colorAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 6 + (8 * currentHoverProg)
          ..strokeCap = StrokeCap.butt
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + (10 * currentHoverProg));
        canvas.drawArc(rect, startAngle, actualSweep, false, glowPaint);

        final paint = Paint()
          ..color = color.withValues(alpha: colorAlpha)
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
      oldDelegate.pulse != pulse ||
      oldDelegate.hoveredIndex != hoveredIndex ||
      oldDelegate.previousHoveredIndex != previousHoveredIndex ||
      oldDelegate.hoverProgress != hoverProgress;
}
