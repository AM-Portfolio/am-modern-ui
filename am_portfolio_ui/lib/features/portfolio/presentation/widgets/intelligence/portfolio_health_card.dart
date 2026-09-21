import 'dart:math' as math;

import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../internal/domain/entities/portfolio_intelligence.dart';
import '../../../providers/portfolio_intelligence_providers.dart';
import 'intelligence_glass_card.dart';

/// Canonical Overview Health factors (order matches product UI).
@visibleForTesting
const kOverviewHealthFactorIds = <String>[
  'diversification',
  'concentration',
  'volatility',
  'liquidity',
  'allocation',
  'risk_resilience',
];

@visibleForTesting
const kHealthGaugeSize = 140.0;

@visibleForTesting
const kHealthSummaryCol = 168.0;

@visibleForTesting
const kHealthScoreCol = 36.0;

@visibleForTesting
const kHealthStatusCol = 96.0;

/// Pick Overview factors from API components; skip missing ids.
@visibleForTesting
List<HealthComponent> selectOverviewHealthFactors(
  List<HealthComponent> components,
) {
  final byId = <String, HealthComponent>{
    for (final c in components) c.id.toLowerCase(): c,
  };
  return [
    for (final id in kOverviewHealthFactorIds)
      if (byId.containsKey(id)) byId[id]!,
  ];
}

/// Mirrors backend [HealthScoreConstants.bandFor] for display only.
@visibleForTesting
String healthBandForScore(num score) {
  final s = score.round();
  if (s <= 39) return 'Critical';
  if (s <= 64) return 'Watch';
  if (s <= 84) return 'Healthy';
  return 'Strong';
}

@visibleForTesting
int countStrongHealthFactors(List<HealthComponent> factors) {
  return factors.where((c) => healthBandForScore(c.score) == 'Strong').length;
}

/// Product status label from existing band thresholds (display only).
@visibleForTesting
String healthStatusLabel(num score) {
  final band = healthBandForScore(score);
  if (band == 'Strong' && score >= 95) return 'Excellent';
  if (band == 'Watch') return 'Needs Attention';
  return band;
}

/// Light presentation polish on backend `reason` — no invented metrics.
@visibleForTesting
String healthReasonDisplay(String? reason) {
  if (reason == null || reason.trim().isEmpty) return '';
  var t = reason.trim();
  t = t.replaceFirst(RegExp(r'^Top1\b', caseSensitive: false), 'Top holding');
  t = t.replaceAll(
    RegExp(r'\s*/\s*vol\s*/\s*', caseSensitive: false),
    ' / volatility / ',
  );
  t = t.replaceFirst(
    RegExp(r'^Insufficient history\b', caseSensitive: false),
    'History short',
  );
  t = t.replaceAll(RegExp(r',\s*'), ' • ');
  t = t.replaceAllMapped(
    RegExp(r'•\s*([a-z])'),
    (m) => '• ${m[1]!.toUpperCase()}',
  );
  // Legacy vol reasons concatenate raw doubles ("Daily vol 3.387555…%").
  t = t.replaceAllMapped(RegExp(r'(\d+\.\d{3,})\s*%'), (m) {
    final v = double.tryParse(m[1]!);
    if (v == null) return m[0]!;
    return '${v.toStringAsFixed(2)}%';
  });
  return t;
}

class PortfolioHealthCard extends ConsumerStatefulWidget {
  const PortfolioHealthCard({
    required this.portfolioId,
    this.compact = false,
    @Deprecated('Overview shows the canonical Health factors from API')
    this.maxComponents,
    this.minHeight,
    this.fillHeight = false,
    this.padding = const EdgeInsets.all(20),
    super.key,
  });

  final String portfolioId;
  final bool compact;
  final int? maxComponents;
  final double? minHeight;
  final bool fillHeight;
  final EdgeInsetsGeometry padding;

  @override
  ConsumerState<PortfolioHealthCard> createState() =>
      _PortfolioHealthCardState();
}

class _PortfolioHealthCardState extends ConsumerState<PortfolioHealthCard> {
  /// One invalidate after cold intel so Volatility upgrades without F5.
  bool _refetchScheduledAfterCold = false;

  @override
  void didUpdateWidget(covariant PortfolioHealthCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.portfolioId != widget.portfolioId) {
      _refetchScheduledAfterCold = false;
    }
  }

  void _maybeRefetchAfterHistWarm(PortfolioIntelligence? intel) {
    if (_refetchScheduledAfterCold) return;
    if (intel == null) return;
    final cold = (intel.confidence ?? 1) < 0.9;
    final factors = selectOverviewHealthFactors(intel.health?.components ?? const []);
    final hasVol = factors.any((c) => c.id.toLowerCase() == 'volatility');
    final volInsufficient = factors.any((c) =>
        c.id.toLowerCase() == 'volatility' &&
        (c.reason ?? '').toLowerCase().contains('insufficient'));
    // Refetch only when still cold / placeholder vol — hist may be warm now.
    if (!cold && hasVol && !volInsufficient) return;
    _refetchScheduledAfterCold = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(portfolioIntelligenceProvider(widget.portfolioId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(portfolioIntelligenceProvider(widget.portfolioId));

    return async.when(
      loading: () => IntelligenceCardSkeleton(
        height: widget.minHeight ?? (widget.fillHeight ? 420 : 280),
      ),
      error: (e, _) => IntelligenceGlassCard(
        title: 'Health Score',
        icon: Icons.favorite_rounded,
        minHeight: widget.minHeight,
        fillHeight: widget.fillHeight,
        padding: widget.padding,
        child: IntelligenceRetryRow(
          message: 'Could not load health score',
          onRetry: () =>
              ref.invalidate(portfolioIntelligenceProvider(widget.portfolioId)),
        ),
      ),
      data: (intel) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _maybeRefetchAfterHistWarm(intel);
        });
        final health = intel?.health;
        if (health == null) {
          return IntelligenceGlassCard(
            title: 'Health Score',
            icon: Icons.favorite_rounded,
            minHeight: widget.minHeight,
            fillHeight: widget.fillHeight,
            padding: widget.padding,
            child: Text(
              'Health data unavailable',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }

        final factors = selectOverviewHealthFactors(health.components);
        final strongCount = countStrongHealthFactors(factors);

        return IntelligenceGlassCard(
          title: 'Health Score',
          icon: Icons.favorite_rounded,
          minHeight: widget.minHeight,
          fillHeight: widget.fillHeight,
          padding: widget.padding,
          // Never nest a card-level scroll here: Overview already scrolls, and
          // fillHeight peers use _FactorList's own ListView. Nested
          // SingleChildScrollView + ListView + BackdropFilter caused stuck /
          // janky page scroll and a collapsed Health card.
          scrollable: false,
          child: _HealthBody(
            fillHeight: widget.fillHeight,
            compact: widget.compact,
            score: health.score,
            band: health.band,
            bandColor: _bandColor(context, health.band),
            factors: factors,
            strongCount: strongCount,
          ),
        );
      },
    );
  }
}

Color _bandColor(BuildContext context, String band) =>
    IntelligenceColors.healthBand(band, context.colors);

Color _factorAccent(String id) => IntelligenceColors.factorAccent(id);

IconData _factorIcon(String id) {
  switch (id.toLowerCase()) {
    case 'diversification':
      return Icons.hub_outlined;
    case 'concentration':
      return Icons.gps_fixed_rounded;
    case 'volatility':
      return Icons.waves_outlined;
    case 'liquidity':
      return Icons.water_drop_outlined;
    case 'allocation':
      return Icons.pie_chart_outline_rounded;
    case 'risk_resilience':
      return Icons.shield_outlined;
    default:
      return Icons.circle_outlined;
  }
}

class _HealthBody extends StatelessWidget {
  const _HealthBody({
    required this.fillHeight,
    required this.compact,
    required this.score,
    required this.band,
    required this.bandColor,
    required this.factors,
    required this.strongCount,
  });

  final bool fillHeight;
  final bool compact;
  final double score;
  final String band;
  final Color bandColor;
  final List<HealthComponent> factors;
  final int strongCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Need room for summary 168 + gap 16 + usable factor list (~220).
        final sideBySide =
            !compact && constraints.maxWidth >= (kHealthSummaryCol + 16 + 220);
        final summary = _SummaryColumn(
          score: score,
          band: band,
          bandColor: bandColor,
          factorCount: factors.length,
          strongCount: strongCount,
          gaugeSize: sideBySide ? kHealthGaugeSize : 128,
        );
        // When peer-stretched (fillHeight), allow a tiny inner scroll so a late
        // 6th factor (Volatility after history warms) never yellow-overflows.
        // Unbounded Overview scroll still owns the page when not fillHeight.
        final list = _FactorList(
          factors: factors,
          scrollable: fillHeight,
        );

        if (sideBySide) {
          final row = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: kHealthSummaryCol, child: summary),
              const SizedBox(width: 16),
              Expanded(child: list),
            ],
          );
          if (fillHeight) return row;
          return IntrinsicHeight(child: row);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            summary,
            const SizedBox(height: 12),
            list,
          ],
        );
      },
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.score,
    required this.band,
    required this.bandColor,
    required this.factorCount,
    required this.strongCount,
    required this.gaugeSize,
  });

  final double score;
  final String band;
  final Color bandColor;
  final int factorCount;
  final int strongCount;
  final double gaugeSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _HealthGauge(
          score: score,
          band: band,
          bandColor: bandColor,
          size: gaugeSize,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _StatCell(
                  value: '$factorCount',
                  label: 'Health Factors',
                  valueColor: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08),
              ),
              Expanded(
                child: _StatCell(
                  value: '$strongCount',
                  label: 'Strong',
                  valueColor: bandColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: valueColor,
                height: 1.05,
                fontSize: 22,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}

class _FactorList extends StatelessWidget {
  const _FactorList({
    required this.factors,
    required this.scrollable,
  });

  final List<HealthComponent> factors;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    if (factors.isEmpty) {
      return Text(
        'No health factors available',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final dense = factors.length >= 6;
    final gap = dense ? 2.0 : 6.0;
    final children = <Widget>[
      for (var i = 0; i < factors.length; i++) ...[
        if (i > 0) SizedBox(height: gap),
        _FactorRow(
          component: factors[i],
          compact: dense,
        ),
      ],
    ];
    if (!scrollable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    }
    // Bounded by peer Expanded — primary scroll stays on Overview page.
    return ListView(
      padding: EdgeInsets.zero,
      primary: false,
      physics: const ClampingScrollPhysics(),
      children: children,
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({
    required this.component,
    this.compact = false,
  });

  final HealthComponent component;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = _factorAccent(component.id);
    final status = healthStatusLabel(component.score);
    final statusColor =
        _bandColor(context, healthBandForScore(component.score));
    final reason = healthReasonDisplay(component.reason);
    final progress = (component.score.clamp(0, 100)) / 100;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padV = compact ? 3.0 : 5.0;
    final iconSize = compact ? 26.0 : 32.0;

    return Container(
      padding: EdgeInsets.fromLTRB(10, padV, 10, padV),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_factorIcon(component.id), size: 16, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  component.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 12 : 13,
                      ),
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    reason,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).hintColor,
                          fontSize: 10,
                          height: 1.2,
                        ),
                  ),
                ],
                SizedBox(height: compact ? 4 : 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: compact ? 3 : 4,
                          backgroundColor: accent.withValues(alpha: 0.12),
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: kHealthScoreCol,
                      child: Text(
                        component.score.toStringAsFixed(0),
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: kHealthStatusCol,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthGauge extends StatelessWidget {
  const _HealthGauge({
    required this.score,
    required this.band,
    required this.bandColor,
    this.size = kHealthGaugeSize,
  });

  final double score;
  final String band;
  final Color bandColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(
          progress: (score.clamp(0, 100)) / 100,
          color: bandColor,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toStringAsFixed(0),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1,
                      fontSize: size >= 140 ? 34 : 28,
                    ),
              ),
              Text(
                '/ 100',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).hintColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: bandColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: bandColor.withValues(alpha: 0.45)),
                ),
                child: Text(
                  band,
                  style: TextStyle(
                    color: bandColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final track = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final glow = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius - 8);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, track);
    final sweep = 2 * math.pi * progress;
    if (sweep > 0) {
      canvas.drawArc(rect, -math.pi / 2, sweep, false, glow);
      canvas.drawArc(rect, -math.pi / 2, sweep, false, fg);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
