import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../internal/domain/entities/metrics/metrics_filter_request.dart';
import '../../internal/domain/enums/metric_types.dart';
import '../../providers/trade_metrics_providers.dart';
import 'tabs/timing_analysis_tab.dart';

enum _AnalysisTab { timing, strategy, direction, holding, risk }

/// Analysis hub — Timing-first edge analytics.
///
/// No page title (sidebar labels the page), no portfolio dropdown, no Export.
/// Date range + Apply sit on the tab row. Timing shows insights + KPI cards.
/// See Doc/analysis_ui_mock_plan.md (Timing KPI strip is intentional for this delivery).
class TradeAnalysisPage extends ConsumerStatefulWidget {
  const TradeAnalysisPage({
    super.key,
    required this.portfolioId,
    this.onOpenCalendar,
    this.onOpenJournalInsights,
  });

  final String portfolioId;
  final VoidCallback? onOpenCalendar;
  final VoidCallback? onOpenJournalInsights;

  @override
  ConsumerState<TradeAnalysisPage> createState() => _TradeAnalysisPageState();
}

class _TradeAnalysisPageState extends ConsumerState<TradeAnalysisPage> {
  _AnalysisTab _tab = _AnalysisTab.timing;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _usingAllTime = true;
  String? _holdingStyle;

  static DateTimeRange get _allTimeRange {
    final range = TimeFrame.all.dateRange;
    return DateTimeRange(start: range.start, end: range.end);
  }

  @override
  void initState() {
    super.initState();
    final all = _allTimeRange;
    _startDate = all.start;
    _endDate = all.end;
    _usingAllTime = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadMetrics();
    });
  }

  @override
  void didUpdateWidget(covariant TradeAnalysisPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.portfolioId != widget.portfolioId) {
      _loadMetrics();
    }
  }

  Future<void> _loadMetrics() async {
    final resolved = await ref.read(tradeMetricsCubitProvider.future);
    if (!mounted) return;
    resolved.loadMetrics(
      MetricsFilterRequest(
        portfolioIds: [widget.portfolioId],
        startDate: _startDate,
        endDate: _endDate,
        metricTypes: const [MetricTypes.performance, MetricTypes.distribution],
        holdingStyle: _holdingStyle,
      ),
    );
  }

  void _onHoldingStyleChanged(String? style) {
    setState(() => _holdingStyle = style);
    _loadMetrics();
  }

  void _resetToAllTime() {
    final all = _allTimeRange;
    setState(() {
      _startDate = all.start;
      _endDate = all.end;
      _usingAllTime = true;
    });
    _loadMetrics();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (ctx) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                  primary: ModuleColors.trade,
                  onPrimary: Colors.white,
                ),
          ),
          child: CompactDateRangePickerDialog(
            initialDateRange: DateTimeRange(
              start: _startDate,
              end: _endDate,
            ),
          ),
        );
      },
    );
    if (picked == null || !mounted) return;

    final all = _allTimeRange;
    final choseAllTime = _isSameCalendarDay(picked.start, all.start) &&
        _isSameCalendarDay(picked.end, all.end);

    setState(() {
      _startDate = picked.start;
      _endDate = picked.end;
      _usingAllTime = choseAllTime;
    });
    await _loadMetrics();
  }

  static bool _isSameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String get _dateLabel {
    if (_usingAllTime) return 'All time';
    final fmt = DateFormat('MMM d, yyyy');
    return '${fmt.format(_startDate)} – ${fmt.format(_endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final cubitAsync = ref.watch(tradeMetricsCubitProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tabs + date/Apply on one row — no page title / LIVE EDGE / portfolio.
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _AnalysisTabBar(
                    selected: _tab,
                    onSelected: (tab) => setState(() => _tab = tab),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _DateApplyBar(
                  dateLabel: _dateLabel,
                  usingAllTime: _usingAllTime,
                  onPickDateRange: _pickDateRange,
                  onResetAllTime: _resetToAllTime,
                  onApply: _loadMetrics,
                ),
              ],
            ),
            if (_tab == _AnalysisTab.timing) ...[
              const SizedBox(height: AppSpacing.sm),
              _HoldingStyleFilter(
                selected: _holdingStyle,
                onChanged: _onHoldingStyleChanged,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: cubitAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: ModuleColors.trade),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Error: $e',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.statusError,
                    ),
                  ),
                ),
                data: (cubit) {
                  if (_tab == _AnalysisTab.timing) {
                    return TimingAnalysisTab(
                      cubit: cubit,
                      onApply: _loadMetrics,
                      onOpenCalendar: widget.onOpenCalendar ?? () {},
                      onOpenJournalInsights:
                          widget.onOpenJournalInsights ?? () {},
                    );
                  }
                  return _ComingSoonTab(tab: _tab);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateApplyBar extends StatelessWidget {
  const _DateApplyBar({
    required this.dateLabel,
    required this.usingAllTime,
    required this.onPickDateRange,
    required this.onResetAllTime,
    required this.onApply,
  });

  final String dateLabel;
  final bool usingAllTime;
  final VoidCallback onPickDateRange;
  final VoidCallback onResetAllTime;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppButton(
          text: dateLabel,
          type: AppButtonType.secondary,
          isOutlined: true,
          icon: Icons.calendar_today_outlined,
          onPressed: onPickDateRange,
          height: 36,
        ),
        if (!usingAllTime)
          AppButton(
            text: 'All time',
            type: AppButtonType.text,
            onPressed: onResetAllTime,
            height: 36,
            textColor: ModuleColors.trade,
          ),
        AppButton(
          text: 'Apply',
          type: AppButtonType.primary,
          onPressed: onApply,
          height: 36,
          backgroundColor: ModuleColors.trade,
        ),
      ],
    );
  }
}

class _HoldingStyleFilter extends StatelessWidget {
  const _HoldingStyleFilter({
    required this.selected,
    required this.onChanged,
  });

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget pill(String label, String? value) {
      return AmToggleChip(
        label: label,
        selected: selected == value,
        compact: true,
        accentColor: ModuleColors.trade,
        onTap: () => onChanged(value),
      );
    }

    return Row(
      children: [
        Text(
          'Holding style:',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              pill('All', null),
              pill('Scalper', 'SCALPER'),
              pill('Intraday', 'INTRADAY'),
              pill('Swing', 'SWING'),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnalysisTabBar extends StatelessWidget {
  const _AnalysisTabBar({required this.selected, required this.onSelected});

  final _AnalysisTab selected;
  final ValueChanged<_AnalysisTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.border.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tab in _AnalysisTab.values) ...[
              if (tab.index > 0) const SizedBox(width: AppSpacing.xs),
              ChoiceChip(
                avatar: Icon(
                  _icon(tab),
                  size: 16,
                  color: selected == tab
                      ? ModuleColors.trade
                      : colors.textSecondary,
                ),
                label: Text(_label(tab)),
                selected: selected == tab,
                onSelected: (_) => onSelected(tab),
                selectedColor: ModuleColors.trade.withValues(alpha: 0.22),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _label(_AnalysisTab tab) => switch (tab) {
        _AnalysisTab.timing => 'Timing',
        _AnalysisTab.strategy => 'Strategy',
        _AnalysisTab.direction => 'Direction',
        _AnalysisTab.holding => 'Holding',
        _AnalysisTab.risk => 'Risk',
      };

  IconData _icon(_AnalysisTab tab) => switch (tab) {
        _AnalysisTab.timing => Icons.schedule_outlined,
        _AnalysisTab.strategy => Icons.flag_outlined,
        _AnalysisTab.direction => Icons.swap_vert,
        _AnalysisTab.holding => Icons.hourglass_empty_outlined,
        _AnalysisTab.risk => Icons.shield_outlined,
      };
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({required this.tab});

  final _AnalysisTab tab;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = switch (tab) {
      _AnalysisTab.timing => 'Timing',
      _AnalysisTab.strategy => 'Strategy',
      _AnalysisTab.direction => 'Direction',
      _AnalysisTab.holding => 'Holding',
      _AnalysisTab.risk => 'Risk',
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.construction_outlined,
            size: 40,
            color: colors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '$name analytics coming next',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
