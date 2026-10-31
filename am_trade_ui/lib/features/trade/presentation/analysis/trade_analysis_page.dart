import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../internal/domain/entities/metrics/metrics_filter_request.dart';
import '../../internal/domain/enums/metric_types.dart';
import '../../providers/trade_metrics_providers.dart';
import 'tabs/timing_analysis_tab.dart';

enum _AnalysisTab { timing, strategy, direction, holding, risk }

/// Trade module accent — prefers [ModuleColorProvider], falls back to
/// [ModuleColors.trade] (brand-synced).
Color _analysisAccent(BuildContext context) =>
    ModuleColorProvider.maybeOf(context) ?? ModuleColors.trade;

/// Analysis hub — Timing-first edge analytics.
///
/// Surfaces/text/status from [context.colors]; accents via [_analysisAccent].
/// Mobile: Style + date chip + Apply. Desktop: wrap header + compact dialog.
class TradeAnalysisPage extends ConsumerStatefulWidget {
  const TradeAnalysisPage({
    super.key,
    required this.portfolioId,
    this.onOpenCalendar,
    this.onOpenJournalInsights,
    this.embedded = false,
  });

  final String portfolioId;
  final VoidCallback? onOpenCalendar;
  final VoidCallback? onOpenJournalInsights;

  /// When true (mobile tab body), skip outer [Scaffold] to avoid nesting.
  final bool embedded;

  @override
  ConsumerState<TradeAnalysisPage> createState() => _TradeAnalysisPageState();
}

class _TradeAnalysisPageState extends ConsumerState<TradeAnalysisPage> {
  _AnalysisTab _tab = _AnalysisTab.timing;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _usingAllTime = true;
  String? _holdingStyle;

  /// Backend holding-style keys only — never forward arbitrary UI strings.
  static const _allowedHoldingStyles = {'SCALPER', 'INTRADAY', 'SWING'};

  static DateTimeRange get _allTimeRange {
    final range = TimeFrame.all.dateRange;
    return DateTimeRange(start: range.start, end: range.end);
  }

  String? _sanitizeHoldingStyle(String? style) {
    if (style == null || style.isEmpty) return null;
    final key = style.trim().toUpperCase();
    return _allowedHoldingStyles.contains(key) ? key : null;
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
    try {
      final resolved = await ref.read(tradeMetricsCubitProvider.future);
      if (!mounted) return;
      if (widget.portfolioId.trim().isEmpty) return;
      resolved.loadMetrics(
        MetricsFilterRequest(
          portfolioIds: [widget.portfolioId],
          startDate: _startDate,
          endDate: _endDate,
          metricTypes: const [
            MetricTypes.performance,
            MetricTypes.distribution,
          ],
          holdingStyle: _sanitizeHoldingStyle(_holdingStyle),
        ),
      );
    } catch (_) {
      // Cubit/error UI owns failure presentation — never surface internals here.
      if (!mounted) return;
    }
  }

  void _onHoldingStyleChanged(String? style, {bool autoLoad = true}) {
    setState(() => _holdingStyle = _sanitizeHoldingStyle(style));
    if (autoLoad) _loadMetrics();
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

  Future<void> _pickDateRange({required bool mobile}) async {
    final colors = context.colors;
    final accent = _analysisAccent(context);
    final initial = DateTimeRange(start: _startDate, end: _endDate);
    final all = _allTimeRange;

    DateTimeRange? picked;
    if (mobile) {
      final result = await AmDateRangeBottomSheet.show(
        context,
        initialRange: initial,
        accentColor: accent,
        allTimeRange: all,
      );
      picked = result?.range;
    } else {
      picked = await showDialog<DateTimeRange>(
        context: context,
        builder: (ctx) {
          return Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: Theme.of(ctx).colorScheme.copyWith(
                    primary: accent,
                    onPrimary: colors.actionPrimaryFg,
                  ),
            ),
            child: CompactDateRangePickerDialog(initialDateRange: initial),
          );
        },
      );
    }
    if (picked == null || !mounted) return;

    final choseAllTime = _isSameCalendarDay(picked.start, all.start) &&
        _isSameCalendarDay(picked.end, all.end);

    setState(() {
      _startDate = picked!.start;
      _endDate = picked.end;
      _usingAllTime = choseAllTime;
    });
    // Mobile: home Apply loads. Desktop: apply immediately after pick.
    if (!mobile) await _loadMetrics();
  }

  static bool _isSameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateLabel(BuildContext context) {
    if (_usingAllTime) return 'All time';
    final locale = Localizations.localeOf(context).toString();
    final sameYear = _startDate.year == _endDate.year;
    final short = sameYear ? 'MMM d' : 'MMM d, yyyy';
    final fmt = DateFormat(short, locale);
    return '${fmt.format(_startDate)} – ${fmt.format(_endDate)}';
  }

  void _showExportUnavailable() {
    final colors = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Metrics export is not available yet. Use Journal → Export CSV for journal data.',
          style: context.text.body(compact: true).copyWith(
                color: colors.actionPrimaryFg,
              ),
        ),
        backgroundColor: colors.textPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _useMobileChrome(BoxConstraints constraints) =>
      widget.embedded ||
      DeviceUtils.isMobile(context) ||
      constraints.maxWidth < 720;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = _analysisAccent(context);
    final cubitAsync = ref.watch(tradeMetricsCubitProvider);

    final body = LayoutBuilder(
      builder: (context, constraints) {
        final mobile = _useMobileChrome(constraints);
        // Inherit parent scaffold when embedded (Trade mobile/web shell).
        final content = Padding(
          padding: EdgeInsets.fromLTRB(
            mobile ? AppSpacing.md : AppSpacing.lg,
            AppSpacing.md,
            mobile ? AppSpacing.md : AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (mobile)
                _MobileAnalysisChrome(
                  tab: _tab,
                  onTabSelected: (tab) => setState(() => _tab = tab),
                  holdingStyle: _holdingStyle,
                  onHoldingStyleChanged: (style) =>
                      _onHoldingStyleChanged(style, autoLoad: false),
                  dateLabel: _dateLabel(context),
                  onPickDateRange: () => _pickDateRange(mobile: true),
                  onApply: _loadMetrics,
                  accent: accent,
                )
              else
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: AppSpacing.md,
                  children: [
                    _AnalysisTabBar(
                      selected: _tab,
                      onSelected: (tab) => setState(() => _tab = tab),
                      filled: false,
                      accent: accent,
                    ),
                    Wrap(
                      spacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (_tab == _AnalysisTab.timing) ...[
                          _HoldingStyleFilter(
                            selected: _holdingStyle,
                            onChanged: _onHoldingStyleChanged,
                            filled: false,
                            stacked: false,
                            accent: accent,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        _DateApplyBar(
                          dateLabel: _dateLabel(context),
                          usingAllTime: _usingAllTime,
                          onPickDateRange: () =>
                              _pickDateRange(mobile: false),
                          onResetAllTime: _resetToAllTime,
                          onApply: _loadMetrics,
                          onRefresh: _loadMetrics,
                          onDownload: _showExportUnavailable,
                          compactIcons: false,
                          accent: accent,
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: cubitAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(color: accent),
                  ),
                  error: (_, __) => AmErrorWidget(
                    message: 'Could not load metrics. Please try again.',
                    onRetry: _loadMetrics,
                  ),
                  data: (cubit) {
                    if (_tab == _AnalysisTab.timing) {
                      return TimingAnalysisTab(
                        cubit: cubit,
                        onApply: _loadMetrics,
                        compact: mobile,
                        accent: accent,
                      );
                    }
                    return _ComingSoonTab(tab: _tab);
                  },
                ),
              ),
            ],
          ),
        );

        if (widget.embedded) return content;

        return ColoredBox(
          color: colors.scaffoldBackground,
          child: content,
        );
      },
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: colors.scaffoldBackground,
      body: body,
    );
  }
}

/// Mobile Metrics chrome: tabs → Style dropdown + Date chip + Apply.
class _MobileAnalysisChrome extends StatelessWidget {
  const _MobileAnalysisChrome({
    required this.tab,
    required this.onTabSelected,
    required this.holdingStyle,
    required this.onHoldingStyleChanged,
    required this.dateLabel,
    required this.onPickDateRange,
    required this.onApply,
    required this.accent,
  });

  final _AnalysisTab tab;
  final ValueChanged<_AnalysisTab> onTabSelected;
  final String? holdingStyle;
  final ValueChanged<String?> onHoldingStyleChanged;
  final String dateLabel;
  final VoidCallback onPickDateRange;
  final VoidCallback onApply;
  final Color accent;

  /// Dropdown uses '' for All so [CustomDropdown] always has a non-null value.
  static const _styleOptions = <({String label, String key})>[
    (label: 'All', key: ''),
    (label: 'Scalper', key: 'SCALPER'),
    (label: 'Intraday', key: 'INTRADAY'),
    (label: 'Swing', key: 'SWING'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styleKey = holdingStyle ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AnalysisTabBar(
          selected: tab,
          onSelected: onTabSelected,
          filled: true,
          bare: true,
          accent: accent,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            if (tab == _AnalysisTab.timing) ...[
              Expanded(
                flex: 3,
                child: CustomDropdown<String>(
                  value: styleKey,
                  hint: 'Style',
                  height: 40,
                  fontSize: AppTypeScale.md,
                  borderRadius: AppRadii.sm,
                  primaryColor: accent,
                  backgroundColor: colors.cardSurface,
                  menuBackgroundColor: colors.cardSurface,
                  borderColor: colors.border.withValues(alpha: 0.45),
                  textColor: colors.textPrimary,
                  items: [
                    for (final o in _styleOptions)
                      DropdownMenuItem<String>(
                        value: o.key,
                        child: Text(o.label),
                      ),
                  ],
                  onChanged: (key) {
                    if (key == null) return;
                    onHoldingStyleChanged(key.isEmpty ? null : key);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              flex: 4,
              child: _DateRangeChip(
                label: dateLabel,
                onTap: onPickDateRange,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton(
              text: 'Apply',
              type: AppButtonType.primary,
              onPressed: onApply,
              height: 40,
              backgroundColor: accent,
            ),
          ],
        ),
      ],
    );
  }
}

class _DateRangeChip extends StatelessWidget {
  const _DateRangeChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.button,
        side: BorderSide(color: colors.border.withValues(alpha: 0.45)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.button,
        child: SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.label(compact: true).copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
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
    required this.onRefresh,
    required this.onDownload,
    required this.accent,
    this.compactIcons = false,
  });

  final String dateLabel;
  final bool usingAllTime;
  final VoidCallback onPickDateRange;
  final VoidCallback onResetAllTime;
  final VoidCallback onApply;
  final VoidCallback onRefresh;
  final VoidCallback onDownload;
  final Color accent;
  final bool compactIcons;

  Widget _iconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    final colors = context.colors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.button,
          side: BorderSide(color: colors.border.withValues(alpha: 0.45)),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadii.button,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: colors.textSecondary),
          ),
        ),
      ),
    );
  }

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
            textColor: accent,
          ),
        AppButton(
          text: 'Apply',
          type: AppButtonType.primary,
          onPressed: onApply,
          height: 36,
          backgroundColor: accent,
        ),
        if (compactIcons) ...[
          _iconButton(
            context,
            icon: Icons.refresh,
            onPressed: onRefresh,
            tooltip: 'Refresh',
          ),
          _iconButton(
            context,
            icon: Icons.download_outlined,
            onPressed: onDownload,
            tooltip: 'Download',
          ),
        ] else ...[
          AppButton(
            text: '',
            icon: Icons.refresh,
            type: AppButtonType.secondary,
            isOutlined: true,
            onPressed: onRefresh,
            height: 36,
          ),
          AppButton(
            text: '',
            icon: Icons.download_outlined,
            type: AppButtonType.secondary,
            isOutlined: true,
            onPressed: onDownload,
            height: 36,
          ),
        ],
      ],
    );
  }
}

class _HoldingStyleFilter extends StatelessWidget {
  const _HoldingStyleFilter({
    required this.selected,
    required this.onChanged,
    required this.accent,
    this.filled = false,
    this.stacked = false,
  });

  final String? selected;
  final ValueChanged<String?> onChanged;
  final Color accent;
  final bool filled;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget pill(String label, String? value) {
      return AmToggleChip(
        label: label,
        selected: selected == value,
        compact: true,
        filled: filled,
        accentColor: accent,
        onTap: () => onChanged(value),
      );
    }

    final pills = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        pill('All', null),
        pill('Scalper <15m', 'SCALPER'),
        pill('Intraday 15m–24h', 'INTRADAY'),
        pill('Swing ≥24h', 'SWING'),
      ],
    );

    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stacked ? 'Holding style' : 'Holding style:',
          style: context.text.label(compact: true).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (stacked) ...[
          const SizedBox(width: AppSpacing.xs),
          Tooltip(
            message:
                'Inferred from hold time: Scalper <15m, Intraday 15m–24h, Swing ≥24h',
            child: Icon(
              Icons.info_outline,
              size: 14,
              color: colors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );

    if (!stacked) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          label,
          const SizedBox(width: AppSpacing.sm),
          pills,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label,
        const SizedBox(height: AppSpacing.sm),
        pills,
      ],
    );
  }
}

class _AnalysisTabBar extends StatelessWidget {
  const _AnalysisTabBar({
    required this.selected,
    required this.onSelected,
    required this.accent,
    this.filled = false,
    this.bare = false,
  });

  final _AnalysisTab selected;
  final ValueChanged<_AnalysisTab> onSelected;
  final Color accent;
  final bool filled;

  /// When true, chips sit directly on the page (no card chrome) — mobile mock.
  final bool bare;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final chips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in _AnalysisTab.values) ...[
            if (tab.index > 0) const SizedBox(width: AppSpacing.sm),
            AmToggleChip(
              label: _label(tab),
              selected: selected == tab,
              compact: true,
              filled: filled,
              accentColor: accent,
              onTap: () => onSelected(tab),
            ),
          ],
        ],
      ),
    );

    if (bare) return chips;

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
      child: chips,
    );
  }

  String _label(_AnalysisTab tab) => switch (tab) {
        _AnalysisTab.timing => 'Timing',
        _AnalysisTab.strategy => 'Strategy',
        _AnalysisTab.direction => 'Direction',
        _AnalysisTab.holding => 'Holding',
        _AnalysisTab.risk => 'Risk',
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
            style: context.text.sectionTitle(compact: true).copyWith(
                  color: colors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
