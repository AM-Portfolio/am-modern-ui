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

/// Analysis hub — edge analytics (Timing first; other tabs stubbed).
///
/// Date range is owned by this page: default is **all time → today**.
/// Global app [appTimeFrameProvider] must not shrink Analysis to 1D/1W.
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
  /// true until the user picks a narrower range in the calendar.
  bool _usingAllTime = true;
  /// null = All holding styles.
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
        metricTypes: const [MetricTypes.distribution],
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
    // Do NOT listen to [appTimeFrameProvider] — global 1D/1W must not wipe
    // Analysis' all-time default.

    final colors = context.colors;
    final theme = Theme.of(context);
    final cubitAsync = ref.watch(tradeMetricsCubitProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analysis',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Analyze your trading patterns to find edge and improve.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
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
            const SizedBox(height: AppSpacing.section),
            _AnalysisTabBar(
              selected: _tab,
              onSelected: (tab) => setState(() => _tab = tab),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          text: dateLabel,
          type: AppButtonType.secondary,
          isOutlined: true,
          icon: Icons.calendar_today_outlined,
          onPressed: onPickDateRange,
          height: 40,
        ),
        if (!usingAllTime) ...[
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            text: 'All time',
            type: AppButtonType.text,
            onPressed: onResetAllTime,
            height: 40,
            textColor: ModuleColors.trade,
          ),
        ],
        const SizedBox(width: AppSpacing.sm),
        AppButton(
          text: 'Apply',
          type: AppButtonType.primary,
          onPressed: onApply,
          height: 40,
          backgroundColor: ModuleColors.trade,
        ),
      ],
    );
  }
}

/// Holding-style filter — same session clocks; subsets trades by hold duration.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Holding style',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            pill('All', null),
            pill('Scalper', 'SCALPER'),
            pill('Intraday', 'INTRADAY'),
            pill('Swing', 'SWING'),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Scalper <15m · Intraday 15m–<24h · Swing ≥24h. Session windows stay the same.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
        ),
      ],
    );
  }
}

/// Hub sub-tabs — soft ChoiceChip pattern matching Journal.
class _AnalysisTabBar extends StatelessWidget {
  const _AnalysisTabBar({required this.selected, required this.onSelected});

  final _AnalysisTab selected;
  final ValueChanged<_AnalysisTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.cardSurface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final tab in _AnalysisTab.values) ...[
                if (tab.index > 0) const SizedBox(width: AppSpacing.sm),
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
                  selectedColor: ModuleColors.trade.withValues(alpha: 0.25),
                  showCheckmark: false,
                ),
              ],
            ],
          ),
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
