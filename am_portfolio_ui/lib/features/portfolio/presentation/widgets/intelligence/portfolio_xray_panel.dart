import 'dart:math' as math;

import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../internal/domain/entities/portfolio_analytics.dart';
import '../../../internal/domain/entities/portfolio_holding.dart';
import '../../../internal/domain/entities/portfolio_intelligence.dart';
import '../../../providers/portfolio_intelligence_providers.dart';
import '../../cubit/portfolio_analytics_cubit.dart';
import '../../cubit/portfolio_analytics_state.dart';
import '../../cubit/portfolio_cubit.dart';
import '../../cubit/portfolio_state.dart';
import 'intelligence_donut.dart';
import 'intelligence_glass_card.dart';

class PortfolioXrayPanel extends ConsumerStatefulWidget {
  const PortfolioXrayPanel({
    required this.portfolioId,
    this.height,
    this.minHeight,
    this.fillHeight = false,
    super.key,
  });

  final String portfolioId;
  final double? height;
  final double? minHeight;
  final bool fillHeight;

  @override
  ConsumerState<PortfolioXrayPanel> createState() => _PortfolioXrayPanelState();
}

class _PortfolioXrayPanelState extends ConsumerState<PortfolioXrayPanel>
    with TickerProviderStateMixin {
  int _tab = 0;
  String? _expandedId;
  int? _hoveredIndex;
  int? _previousHoveredIndex;

  late final AnimationController _hoverController;
  late final Animation<double> _hoverAnimation;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  static const _donutSize = 168.0;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _hoverAnimation = CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  void _ensurePulse() {
    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _stopPulse() {
    if (_pulseController.isAnimating) {
      _pulseController
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String get _centerIdleLabel {
    switch (_tab) {
      case 1:
        return 'Industry';
      case 2:
        return 'Cap';
      default:
        return 'True Exposure';
    }
  }

  List<XrayWeight> _weightsForTab(PortfolioXray? xray) {
    if (xray == null) return const [];
    final raw = switch (_tab) {
      1 => xray.industryWeights,
      2 => xray.marketCapWeights,
      _ => xray.sectorWeights,
    };
    final sorted = [...raw]
      ..sort((a, b) {
        final aUnk = a.name.toLowerCase() == 'unknown';
        final bUnk = b.name.toLowerCase() == 'unknown';
        if (aUnk != bUnk) return aUnk ? 1 : -1;
        return b.weightPct.compareTo(a.weightPct);
      });
    return sorted;
  }

  void _onHover(Offset local, List<XrayWeight> weights) {
    final center = Offset(_donutSize / 2, _donutSize / 2);
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 48 || dist > 88) {
      _onHoverExit();
      return;
    }
    var total = weights.fold<double>(0, (s, w) => s + w.weightPct);
    if (total <= 0) total = 100;
    var angle = math.atan2(dy, dx);
    angle = (angle + math.pi / 2 + 2 * math.pi) % (2 * math.pi);
    var cumulative = 0.0;
    for (var i = 0; i < weights.length; i++) {
      cumulative += (weights[i].weightPct / total) * (2 * math.pi);
      if (angle <= cumulative) {
        if (_hoveredIndex != i) {
          setState(() {
            _previousHoveredIndex = _hoveredIndex;
            _hoveredIndex = i;
          });
          _ensurePulse();
          _hoverController.forward(from: 0);
        }
        return;
      }
    }
    _onHoverExit();
  }

  void _onHoverExit() {
    if (_hoveredIndex == null) return;
    setState(() {
      _previousHoveredIndex = _hoveredIndex;
      _hoveredIndex = null;
    });
    _stopPulse();
    _hoverController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(portfolioIntelligenceProvider(widget.portfolioId));

    List<PortfolioHolding>? holdings;
    MarketCapAllocation? mcap;
    try {
      final portfolioState = context.watch<PortfolioCubit>().state;
      if (portfolioState is PortfolioLoaded) {
        holdings = portfolioState.holdings;
      }
    } catch (_) {
      // Tests / hosts without PortfolioCubit.
    }
    try {
      final analyticsState = context.watch<PortfolioAnalyticsCubit>().state;
      if (analyticsState is PortfolioAnalyticsLoaded) {
        mcap = analyticsState.marketCapAllocation;
      }
    } catch (_) {
      // Tests / hosts without analytics cubit.
    }

    return async.when(
      loading: () => IntelligenceCardSkeleton(
        height: widget.minHeight ??
            widget.height ??
            (widget.fillHeight ? 320 : 260),
      ),
      error: (e, _) => IntelligenceGlassCard(
        title: 'Portfolio X-Ray',
        icon: Icons.donut_large_rounded,
        minHeight: widget.minHeight,
        fillHeight: widget.fillHeight,
        child: IntelligenceRetryRow(
          message: 'Could not load X-Ray',
          onRetry: () => ref
              .invalidate(portfolioIntelligenceProvider(widget.portfolioId)),
        ),
      ),
      data: (intel) {
        final weights = _weightsForTab(intel?.xray);
        final totalValue = holdings == null || holdings.isEmpty
            ? null
            : holdings.fold<double>(0, (s, h) => s + h.currentValue);
        final useFill = widget.fillHeight;
        final body = _XrayBody(
          weights: weights,
          tab: _tab,
          expandedId: _expandedId,
          hoveredIndex: _hoveredIndex,
          previousHoveredIndex: _previousHoveredIndex,
          hoverAnimation: _hoverAnimation,
          pulseAnimation: _pulseAnimation,
          centerIdleLabel: _centerIdleLabel,
          totalValue: totalValue,
          holdings: holdings,
          marketCapAllocation: mcap,
          donutSize: _donutSize,
          fillHeight: useFill,
          sideBySide: MediaQuery.sizeOf(context).width >= 600,
          onTab: (t) => setState(() {
            _tab = t;
            _expandedId = null;
            _hoveredIndex = null;
            _previousHoveredIndex = null;
            _stopPulse();
          }),
          onHover: (o) => _onHover(o, weights),
          onHoverExit: _onHoverExit,
          onExpand: (name) => setState(() {
            _expandedId = _expandedId == name ? null : name;
          }),
        );

        final card = IntelligenceGlassCard(
          title: 'Portfolio X-Ray',
          icon: Icons.donut_large_rounded,
          minHeight: widget.minHeight,
          fillHeight: useFill,
          scrollable: false,
          footer: IntelligenceTextLink(
            label: 'Explore Full X-Ray →',
            onPressed: () => showIntelligenceSheet(
              context: context,
              title: 'Full X-Ray',
              subtitle: 'Sector · Industry · Cap exposure',
              body: SizedBox(
                height: 420,
                child: _XrayBody(
                  weights: weights,
                  tab: _tab,
                  expandedId: _expandedId,
                  hoveredIndex: _hoveredIndex,
                  previousHoveredIndex: _previousHoveredIndex,
                  hoverAnimation: _hoverAnimation,
                  pulseAnimation: _pulseAnimation,
                  centerIdleLabel: _centerIdleLabel,
                  totalValue: totalValue,
                  holdings: holdings,
                  marketCapAllocation: mcap,
                  donutSize: _donutSize,
                  fillHeight: true,
                  sideBySide: true,
                  onTab: (t) => setState(() {
                    _tab = t;
                    _expandedId = null;
                  }),
                  onHover: (o) => _onHover(o, weights),
                  onHoverExit: _onHoverExit,
                  onExpand: (name) => setState(() {
                    _expandedId = _expandedId == name ? null : name;
                  }),
                ),
              ),
            ),
          ),
          child: body,
        );

        if (widget.height != null) {
          return SizedBox(height: widget.height, child: card);
        }
        return card;
      },
    );
  }
}

class _XrayBody extends StatelessWidget {
  const _XrayBody({
    required this.weights,
    required this.tab,
    required this.expandedId,
    required this.hoveredIndex,
    required this.previousHoveredIndex,
    required this.hoverAnimation,
    required this.pulseAnimation,
    required this.centerIdleLabel,
    required this.totalValue,
    required this.holdings,
    required this.marketCapAllocation,
    required this.donutSize,
    required this.onTab,
    required this.onHover,
    required this.onHoverExit,
    required this.onExpand,
    this.fillHeight = true,
    this.sideBySide = false,
  });

  final List<XrayWeight> weights;
  final int tab;
  final String? expandedId;
  final int? hoveredIndex;
  final int? previousHoveredIndex;
  final Animation<double> hoverAnimation;
  final Animation<double> pulseAnimation;
  final String centerIdleLabel;
  final double? totalValue;
  final List<PortfolioHolding>? holdings;
  final MarketCapAllocation? marketCapAllocation;
  final double donutSize;
  final ValueChanged<int> onTab;
  final ValueChanged<Offset> onHover;
  final VoidCallback onHoverExit;
  final ValueChanged<String> onExpand;
  final bool fillHeight;
  final bool sideBySide;

  @override
  Widget build(BuildContext context) {
    final bars = weights.isEmpty
        ? const IntelligenceEmptyHint(message: 'No allocation data')
        : ListView.builder(
            shrinkWrap: !fillHeight,
            physics: fillHeight
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            itemCount: weights.length,
            itemBuilder: (context, i) {
              final w = weights[i];
              final color = intelligenceDonutColor(i);
              return _WeightBar(
                weight: w,
                color: color,
                expanded: expandedId == w.name,
                onTap: () => onExpand(w.name),
                holdings: _holdingsFor(w),
                groupPct: w.weightPct,
              );
            },
          );

    final donut = SizedBox(
      width: donutSize,
      height: donutSize,
      child: MouseRegion(
        onHover: (e) => onHover(e.localPosition),
        onExit: (_) => onHoverExit(),
        child: GestureDetector(
          onPanUpdate: (d) => onHover(d.localPosition),
          onTapDown: (d) => onHover(d.localPosition),
          child: AnimatedBuilder(
            animation: Listenable.merge([hoverAnimation, pulseAnimation]),
            builder: (context, _) {
              return CustomPaint(
                painter: _CompactGlowingDonutPainter(
                  weights: weights,
                  palette: IntelligenceDonut.palette,
                  hoveredIndex: hoveredIndex,
                  previousHoveredIndex: previousHoveredIndex,
                  hoverProgress: hoverAnimation.value,
                  pulse: pulseAnimation.value,
                ),
                child: Center(child: _centerLabel(context)),
              );
            },
          ),
        ),
      ),
    );

    final Widget legendPane;
    if (weights.isEmpty) {
      legendPane = const IntelligenceEmptyHint(message: 'No allocation data');
    } else if (fillHeight) {
      legendPane = bars;
    } else {
      legendPane = ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: weights.length,
          itemBuilder: (context, i) {
            final w = weights[i];
            final color = intelligenceDonutColor(i);
            return _WeightBar(
              weight: w,
              color: color,
              expanded: expandedId == w.name,
              onTap: () => onExpand(w.name),
              holdings: _holdingsFor(w),
              groupPct: w.weightPct,
            );
          },
        ),
      );
    }

    final Widget main;
    if (sideBySide) {
      main = Row(
        crossAxisAlignment:
            fillHeight ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
        children: [
          donut,
          const SizedBox(width: 16),
          Expanded(child: legendPane),
        ],
      );
    } else {
      main = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: donut),
          const SizedBox(height: 12),
          if (fillHeight) Expanded(child: bars) else bars,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
      children: [
        _Tabs(tab: tab, onTab: onTab),
        const SizedBox(height: 12),
        if (fillHeight) Expanded(child: main) else main,
      ],
    );
  }

  Widget _centerLabel(BuildContext context) {
    if (hoveredIndex != null &&
        hoveredIndex! >= 0 &&
        hoveredIndex! < weights.length) {
      final w = weights[hoveredIndex!];
      final color = intelligenceDonutColor(hoveredIndex!);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${w.weightPct.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 22,
                ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              w.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      );
    }

    final currency = NumberFormat.compactCurrency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 1,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          centerIdleLabel,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (totalValue != null && totalValue! > 0)
          Text(
            currency.format(totalValue),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ModuleColors.portfolio,
                ),
          ),
      ],
    );
  }

  List<PortfolioHolding> _holdingsFor(XrayWeight weight) {
    final all = holdings;
    if (all == null || all.isEmpty) return const [];
    Iterable<PortfolioHolding> filtered;
    if (tab == 0) {
      filtered = all.where((h) => h.sector == weight.name);
    } else if (tab == 1) {
      filtered = all.where((h) => h.industry == weight.name);
    } else {
      final tops = marketCapAllocation?.segments
          .where((s) => s.segmentName == weight.name)
          .expand((s) => s.topStocks)
          .toSet();
      if (tops != null && tops.isNotEmpty) {
        filtered = all.where((h) => tops.contains(h.symbol));
      } else {
        filtered = const [];
      }
    }
    final list = filtered.toList()
      ..sort((a, b) => b.portfolioWeight.compareTo(a.portfolioWeight));
    return list;
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.tab, required this.onTab});

  final int tab;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget chip(int i, String label) {
      final selected = tab == i;
      return GestureDetector(
        onTap: () => onTab(i),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? ModuleColors.portfolio : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark
            ? context.colors.cardSurface.withValues(alpha: 0.55)
            : context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.border.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip(0, 'Sector'),
          chip(1, 'Industry'),
          chip(2, 'Cap'),
        ],
      ),
    );
  }
}

class _WeightBar extends StatelessWidget {
  const _WeightBar({
    required this.weight,
    required this.color,
    required this.expanded,
    required this.onTap,
    required this.holdings,
    required this.groupPct,
  });

  final XrayWeight weight;
  final Color color;
  final bool expanded;
  final VoidCallback onTap;
  final List<PortfolioHolding> holdings;
  final double groupPct;

  @override
  Widget build(BuildContext context) {
    final top = holdings.take(5).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: expanded ? color.withValues(alpha: 0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsets.all(expanded ? 10 : 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 8),
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    Expanded(
                      child: Text(
                        weight.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                      ),
                    ),
                    Text(
                      '${weight.weightPct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (weight.weightPct / 100).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: color.withValues(alpha: 0.12),
                    color: color,
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(height: 10),
                  if (top.isEmpty)
                    Text(
                      'No holdings for this group',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'HOLDING',
                            style: _colHeader(context),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '% GRP',
                            textAlign: TextAlign.end,
                            style: _colHeader(context),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '% PF',
                            textAlign: TextAlign.end,
                            style: _colHeader(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    for (final h in top)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                h.symbol,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                groupPct > 0
                                    ? '${((h.portfolioWeight / groupPct) * 100).toStringAsFixed(1)}%'
                                    : '—',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${h.portfolioWeight.toStringAsFixed(1)}%',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (holdings.length > 5)
                      Text(
                        '+${holdings.length - 5} more',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: ModuleColors.portfolio,
                            ),
                      ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _colHeader(BuildContext context) => TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).hintColor,
        letterSpacing: 0.3,
      );
}

class _CompactGlowingDonutPainter extends CustomPainter {
  _CompactGlowingDonutPainter({
    required this.weights,
    required this.palette,
    required this.hoveredIndex,
    required this.previousHoveredIndex,
    required this.hoverProgress,
    required this.pulse,
  });

  final List<XrayWeight> weights;
  final List<Color> palette;
  final int? hoveredIndex;
  final int? previousHoveredIndex;
  final double hoverProgress;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    if (weights.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (size.shortestSide / 2) - 12;
    const gap = 0.04;
    var start = -math.pi / 2;
    var total = weights.fold<double>(0, (s, w) => s + w.weightPct);
    if (total <= 0) total = 100;

    for (var i = 0; i < weights.length; i++) {
      final color = palette[i % palette.length];
      double targetAlpha(int? h) =>
          h == null ? 1.0 : (i == h ? 1.0 : 0.35);
      double targetGlow(int? h) =>
          h == null ? 0.28 : (i == h ? 0.65 : 0.08);
      double targetProg(int? h) =>
          h == null ? 0.0 : (i == h ? 1.0 : 0.0);

      final colorAlpha = targetAlpha(previousHoveredIndex) +
          (targetAlpha(hoveredIndex) - targetAlpha(previousHoveredIndex)) *
              hoverProgress;
      final glowAlpha = targetGlow(previousHoveredIndex) +
          (targetGlow(hoveredIndex) - targetGlow(previousHoveredIndex)) *
              hoverProgress;
      final hoverProg = targetProg(previousHoveredIndex) +
          (targetProg(hoveredIndex) - targetProg(previousHoveredIndex)) *
              hoverProgress;
      final idlePulse =
          (i == 0 && hoveredIndex == null) ? pulse * 0.5 : 0.0;

      final radius = baseRadius + 6 * hoverProg + idlePulse;
      final stroke = 18.0 + 3 * hoverProg;
      final rect = Rect.fromCircle(center: center, radius: radius);
      final fullSweep = (weights[i].weightPct / total) * 2 * math.pi;
      final sweep = (fullSweep - gap).clamp(0.0, fullSweep);

      if (sweep > 0) {
        canvas.drawArc(
          rect,
          start,
          sweep,
          false,
          Paint()
            ..color = color.withValues(alpha: glowAlpha * colorAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke + 5 + 6 * hoverProg
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              5 + 8 * hoverProg,
            ),
        );
        canvas.drawArc(
          rect,
          start,
          sweep,
          false,
          Paint()
            ..color = color.withValues(alpha: colorAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke,
        );
      }
      start += fullSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _CompactGlowingDonutPainter old) =>
      old.weights != weights ||
      old.hoveredIndex != hoveredIndex ||
      old.previousHoveredIndex != previousHoveredIndex ||
      old.hoverProgress != hoverProgress ||
      old.pulse != pulse;
}
