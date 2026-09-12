import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../internal/domain/entities/metrics/metrics_filter_request.dart';
import '../../internal/domain/enums/metric_types.dart';
import '../../providers/trade_metrics_providers.dart';
import '../metrics/cubit/trade_metrics_cubit.dart';
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
  TradeMetricsCubit? _cubit;

  @override
  void initState() {
    super.initState();
    final range = TimeFrame.oneYear.dateRange;
    _startDate = range.start;
    _endDate = range.end;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFromAppTimeFrame();
    });
  }

  void _syncFromAppTimeFrame() {
    final range = ref.read(appTimeFrameProvider).dateRange;
    setState(() {
      _startDate = range.start;
      _endDate = range.end;
    });
    _loadMetrics();
  }

  Future<void> _ensureCubit() async {
    _cubit ??= await ref.read(tradeMetricsCubitProvider.future);
  }

  Future<void> _loadMetrics() async {
    await _ensureCubit();
    if (!mounted || _cubit == null) return;
    _cubit!.loadMetrics(
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
    final theme = Theme.of(context);
    final cubitAsync = ref.watch(tradeMetricsCubitProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
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
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Analyze your trading patterns to find edge and improve.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _DateApplyBar(
                  dateLabel: _dateLabel,
                  onPickDateRange: _pickDateRange,
                  onApply: _loadMetrics,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _UnderlineTabBar(
              selected: _tab,
              onSelected: (tab) => setState(() => _tab = tab),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: cubitAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (cubit) {
                  _cubit = cubit;
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
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: onPickDateRange,
          icon: Icon(Icons.calendar_today_outlined,
              size: 16, color: ModuleColors.trade),
          label: Text(dateLabel),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface,
            side: BorderSide(
              color: theme.colorScheme.outlineVariant,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: onApply,
          style: FilledButton.styleFrom(
            backgroundColor: ModuleColors.trade,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _UnderlineTabBar extends StatelessWidget {
  const _UnderlineTabBar({required this.selected, required this.onSelected});

  final _AnalysisTab selected;
  final ValueChanged<_AnalysisTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tab in _AnalysisTab.values)
              _TabItem(
                label: _label(tab),
                icon: _icon(tab),
                selected: selected == tab,
                onTap: () => onSelected(tab),
              ),
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

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        selected ? ModuleColors.trade : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? ModuleColors.trade : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({required this.tab});

  final _AnalysisTab tab;

  @override
  Widget build(BuildContext context) {
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
          Icon(Icons.construction_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            '$name analytics coming next',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
