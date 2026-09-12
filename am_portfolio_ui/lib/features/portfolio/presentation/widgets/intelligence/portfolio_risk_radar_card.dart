import 'dart:math' as math;

import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../internal/domain/entities/portfolio_intelligence.dart';
import '../../../providers/portfolio_intelligence_providers.dart';
import 'intelligence_glass_card.dart';
import 'risk_radar_live_view.dart';
import 'risk_radar_math.dart';

class PortfolioRiskRadarCard extends ConsumerWidget {
  const PortfolioRiskRadarCard({
    required this.portfolioId,
    this.minHeight,
    this.fillHeight = false,
    this.padding = const EdgeInsets.all(20),
    super.key,
  });

  final String portfolioId;
  final double? minHeight;
  final bool fillHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(portfolioIntelligenceProvider(portfolioId));

    return async.when(
      loading: () =>
          IntelligenceCardSkeleton(height: minHeight ?? (fillHeight ? 320 : 220)),
      error: (e, _) => IntelligenceGlassCard(
        title: 'Risk Radar',
        icon: Icons.radar_rounded,
        minHeight: minHeight,
        fillHeight: fillHeight,
        padding: padding,
        child: IntelligenceRetryRow(
          message: 'Could not load risk radar',
          onRetry: () =>
              ref.invalidate(portfolioIntelligenceProvider(portfolioId)),
        ),
      ),
      data: (intel) {
        final risk = intel?.risk;
        if (risk == null || risk.axes.isEmpty) {
          return IntelligenceGlassCard(
            title: 'Risk Radar',
            icon: Icons.radar_rounded,
            minHeight: minHeight,
            fillHeight: fillHeight,
            padding: padding,
            child: const IntelligenceEmptyHint(message: 'Risk data unavailable'),
          );
        }

        return _RiskRadarLoadedBody(
          risk: risk,
          minHeight: minHeight,
          fillHeight: fillHeight,
          padding: padding,
        );
      },
    );
  }
}

class _RiskRadarLoadedBody extends StatefulWidget {
  const _RiskRadarLoadedBody({
    required this.risk,
    required this.padding,
    this.minHeight,
    this.fillHeight = false,
  });

  final PortfolioRisk risk;
  final double? minHeight;
  final bool fillHeight;
  final EdgeInsetsGeometry padding;

  @override
  State<_RiskRadarLoadedBody> createState() => _RiskRadarLoadedBodyState();
}

class _RiskRadarLoadedBodyState extends State<_RiskRadarLoadedBody> {
  String? _selectedAxisId;
  String? _expandedKey;
  String? _sweepFocusId;
  /// User pinned a row; sweep must not clear pin.
  bool _userPinned = false;

  void _onUserSelectAxis(String? id) {
    setState(() {
      if (id == null ||
          (_selectedAxisId != null &&
              id.toUpperCase() == _selectedAxisId!.toUpperCase() &&
              _userPinned)) {
        _selectedAxisId = null;
        _userPinned = false;
        _expandedKey = null;
      } else {
        _selectedAxisId = id;
        _userPinned = true;
        _expandedKey = id;
      }
    });
  }

  void _onSweepFocus(String id) {
    if (_userPinned) return;
    if (_sweepFocusId?.toUpperCase() == id.toUpperCase()) return;
    setState(() => _sweepFocusId = id);
  }

  void _toggleFactor(_RiskFactorRow r) {
    setState(() {
      if (_expandedKey != null &&
          _expandedKey!.toUpperCase() == r.axisId.toUpperCase()) {
        _expandedKey = null;
        if (_selectedAxisId?.toUpperCase() == r.axisId.toUpperCase()) {
          _selectedAxisId = null;
          _userPinned = false;
        }
        return;
      }
      _expandedKey = r.axisId;
      _selectedAxisId = r.axisId;
      _userPinned = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final risk = widget.risk;
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final primaryAxes = riskRadarPrimaryAxes(risk.axes);
    final chartAxes =
        primaryAxes.length >= 3 ? primaryAxes : risk.axes.take(4).toList();
    final factors = _riskFactorRows(risk, chartAxes);
    final overall = _worstBandLabel(factors);
    final overallColor = _severityColor(overall);
    final semanticsBand = '$overall Risk';
    // Soft painter focus from sweep only; strong selection only when pinned.
    final focusAxisId = _userPinned ? null : _sweepFocusId;
    final pinnedAxisId = _userPinned ? _selectedAxisId : null;

    final spider = LayoutBuilder(
      builder: (context, constraints) {
        final maxW =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 260.0;
        final maxH =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 260.0;
        // Prefer a readable size, but never exceed the pane (caption eats height).
        final available = math.min(maxW, maxH);
        final lo = isPhone ? 176.0 : 200.0;
        final side = available >= lo
            ? available.clamp(lo, 320.0)
            : available.clamp(120.0, 320.0);
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: RiskRadarLiveView(
              axes: chartAxes,
              color: ModuleColors.portfolio,
              selectedAxisId: pinnedAxisId,
              focusAxisId: focusAxisId,
              semanticsLabel: 'Risk radar. Overall $semanticsBand.',
              onAxisSelected: _onUserSelectAxis,
              onSweepAxis: _onSweepFocus,
            ),
          ),
        );
      },
    );

    Widget factorList({required bool scroll}) {
      final cards = factors.map((r) {
        final expanded = _expandedKey != null &&
            _expandedKey!.toUpperCase() == r.axisId.toUpperCase();
        final selected = _userPinned &&
            _selectedAxisId != null &&
            r.axisId.toUpperCase() == _selectedAxisId!.toUpperCase();
        return Semantics(
          button: true,
          label:
              '${r.label}, score ${r.scoreLabel}, ${r.severity.toLowerCase()}',
          child: _RiskFactorCard(
            row: r,
            selected: selected,
            expanded: expanded,
            onTap: () => _toggleFactor(r),
          ),
        );
      }).toList();

      if (!scroll) {
        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: cards,
          ),
        );
      }
      return ListView(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        children: cards,
      );
    }

    final mid = isPhone
        ? (widget.fillHeight
            ? Column(
                children: [
                  Expanded(flex: 6, child: spider),
                  const SizedBox(height: 4),
                  Expanded(flex: 4, child: factorList(scroll: true)),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  spider,
                  const SizedBox(height: 4),
                  factorList(scroll: false),
                ],
              ))
        : (widget.fillHeight
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 6, child: spider),
                  const SizedBox(width: 8),
                  Expanded(flex: 4, child: factorList(scroll: true)),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: spider),
                  const SizedBox(width: 8),
                  Expanded(flex: 4, child: factorList(scroll: false)),
                ],
              ));

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: widget.fillHeight ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Text(
          'Scores are 0–100. Higher means more risk.',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
        ),
        const SizedBox(height: 8),
        if (widget.fillHeight) Expanded(child: mid) else mid,
      ],
    );

    return IntelligenceGlassCard(
      title: 'Risk Radar',
      icon: Icons.radar_rounded,
      minHeight: widget.minHeight,
      fillHeight: widget.fillHeight,
      padding: widget.padding,
      scrollable: false,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: overallColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: overallColor.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_rounded, size: 14, color: overallColor),
            const SizedBox(width: 4),
            Text(
              '$overall Risk',
              style: TextStyle(
                color: overallColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      child: body,
    );
  }
}

class _RiskFactorRow {
  const _RiskFactorRow({
    required this.axisId,
    required this.label,
    required this.scoreLabel,
    required this.severity,
    this.findingLabel,
  });

  final String axisId;
  final String label;
  final String scoreLabel;
  final String severity;
  final String? findingLabel;
}

List<_RiskFactorRow> _riskFactorRows(
  PortfolioRisk risk,
  List<RiskAxis> chartAxes,
) {
  return chartAxes.map((a) {
    final finding = riskRadarFindingForAxis(risk.findings, a.id);
    return _RiskFactorRow(
      axisId: a.id,
      label: riskRadarAxisLabel(a),
      scoreLabel: riskRadarScoreLabel(a.riskScore),
      severity: riskRadarBandSeverity(a.riskScore),
      findingLabel: finding?.label,
    );
  }).toList();
}

String _worstBandLabel(List<_RiskFactorRow> rows) {
  if (rows.isEmpty) return 'Good';
  var rank = 0;
  for (final r in rows) {
    final s = r.severity.toUpperCase();
    final v = switch (s) {
      'HIGH' || 'CRITICAL' => 3,
      'MEDIUM' || 'WATCH' => 2,
      _ => 1,
    };
    if (v > rank) rank = v;
  }
  return switch (rank) {
    3 => 'High',
    2 => 'Medium',
    _ => 'Good',
  };
}

class _RiskFactorCard extends StatefulWidget {
  const _RiskFactorCard({
    required this.row,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final _RiskFactorRow row;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  State<_RiskFactorCard> createState() => _RiskFactorCardState();
}

class _RiskFactorCardState extends State<_RiskFactorCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final pill = switch (row.severity.toUpperCase()) {
      'HIGH' || 'CRITICAL' => 'High',
      'MEDIUM' || 'WATCH' => 'Medium',
      _ => 'Good',
    };
    final severityColor = _severityColor(row.severity);
    final accent = riskRadarAxisAccent(row.axisId);
    final goldFocus = widget.selected || widget.expanded || _hovered;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final insight = riskRadarKeyInsightParagraph(row.axisId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: widget.expanded || widget.selected
              ? accent.withValues(alpha: 0.08)
              : Theme.of(context).colorScheme.surface.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: goldFocus
                      ? kRiskRadarPolygonGold.withValues(alpha: 0.85)
                      : accent.withValues(alpha: 0.28),
                  width: goldFocus ? 1.6 : 1,
                ),
              ),
              child: AnimatedSize(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 7, 4, 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, rowConstraints) {
                          final showPill = rowConstraints.maxWidth >= 120;
                          return Row(
                            children: [
                              Icon(riskRadarAxisIcon(row.axisId),
                                  size: 17, color: accent),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  row.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontSize: 13,
                                        fontWeight: widget.expanded
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        height: 1.15,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                row.scoreLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                    ),
                              ),
                              if (showPill) ...[
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        severityColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: severityColor.withValues(
                                        alpha: 0.45,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    pill,
                                    style: TextStyle(
                                      color: severityColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      if (widget.expanded) ...[
                        const SizedBox(height: 6),
                        _KeyInsightPanel(
                          insight: insight,
                          findingLabel: row.findingLabel,
                          accent: accent,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyInsightPanel extends StatelessWidget {
  const _KeyInsightPanel({
    required this.insight,
    required this.accent,
    this.findingLabel,
  });

  final String insight;
  final Color accent;
  final String? findingLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(
                'Key Insight',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            insight,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  height: 1.3,
                  color: Theme.of(context).hintColor,
                ),
          ),
          if (findingLabel != null && findingLabel!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              findingLabel!.trim(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

Color _severityColor(String? severity) {
  final s = (severity ?? '').toUpperCase();
  switch (s) {
    case 'HIGH':
    case 'CRITICAL':
      return const Color(0xFFFF7675);
    case 'MEDIUM':
    case 'WATCH':
      return const Color(0xFFFDCB6E);
    case 'GOOD':
    default:
      return const Color(0xFF00B894);
  }
}
