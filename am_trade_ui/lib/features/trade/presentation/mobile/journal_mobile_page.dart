import 'dart:async';

import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../journal_providers.dart';
import '../cubit/journal/journal_cubit.dart';
import '../cubit/journal/journal_state.dart';
import '../journal/models/journal_folder_filter.dart';
import '../journal/pages/journal_insights_page.dart';
import '../journal/pages/weekly_review_page.dart';
import '../journal/widgets/journal_entry_list_view.dart';
import '../journal_template/pages/template_browser_mobile_page.dart';
import '../../internal/domain/entities/journal_entry.dart';
import 'journal/pages/journal_log_day_mobile_page.dart';
import 'journal/pages/journal_trade_workflow_mobile_page.dart';

enum _JournalMobileTab { entries, playbooks, insights, weekly }

_JournalMobileTab _journalMobileTabFromSlug(String slug) =>
    switch (slug.toLowerCase()) {
      'playbooks' || 'templates' => _JournalMobileTab.playbooks,
      'insights' => _JournalMobileTab.insights,
      'weekly' => _JournalMobileTab.weekly,
      _ => _JournalMobileTab.entries,
    };

/// Journal hub (mobile): Entries | Playbooks | Insights (| Weekly when flagged).
///
/// Log day / Trade journal open **inline** on Entries (list disappears); no new route.
class JournalMobilePage extends ConsumerStatefulWidget {
  const JournalMobilePage({
    super.key,
    this.portfolioId,
    this.embedded = false,
    this.initialTab = 'entries',
  });

  final String? portfolioId;
  final bool embedded;

  /// `entries` | `playbooks` | `insights` | `weekly` (also accepts `templates` → playbooks)
  final String initialTab;

  @override
  ConsumerState<JournalMobilePage> createState() => _JournalMobilePageState();
}

class _JournalMobilePageState extends ConsumerState<JournalMobilePage> {
  bool _showFab = true;
  Timer? _fabHideTimer;
  late _JournalMobileTab _tab;

  /// `false` Log day, `true` Trade journal — always one highlighted (web parity).
  bool _createTradeMode = true;

  /// Inline composer on Entries (replaces the list — no Navigator.push).
  bool _composerOpen = false;
  bool _composerIsTrade = true;
  JournalEntry? _composerEntry;
  int _composerNonce = 0;

  final _playbooksKey = GlobalKey<TemplateBrowserMobilePageState>();

  @override
  void initState() {
    super.initState();
    _tab = _journalMobileTabFromSlug(widget.initialTab);
    _resetFabHideTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cubit = await ref.read(journalCubitProvider.future);
      if (!mounted) return;
      cubit.setPortfolioId(widget.portfolioId, reload: false);
      cubit.loadJournalEntries();
      JournalSearchBridge.bind(
        applySearchQuery: (q) {
          if (!mounted) return;
          cubit.setFilters(searchQuery: q);
        },
      );
    });
  }

  @override
  void didUpdateWidget(covariant JournalMobilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      final next = _journalMobileTabFromSlug(widget.initialTab);
      if (next != _tab) setState(() => _tab = next);
    }
  }

  void _resetFabHideTimer() {
    if (!_showFab) setState(() => _showFab = true);
    _fabHideTimer?.cancel();
    _fabHideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _showFab) setState(() => _showFab = false);
    });
  }

  @override
  void dispose() {
    _fabHideTimer?.cancel();
    JournalSearchBridge.unbind();
    super.dispose();
  }

  Future<void> _openComposer({
    required bool trade,
    JournalEntry? entry,
  }) async {
    // Tap the already-open mode (new create) → warn then return to list.
    if (_composerOpen &&
        _composerIsTrade == trade &&
        entry == null &&
        _composerEntry == null) {
      final leave = await _confirmLeaveComposer();
      if (!leave || !mounted) return;
      setState(() {
        _composerOpen = false;
        _showFab = true;
      });
      return;
    }

    setState(() {
      _tab = _JournalMobileTab.entries;
      _createTradeMode = trade;
      _composerIsTrade = trade;
      _composerEntry = entry;
      _composerOpen = true;
      _composerNonce++;
      _showFab = false;
    });
  }

  Future<bool> _confirmLeaveComposer() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave journal?'),
        content: const Text(
          'Leave without saving? Unsaved journal work will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ModuleColors.trade,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  Future<void> _closeComposer({
    required JournalCubit cubit,
    required bool reload,
  }) async {
    setState(() {
      _composerOpen = false;
      _composerEntry = null;
      _showFab = true;
    });
    if (reload) await cubit.loadJournalEntries();
  }

  String _tabLabel(_JournalMobileTab tab) => switch (tab) {
        _JournalMobileTab.entries => 'Entries',
        _JournalMobileTab.playbooks => 'Playbooks',
        _JournalMobileTab.insights => 'Insights',
        _JournalMobileTab.weekly => 'Weekly',
      };

  bool get _weeklyReviewEnabled =>
      ref.watch(journalWeeklyReviewEnabledProvider);

  List<_JournalMobileTab> get _visibleTabs => [
        _JournalMobileTab.entries,
        _JournalMobileTab.playbooks,
        _JournalMobileTab.insights,
        if (_weeklyReviewEnabled) _JournalMobileTab.weekly,
      ];

  _JournalMobileTab get _activeTab =>
      (_tab == _JournalMobileTab.weekly && !_weeklyReviewEnabled)
          ? _JournalMobileTab.entries
          : _tab;

  @override
  Widget build(BuildContext context) {
    final cubitAsync = ref.watch(journalCubitProvider);

    return cubitAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (cubit) => BlocProvider.value(
        value: cubit,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            if (!_composerOpen) _resetFabHideTimer();
          },
          onPointerMove: (_) {
            if (!_composerOpen) _resetFabHideTimer();
          },
          child: _buildShell(context, cubit),
        ),
      ),
    );
  }

  Widget _buildShell(BuildContext context, JournalCubit cubit) {
    final showFab = _activeTab == _JournalMobileTab.entries && !_composerOpen;
    // Tabs + Log day | Trade journal stay on screen; form/list swaps beneath.
    final content = Column(
      children: [
        _buildSubnav(context, cubit),
        Expanded(child: _buildTabBody(cubit)),
      ],
    );

    final fab = showFab
        ? AnimatedScale(
            duration: const Duration(milliseconds: 400),
            scale: _showFab ? 1.0 : 0.0,
            child: FloatingActionButton.extended(
              onPressed: () => _openComposer(trade: _createTradeMode),
              backgroundColor: ModuleColors.trade,
              foregroundColor: context.colors.actionPrimaryFg,
              icon: Icon(
                _createTradeMode
                    ? Icons.candlestick_chart_outlined
                    : Icons.add_rounded,
              ),
              label: Text(_createTradeMode ? 'Trade journal' : 'Log day'),
            ),
          )
        : null;

    if (widget.embedded) {
      final navReserve = PlatformConstants.globalBottomNavReserve(context);
      return Stack(
        children: [
          content,
          if (fab != null)
            ValueListenableBuilder<double>(
              valueListenable: GlobalBottomNavVisibility.factor,
              builder: (context, navFactor, _) {
                final t = navFactor.clamp(0.0, 1.0);
                final fabBottom = AppSpacing.sm + (navReserve * t);
                return Positioned(
                  right: AppSpacing.md,
                  bottom: fabBottom,
                  child: fab,
                );
              },
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Trade Journal')),
      floatingActionButton: fab,
      body: content,
    );
  }

  Widget _buildSubnav(BuildContext context, JournalCubit cubit) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + AppSpacing.xs,
                vertical: AppSpacing.sm - AppSpacing.xxs,
              ),
              itemCount: _visibleTabs.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.sm - AppSpacing.xxs),
              itemBuilder: (context, i) {
                final tab = _visibleTabs[i];
                final selected = _activeTab == tab;
                return FilterChip(
                  label: Text(
                    _tabLabel(tab),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? ModuleColors.trade
                              : colors.textSecondary,
                        ),
                  ),
                  selected: selected,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  selectedColor: ModuleColors.trade.withValues(alpha: 0.16),
                  backgroundColor: colors.cardSurface,
                  side: BorderSide(
                    color: selected
                        ? ModuleColors.trade.withValues(alpha: 0.45)
                        : colors.border.withValues(alpha: 0.4),
                  ),
                  onSelected: (_) async {
                    if (tab == _activeTab) return;
                    if (_composerOpen && tab != _JournalMobileTab.entries) {
                      final leave = await _confirmLeaveComposer();
                      if (!leave || !mounted) return;
                    }
                    if (_activeTab == _JournalMobileTab.playbooks &&
                        (_playbooksKey.currentState?.isUsingTemplateInline ??
                            false)) {
                      final leave = await _playbooksKey.currentState!
                          .confirmLeaveInlineUse();
                      if (!leave || !mounted) return;
                    }
                    setState(() {
                      _tab = tab;
                      if (tab != _JournalMobileTab.entries && _composerOpen) {
                        _composerOpen = false;
                        _composerEntry = null;
                        _showFab = true;
                      }
                    });
                    if (tab == _JournalMobileTab.entries) {
                      cubit.setFilters(status: 'ALL', reload: true);
                    }
                  },
                );
              },
            ),
          ),
          if (_activeTab == _JournalMobileTab.entries)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: JournalCreateModeToggle(
                selected: _createTradeMode,
                onLogDay: () => _openComposer(trade: false),
                onTradeJournal: () => _openComposer(trade: true),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBody(JournalCubit cubit) {
    return IndexedStack(
      index: _activeTab.index,
      children: [
        // Entries: list OR form directly under the Log day | Trade journal toggle.
        _composerOpen ? _buildInlineComposer(cubit) : _buildEntries(cubit),
        TemplateBrowserMobilePage(
          key: _playbooksKey,
          embedded: true,
          onTemplateSelected: (_) async {
            await cubit.loadJournalEntries();
            if (!mounted) return;
            await _openComposer(trade: true);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Playbook applied — continue below'),
                backgroundColor: ModuleColors.trade,
              ),
            );
          },
        ),
        JournalInsightsPage(journalCubit: cubit),
        WeeklyReviewPage(journalCubit: cubit),
      ],
    );
  }

  Future<void> _confirmDeleteEntry(
    JournalCubit cubit,
    JournalEntry entry,
    bool isTrade,
  ) async {
    final title = entry.title.trim().isNotEmpty
        ? entry.title.trim()
        : (entry.symbol?.trim().isNotEmpty == true
            ? entry.symbol!.trim()
            : 'Untitled');
    final kind = isTrade ? 'Trade journal' : 'Log';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
          backgroundColor: colors.cardSurface,
          title: Text('Delete $kind?'),
          content: Text('“$title” will be permanently removed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: colors.statusError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    await cubit.removeJournalEntry(entry.id);
  }

  /// Form only — no second page chrome. Toggle above stays from [_buildSubnav].
  Widget _buildInlineComposer(JournalCubit cubit) {
    return KeyedSubtree(
      key: ValueKey('composer-$_composerNonce-$_composerIsTrade'),
      child: _composerIsTrade
          ? JournalTradeWorkflowMobilePage(
              journalCubit: cubit,
              portfolioId: widget.portfolioId,
              initialEntry: _composerEntry,
              embedded: true,
              onDone: () => _closeComposer(cubit: cubit, reload: true),
              onCancel: () => _closeComposer(cubit: cubit, reload: false),
            )
          : JournalLogDayMobilePage(
              journalCubit: cubit,
              portfolioId: widget.portfolioId,
              initialEntry: _composerEntry,
              embedded: true,
              onDone: () => _closeComposer(cubit: cubit, reload: true),
              onCancel: () => _closeComposer(cubit: cubit, reload: false),
            ),
    );
  }

  Widget _buildEntries(JournalCubit cubit) {
    final colors = context.colors;
    return BlocBuilder<JournalCubit, JournalState>(
      builder: (context, state) => state.when(
        initial: () => const SizedBox.shrink(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (message) => Center(child: Text('Error: $message')),
        success: (_) => const Center(child: CircularProgressIndicator()),
        loaded: (entries, summary, adherence, status, folder, tags, q, setup) {
          if (entries.isEmpty) {
            return _EmptyMobileEntries(
              onLogDay: () => _openComposer(trade: false),
              onTradeJournal: () => _openComposer(trade: true),
            );
          }
          final bottomPad =
              PlatformConstants.globalBottomNavReserve(context) + 72;
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              bottomPad,
            ),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isTrade =
                  JournalFolderFilter.shouldOpenTradeWorkflow(entry);
              final title = (entry.title.trim().isNotEmpty)
                  ? entry.title
                  : (entry.symbol?.trim().isNotEmpty == true
                      ? entry.symbol!
                      : 'Untitled');
              final subtitle = entry.postTradeReview?.lessonLearned ??
                  entry.setup ??
                  entry.content;
              final locale = Localizations.localeOf(context).toString();
              final dateLabel =
                  DateFormat('MMM d, yyyy', locale).format(entry.entryDate);
              final status = (entry.journalStatus ?? '').trim();

              return Material(
                color: colors.surface.withValues(alpha: 0.55),
                borderRadius: AppRadii.input,
                child: InkWell(
                  borderRadius: AppRadii.input,
                  onTap: () => _openComposer(trade: isTrade, entry: entry),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm + AppSpacing.xs,
                      AppSpacing.sm + AppSpacing.xxs,
                      AppSpacing.xs,
                      AppSpacing.sm + AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: AppRadii.input,
                      border: Border.all(
                        color: colors.border.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  _EntryTypeChip(
                                    label: isTrade ? 'Trade journal' : 'Log',
                                    trade: isTrade,
                                  ),
                                  if (status.isNotEmpty)
                                    _EntryTypeChip(
                                      label: status.toUpperCase(),
                                      trade: false,
                                      muted: true,
                                    ),
                                ],
                              ),
                              if (subtitle != null &&
                                  subtitle.trim().isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  subtitle.trim(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: colors.textSecondary),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                dateLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: colors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: Icon(
                            Icons.delete_outline,
                            color: colors.textSecondary,
                          ),
                          onPressed: () =>
                              _confirmDeleteEntry(cubit, entry, isTrade),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EntryTypeChip extends StatelessWidget {
  const _EntryTypeChip({
    required this.label,
    required this.trade,
    this.muted = false,
  });

  final String label;
  final bool trade;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent =
        ModuleColorProvider.maybeOf(context) ?? ModuleColors.trade;
    final bg = muted
        ? colors.border.withValues(alpha: 0.25)
        : trade
            ? accent.withValues(alpha: 0.14)
            : colors.statusNeutral.withValues(alpha: 0.18);
    final fg = muted
        ? colors.textSecondary
        : trade
            ? accent
            : colors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm - AppSpacing.xxs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.chip,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _EmptyMobileEntries extends StatelessWidget {
  const _EmptyMobileEntries({
    required this.onLogDay,
    required this.onTradeJournal,
  });

  final VoidCallback onLogDay;
  final VoidCallback onTradeJournal;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 40, color: colors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No journal entries yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Start with a Log day note or a Trade journal.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            JournalCreateModeToggle(
              selected: true,
              onLogDay: onLogDay,
              onTradeJournal: onTradeJournal,
            ),
          ],
        ),
      ),
    );
  }
}
