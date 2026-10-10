import 'dart:async';

import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../journal_providers.dart';
import '../cubit/journal/journal_cubit.dart';
import '../cubit/journal/journal_state.dart';
import '../journal/pages/journal_insights_page.dart';
import '../journal/pages/trade_journal_workflow_page.dart';
import '../journal/pages/simple_journal_note_page.dart';
import '../journal/pages/weekly_review_page.dart';
import '../journal_template/pages/template_browser_page.dart';

enum _JournalMobileTab { entries, playbooks, insights, weekly }

_JournalMobileTab _journalMobileTabFromSlug(String slug) =>
    switch (slug.toLowerCase()) {
      'playbooks' || 'templates' => _JournalMobileTab.playbooks,
      'insights' => _JournalMobileTab.insights,
      'weekly' => _JournalMobileTab.weekly,
      _ => _JournalMobileTab.entries,
    };

/// Journal hub (mobile): Entries | Playbooks | Insights | Weekly — mirrors web.
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

  @override
  void initState() {
    super.initState();
    _tab = _journalMobileTabFromSlug(widget.initialTab);
    _resetFabHideTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cubit = await ref.read(journalCubitProvider.future);
      if (!mounted) return;
      cubit.loadJournalEntries();
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
    super.dispose();
  }

  void _openNew(JournalCubit cubit) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.candlestick_chart),
              title: const Text('Trade Journal'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TradeJournalWorkflowPage(
                      journalCubit: cubit,
                      portfolioId: widget.portfolioId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notes),
              title: const Text('Daily Note'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SimpleJournalNotePage(
                      journalCubit: cubit,
                      entryType: 'DAILY',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Missed Trade'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SimpleJournalNotePage(
                      journalCubit: cubit,
                      entryType: 'MISSED',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _tabLabel(_JournalMobileTab tab) => switch (tab) {
        _JournalMobileTab.entries => 'Entries',
        _JournalMobileTab.playbooks => 'Playbooks',
        _JournalMobileTab.insights => 'Insights',
        _JournalMobileTab.weekly => 'Weekly',
      };

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
          onPointerDown: (_) => _resetFabHideTimer(),
          onPointerMove: (_) => _resetFabHideTimer(),
          child: _buildShell(context, cubit),
        ),
      ),
    );
  }

  Widget _buildShell(BuildContext context, JournalCubit cubit) {
    final content = Column(
      children: [
        _buildSubnav(context, cubit),
        Expanded(child: _buildTabBody(cubit)),
      ],
    );

    final fab = _tab == _JournalMobileTab.entries
        ? AnimatedScale(
            duration: const Duration(milliseconds: 400),
            scale: _showFab ? 1.0 : 0.0,
            child: FloatingActionButton(
              onPressed: () => _openNew(cubit),
              child: const Icon(Icons.add),
            ),
          )
        : null;

    if (widget.embedded) {
      // Sit above the floating global bottom nav so the FAB does not overlap chrome.
      final fabBottom =
          PlatformConstants.globalBottomNavReserve(context) + AppSpacing.sm;
      return Stack(
        children: [
          content,
          if (fab != null)
            Positioned(
              right: AppSpacing.md,
              bottom: fabBottom,
              child: fab,
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
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            for (final tab in _JournalMobileTab.values) ...[
              if (tab.index > 0) const SizedBox(width: AppSpacing.sm),
              ChoiceChip(
                label: Text(_tabLabel(tab)),
                selected: _tab == tab,
                onSelected: (_) {
                  setState(() => _tab = tab);
                  if (tab == _JournalMobileTab.entries) {
                    cubit.setFilters(status: 'ALL', reload: true);
                  }
                },
                selectedColor: ModuleColors.trade.withValues(alpha: 0.25),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabBody(JournalCubit cubit) {
    return IndexedStack(
      index: _tab.index,
      children: [
        _buildEntries(cubit),
        TemplateBrowserPage(
          embedded: true,
          onTemplateSelected: (_) async {
            await cubit.loadJournalEntries();
            if (!mounted) return;
            setState(() => _tab = _JournalMobileTab.entries);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Playbook applied — continue in Entries'),
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

  Widget _buildEntries(JournalCubit cubit) {
    return BlocBuilder<JournalCubit, JournalState>(
      builder: (context, state) => state.when(
        initial: () => const SizedBox.shrink(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (message) => Center(child: Text('Error: $message')),
        success: (_) => const Center(child: CircularProgressIndicator()),
        loaded: (entries, summary, status, folder, tags, q, setup) {
          if (entries.isEmpty) {
            return const Center(child: Text('No journal entries'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: entries.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.sm + 4),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                child: ListTile(
                  title: Text(entry.symbol ?? entry.title),
                  subtitle: Text(
                    entry.postTradeReview?.lessonLearned ??
                        entry.setup ??
                        entry.journalStatus ??
                        '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => cubit.removeJournalEntry(entry.id),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TradeJournalWorkflowPage(
                          journalCubit: cubit,
                          initialEntry: entry,
                          portfolioId: widget.portfolioId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
