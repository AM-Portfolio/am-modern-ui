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

  @override
  void initState() {
    super.initState();
    // Analysis needs a wide default — short global app timeframes (e.g. 1D)
    // hide historical doc-parser imports and show "0 trades".
    final range = TimeFrame.all.dateRange;
    _startDate = range.start;
    _endDate = range.end;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFromAppTimeFrame();
    });
  }

  @override
  void didUpdateWidget(covariant TradeAnalysisPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.portfolioId != widget.portfolioId) {
      _loadMetrics();
    }
  }

  void _syncFromAppTimeFrame() {
    final tf = ref.read(appTimeFrameProvider);
    final range = _analysisDateRangeFor(tf);
    setState(() {
      _startDate = range.start;
      _endDate = range.end;
    });
    _loadMetrics();
  }

  /// Prefer a wide analysis window. Short global frames (1D/1W/1M) would miss
  /// multi-year broker imports that doc-parser produces.
  ({DateTime start, DateTime end}) _analysisDateRangeFor(TimeFrame tf) {
    switch (tf) {
      case TimeFrame.oneDay:
      case TimeFrame.oneWeek:
      case TimeFrame.oneMonth:
        return TimeFrame.all.dateRange;
      default:
        return tf.dateRange;
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
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: ModuleColors.trade,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startDate = picked.start;
      _endDate = picked.end;
    });
  }

  String get _dateLabel {
    final fmt = DateFormat('MMM d, yyyy');
    return '${fmt.format(_startDate)} – ${fmt.format(_endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TimeFrame>(appTimeFrameProvider, (previous, next) {
      if (previous == next) return;
      final range = _analysisDateRangeFor(next);
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
      _loadMetrics();
    });

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
                  onPickDateRange: _pickDateRange,
                  onApply: _loadMetrics,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.section),
            _AnalysisTabBar(
              selected: _tab,
              onSelected: (tab) => setState(() => _tab = tab),
            ),
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
    required this.onPickDateRange,
    required this.onApply,
  });

  final String dateLabel;
  final VoidCallback onPickDateRange;
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

/// Hub sub-tabs — same ChoiceChip pattern as Journal.
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
                  avatar: Icon(_icon(tab), size: 16),
                  label: Text(_label(tab)),
                  selected: selected == tab,
                  onSelected: (_) => onSelected(tab),
                  selectedColor: ModuleColors.trade.withValues(alpha: 0.25),
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
