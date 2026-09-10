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
    super.key,
  });

  final String portfolioId;
  final double? minHeight;
  final bool fillHeight;

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
            child: const IntelligenceEmptyHint(message: 'Risk data unavailable'),
          );
        }

        return _RiskRadarLoadedBody(
          risk: risk,
          minHeight: minHeight,
          fillHeight: fillHeight,
        );
      },
    );
  }
}

class _RiskRadarLoadedBody extends StatefulWidget {
  const _RiskRadarLoadedBody({
    required this.risk,
    this.minHeight,
    this.fillHeight = false,
  });

  final PortfolioRisk risk;
  final double? minHeight;
  final bool fillHeight;

  @override
  State<_RiskRadarLoadedBody> createState() => _RiskRadarLoadedBodyState();
}

class _RiskRadarLoadedBodyState extends State<_RiskRadarLoadedBody> {
  String? _selectedAxisId;
  String? _expandedKey;
  /// User pinned a row; sweep must not override until cleared.
  bool _userPinned = false;

  String _rowKey(_DisplayFinding r) =>
      r.axisId ?? 'finding:${r.label}:${r.value}';

  void _selectAxis(String? id, {required bool fromUser}) {
    setState(() {
      if (fromUser) {
        if (id == null ||
            (_selectedAxisId != null &&
                id.toUpperCase() == _selectedAxisId!.toUpperCase() &&
                _userPinned)) {
          _selectedAxisId = null;
          _userPinned = false;
        } else {
          _selectedAxisId = id;
          _userPinned = id != null;
        }
      } else {
        if (_userPinned) return;
        _selectedAxisId = id;
        // Sweep highlights radar/callout only — do not auto-expand rows.
      }
      if (fromUser && _selectedAxisId != null) {
        _expandedKey = _selectedAxisId;
      } else if (fromUser && _selectedAxisId == null) {
        _expandedKey = null;
      }
    });
  }

  void _toggleRow(_DisplayFinding r) {
    final key = _rowKey(r);
    setState(() {
      if (_expandedKey == key) {
        _expandedKey = null;
        if (r.axisId != null &&
            _selectedAxisId?.toUpperCase() == r.axisId!.toUpperCase()) {
          _selectedAxisId = null;
          _userPinned = false;
        }
        return;
      }
      _expandedKey = key;
      if (r.axisId != null) {
        _selectedAxisId = r.axisId;
        _userPinned = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final risk = widget.risk;
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final rows = _displayFindings(risk);
    final insight = _keyInsight(rows);
    final overall = _worstBandLabel(rows);
    final overallColor = _severityColor(overall);
    final topAxisId = risk.axes.isEmpty
        ? null
        : ([...risk.axes]..sort((a, b) => b.riskScore.compareTo(a.riskScore)))
            .first
            .id;
    final focusAxisId = _selectedAxisId ?? topAxisId;
    // Sized so collapsed 4 factors + insight fit the peer band without page scroll.
    final spiderSize = isPhone ? 200.0 : (widget.fillHeight ? 210.0 : 220.0);

    Widget buildSpider(double side) => SizedBox(
          width: side,
          height: side,
          child: RiskRadarLiveView(
            axes: risk.axes,
            color: ModuleColors.portfolio,
            selectedAxisId: _selectedAxisId,
            focusAxisId: focusAxisId,
            semanticsLabel: 'Risk radar. $insight',
            onAxisSelected: (id) => _selectAxis(id, fromUser: true),
            onSweepAxis: (id) => _selectAxis(id, fromUser: false),
          ),
        );

    final spider = LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : spiderSize;
        final side = spiderSize.clamp(140.0, maxW);
        return buildSpider(side);
      },
    );

    Widget metricList({required bool scroll}) {
      final hint = Text(
        'Tap a factor to learn what it means. Higher score = more risk.',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).hintColor,
              height: 1.3,
            ),
      );
      final rowWidgets = rows.map((r) {
        final key = _rowKey(r);
        final selected = r.axisId != null &&
            _selectedAxisId != null &&
            r.axisId!.toUpperCase() == _selectedAxisId!.toUpperCase();
        final expanded = _expandedKey == key;
        return _ExpandableMetricRow(
          row: r,
          selected: selected,
          expanded: expanded,
          onTap: () => _toggleRow(r),
        );
      }).toList();

      if (!scroll) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [hint, const SizedBox(height: 6), ...rowWidgets],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hint,
          const SizedBox(height: 6),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: rowWidgets,
            ),
          ),
        ],
      );
    }

    final mid = isPhone
        ? (widget.fillHeight
            ? Column(
                children: [
                  Center(child: spider),
                  const SizedBox(height: 8),
                  Expanded(child: metricList(scroll: true)),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(child: spider),
                  const SizedBox(height: 8),
                  metricList(scroll: false),
                ],
              ))
        : (widget.fillHeight
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    flex: 5,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: spider,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(flex: 5, child: metricList(scroll: true)),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 5,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: spider,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(flex: 5, child: metricList(scroll: false)),
                ],
              ));

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How your portfolio risk is distributed',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.w500,
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
      scrollable: false,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: overallColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: overallColor.withValues(alpha: 0.45)),
        ),
        child: Text(
          overall,
          style: TextStyle(
            color: overallColor,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
      footer: _KeyInsightBanner(message: insight),
      child: body,
    );
  }
}

class _KeyInsightBanner extends StatelessWidget {
  const _KeyInsightBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: ModuleColors.portfolio.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ModuleColors.portfolio.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 16,
            color: ModuleColors.portfolio,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Key insight  ',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ModuleColors.portfolio,
                        ),
                  ),
                  TextSpan(
                    text: message,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          height: 1.3,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisplayFinding {
  const _DisplayFinding({
    required this.label,
    required this.value,
    required this.severity,
    this.axisId,
  });

  final String label;
  final String value;
  final String severity;
  final String? axisId;
}

List<_DisplayFinding> _displayFindings(PortfolioRisk risk) {
  if (risk.findings.isNotEmpty) {
    return risk.findings.take(4).map((f) {
      final sev = (f.severity ?? 'GOOD').toUpperCase();
      final valueMatch = RegExp(r'([\d.]+%?)\s*$').firstMatch(f.label.trim());
      final value = valueMatch?.group(1) ?? '—';
      var label = f.label.trim();
      if (valueMatch != null) {
        label = label.substring(0, valueMatch.start).trim();
      }
      if (label.isEmpty) label = f.code;
      return _DisplayFinding(label: label, value: value, severity: sev);
    }).toList();
  }

  final sorted = [...risk.axes]
    ..sort((a, b) => b.riskScore.compareTo(a.riskScore));
  return sorted.take(4).map((a) {
    return _DisplayFinding(
      label: riskRadarAxisLabel(a),
      value: a.riskScore.toStringAsFixed(0),
      severity: riskRadarBandSeverity(a.riskScore),
      axisId: a.id,
    );
  }).toList();
}

String _keyInsight(List<_DisplayFinding> rows) {
  if (rows.isEmpty) {
    return 'No material risk signals right now.';
  }
  final top = rows.first;
  return '${top.label} is currently your largest risk factor (${top.value}).';
}

String _worstBandLabel(List<_DisplayFinding> rows) {
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

class _ExpandableMetricRow extends StatelessWidget {
  const _ExpandableMetricRow({
    required this.row,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final _DisplayFinding row;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pill = switch (row.severity.toUpperCase()) {
      'HIGH' || 'CRITICAL' => 'High',
      'MEDIUM' || 'WATCH' => 'Medium',
      _ => 'Good',
    };
    final color = _severityColor(row.severity);
    final edu = row.axisId != null
        ? riskRadarAxisEducation(row.axisId!)
        : (
            meaning:
                'This is a notable risk signal from your current portfolio.',
            tip:
                'Open related factors on the radar to see how risk is '
                'distributed across your book.',
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: (expanded || selected)
            ? ModuleColors.portfolio.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          row.label,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: expanded
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                row.value,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.45),
                                  ),
                                ),
                                child: Text(
                                  pill,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Icon(
                                expanded
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                size: 16,
                                color: Theme.of(context).hintColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (expanded) ...[
                    const SizedBox(height: 6),
                    _EduLine(title: 'What it means', body: edu.meaning),
                    _EduLine(title: 'Good to know', body: edu.tip),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EduLine extends StatelessWidget {
  const _EduLine({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ModuleColors.portfolio,
                ),
          ),
          Text(
            body,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  height: 1.35,
                  color: Theme.of(context).hintColor,
                ),
          ),
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
