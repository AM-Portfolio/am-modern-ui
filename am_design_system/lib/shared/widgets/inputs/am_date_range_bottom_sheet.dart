import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_type_scale.dart';
import '../../../core/theme/color_extensions.dart';
import '../buttons/app_button.dart';
import 'am_toggle_chip.dart';

/// Result of [AmDateRangeBottomSheet.show].
class AmDateRangeResult {
  const AmDateRangeResult({
    required this.range,
    this.presetLabel,
  });

  final DateTimeRange range;
  final String? presetLabel;
}

enum _SheetMode { presets, custom }

/// Mobile date-range sheet (Presets / Custom + calendar).
///
/// Theme-only surfaces: [context.colors], [AppRadii], [AppSpacing], [AppButton],
/// [AmToggleChip]. Pass [accentColor] for module accent (e.g. Trade).
///
/// No auth/user identifiers — only local calendar selection.
class AmDateRangeBottomSheet extends StatefulWidget {
  const AmDateRangeBottomSheet({
    super.key,
    this.initialRange,
    this.accentColor,
    this.allTimeRange,
  });

  final DateTimeRange? initialRange;
  final Color? accentColor;

  /// When set, "All time" uses this range (e.g. [TimeFrame.all.dateRange]).
  final DateTimeRange? allTimeRange;

  /// Shows the sheet and returns the confirmed range, or null if dismissed.
  static Future<AmDateRangeResult?> show(
    BuildContext context, {
    DateTimeRange? initialRange,
    Color? accentColor,
    DateTimeRange? allTimeRange,
  }) {
    final colors = context.colors;
    return showModalBottomSheet<AmDateRangeResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      backgroundColor: colors.cardSurface,
      barrierColor: colors.textPrimary.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (ctx) => AmDateRangeBottomSheet(
        initialRange: initialRange,
        accentColor: accentColor,
        allTimeRange: allTimeRange,
      ),
    );
  }

  @override
  State<AmDateRangeBottomSheet> createState() => _AmDateRangeBottomSheetState();
}

class _AmDateRangeBottomSheetState extends State<AmDateRangeBottomSheet> {
  _SheetMode _mode = _SheetMode.presets;
  late DateTime _displayedMonth;
  DateTime? _start;
  DateTime? _end;
  String? _presetLabel;
  bool _pickingStart = true;

  Color get _accent => widget.accentColor ?? context.colors.actionPrimaryBg;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initial = widget.initialRange;
    _start = initial == null ? null : _dateOnly(initial.start);
    _end = initial == null ? null : _dateOnly(initial.end);
    _displayedMonth = _end ?? _start ?? DateTime(now.year, now.month);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  List<({String label, DateTimeRange Function() range})> get _presets {
    final today = _today();
    final now = DateTime.now();
    return [
      (
        label: 'Today',
        range: () => DateTimeRange(start: today, end: today),
      ),
      (
        label: 'Last 7 days',
        range: () => DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        ),
      ),
      (
        label: 'Last 30 days',
        range: () => DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: today,
        ),
      ),
      (
        label: 'This month',
        range: () => DateTimeRange(
          start: DateTime(now.year, now.month),
          end: today,
        ),
      ),
      (
        label: 'Last month',
        range: () {
          final firstOfCurrent = DateTime(now.year, now.month);
          final lastOfPrev =
              firstOfCurrent.subtract(const Duration(days: 1));
          final firstOfPrev = DateTime(lastOfPrev.year, lastOfPrev.month);
          return DateTimeRange(start: firstOfPrev, end: lastOfPrev);
        },
      ),
      (
        label: 'Year to date',
        range: () => DateTimeRange(start: DateTime(now.year), end: today),
      ),
      (
        label: 'All time',
        range: () {
          final all = widget.allTimeRange;
          if (all != null) {
            return DateTimeRange(
              start: _dateOnly(all.start),
              end: _dateOnly(all.end),
            );
          }
          return DateTimeRange(
            start: DateTime(now.year - 20, now.month, now.day),
            end: today,
          );
        },
      ),
    ];
  }

  void _applyPreset(String label, DateTimeRange range) {
    setState(() {
      _presetLabel = label;
      _start = _dateOnly(range.start);
      _end = _dateOnly(range.end);
      _displayedMonth = DateTime(_end!.year, _end!.month);
      _pickingStart = true;
    });
  }

  void _onDayTap(DateTime day) {
    setState(() {
      _presetLabel = null;
      if (_pickingStart || _start == null) {
        _start = day;
        if (_end != null && _end!.isBefore(day)) _end = null;
        _pickingStart = false;
      } else if (day.isBefore(_start!)) {
        _start = day;
        _end = null;
        _pickingStart = false;
      } else {
        _end = day;
      }
      _mode = _SheetMode.custom;
    });
  }

  void _clear() {
    setState(() {
      _start = null;
      _end = null;
      _presetLabel = null;
      _pickingStart = true;
    });
  }

  void _apply() {
    if (_start == null) return;
    final end = _end ?? _start!;
    final range = end.isBefore(_start!)
        ? DateTimeRange(start: end, end: _start!)
        : DateTimeRange(start: _start!, end: end);
    Navigator.of(context).pop(
      AmDateRangeResult(range: range, presetLabel: _presetLabel),
    );
  }

  DateFormat _dateFmt(BuildContext context) =>
      DateFormat('MMM d, yyyy', Localizations.localeOf(context).toString());

  DateFormat _monthFmt(BuildContext context) =>
      DateFormat('MMMM yyyy', Localizations.localeOf(context).toString());

  String _formatPresetRange(BuildContext context, DateTimeRange r) {
    final fmt = _dateFmt(context);
    if (_isSameDay(r.start, r.end)) return fmt.format(r.start);
    return '${fmt.format(r.start)} – ${fmt.format(r.end)}';
  }

  String _summaryText(BuildContext context) {
    if (_start == null) return 'Select a start date';
    final fmt = _dateFmt(context);
    final end = _end ?? _start!;
    final days = end.difference(_start!).inDays.abs() + 1;
    return '${fmt.format(_start!)} – ${fmt.format(end)} ($days '
        '${days == 1 ? 'day' : 'days'})';
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final media = MediaQuery.of(context);
    // Bound height so [Expanded] is valid; reserve floating bottom nav.
    final maxH = media.size.height * 0.92;
    final bottomInset = PlatformConstants.globalBottomNavReserve(context);

    return SizedBox(
      height: maxH,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md + bottomInset,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.border.withValues(alpha: 0.6),
                  borderRadius: AppRadii.chip,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select date range',
                    style: context.text.sectionTitle(compact: true).copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: colors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                AmToggleChip(
                  label: 'Presets',
                  selected: _mode == _SheetMode.presets,
                  filled: true,
                  compact: true,
                  accentColor: _accent,
                  onTap: () => setState(() => _mode = _SheetMode.presets),
                ),
                const SizedBox(width: AppSpacing.sm),
                AmToggleChip(
                  label: 'Custom',
                  selected: _mode == _SheetMode.custom,
                  filled: true,
                  compact: true,
                  accentColor: _accent,
                  onTap: () => setState(() => _mode = _SheetMode.custom),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_mode == _SheetMode.presets) ...[
                      _buildPresetsList(context),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _buildCalendar(context),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _summaryText(context),
                    style: context.text.caption(compact: true).copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                AppButton(
                  text: 'Clear',
                  type: AppButtonType.text,
                  onPressed: _clear,
                  height: 36,
                  textColor: colors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              text: 'Apply',
              type: AppButtonType.primary,
              onPressed: _start == null ? null : _apply,
              height: 44,
              backgroundColor: _accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetsList(BuildContext context) {
    final colors = context.colors;
    final presets = _presets;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.55),
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < presets.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: colors.border.withValues(alpha: 0.35),
              ),
            Builder(
              builder: (context) {
                final preset = presets[i];
                final range = preset.range();
                return _PresetRow(
                  label: preset.label,
                  rangeLabel: _formatPresetRange(context, range),
                  selected: _presetLabel == preset.label,
                  accent: _accent,
                  onTap: () => _applyPreset(preset.label, range),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final colors = context.colors;
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstWeekday = DateTime(year, month, 1).weekday % 7; // Su=0
    final today = _today();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: () => setState(() {
                  _displayedMonth = DateTime(year, month - 1);
                }),
                icon: Icon(Icons.chevron_left, color: colors.textSecondary),
              ),
              Expanded(
                child: Text(
                  _monthFmt(context).format(_displayedMonth),
                  textAlign: TextAlign.center,
                  style: context.text.label(compact: true).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: AppTypeScale.md,
                      ),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: () => setState(() {
                  _displayedMonth = DateTime(year, month + 1);
                }),
                icon: Icon(Icons.chevron_right, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final d in const [
                'Su',
                'Mo',
                'Tu',
                'We',
                'Th',
                'Fr',
                'Sa',
              ])
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: context.text.caption(compact: true).copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemBuilder: (context, index) {
              final dayNum = index - firstWeekday + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox.shrink();
              }
              final date = DateTime(year, month, dayNum);
              final isFuture = date.isAfter(today);
              final isStart = _start != null && _isSameDay(date, _start!);
              final isEnd = _end != null && _isSameDay(date, _end!);
              final inRange = _start != null &&
                  _end != null &&
                  date.isAfter(_start!) &&
                  date.isBefore(_end!);

              Color? bg;
              Color fg = colors.textPrimary;
              BorderRadius? radius;

              if (isStart || isEnd) {
                bg = _accent;
                fg = colors.actionPrimaryFg;
                radius = AppRadii.chip;
              } else if (inRange) {
                bg = _accent.withValues(alpha: 0.14);
              } else if (isFuture) {
                fg = colors.textSecondary.withValues(alpha: 0.35);
              }

              return Material(
                color: bg ?? colors.cardSurface.withValues(alpha: 0),
                borderRadius: radius ?? AppRadii.button,
                child: InkWell(
                  onTap: isFuture ? null : () => _onDayTap(date),
                  borderRadius: radius ?? AppRadii.button,
                  child: Semantics(
                    button: true,
                    enabled: !isFuture,
                    label: _dateFmt(context).format(date),
                    selected: isStart || isEnd,
                    child: Center(
                      child: Text(
                        '$dayNum',
                        style: context.text.label(compact: true).copyWith(
                              color: fg,
                              fontWeight: (isStart || isEnd)
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.label,
    required this.rangeLabel,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String rangeLabel;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected
          ? accent.withValues(alpha: 0.10)
          : colors.cardSurface.withValues(alpha: 0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.text.label(compact: true).copyWith(
                        color: selected ? accent : colors.textPrimary,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ),
              Text(
                rangeLabel,
                style: context.text.caption(compact: true).copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
