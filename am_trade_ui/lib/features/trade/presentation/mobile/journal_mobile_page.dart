import 'dart:async';

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

class JournalMobilePage extends ConsumerStatefulWidget {
  const JournalMobilePage({
    super.key,
    this.portfolioId,
    this.embedded = false,
  });

  final String? portfolioId;
  final bool embedded;

  @override
  ConsumerState<JournalMobilePage> createState() => _JournalMobilePageState();
}

class _JournalMobilePageState extends ConsumerState<JournalMobilePage> {
  bool _showFab = true;
  Timer? _fabHideTimer;

  @override
  void initState() {
    super.initState();
    _resetFabHideTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cubit = await ref.read(journalCubitProvider.future);
      if (!mounted) return;
      cubit.loadJournalEntries();
    });
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
            ListTile(
              leading: const Icon(Icons.insights),
              title: const Text('Insights'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Journal Insights')),
                      body: JournalInsightsPage(journalCubit: cubit),
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

  @override
  Widget build(BuildContext context) {
    final cubitAsync = ref.watch(journalCubitProvider);

    return cubitAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
      data: (cubit) => BlocProvider.value(
        value: cubit,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _resetFabHideTimer(),
          onPointerMove: (_) => _resetFabHideTimer(),
          child: Scaffold(
            appBar: widget.embedded
                ? null
                : AppBar(
                    title: const Text('Trade Journal'),
                    actions: [
                      IconButton(
                        tooltip: 'Insights',
                        icon: const Icon(Icons.insights_outlined),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => Scaffold(
                                appBar: AppBar(
                                  title: const Text('Journal Insights'),
                                ),
                                body: JournalInsightsPage(journalCubit: cubit),
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Weekly review',
                        icon: const Icon(Icons.event_note_outlined),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => Scaffold(
                                appBar: AppBar(
                                  title: const Text('Weekly Review'),
                                ),
                                body: WeeklyReviewPage(journalCubit: cubit),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
            floatingActionButton: AnimatedScale(
              duration: const Duration(milliseconds: 400),
              scale: _showFab ? 1.0 : 0.0,
              child: FloatingActionButton(
                onPressed: () => _openNew(cubit),
                child: const Icon(Icons.add),
              ),
            ),
            body: BlocBuilder<JournalCubit, JournalState>(
              builder: (context, state) => state.when(
                initial: () => const SizedBox.shrink(),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (message) => Center(child: Text('Error: $message')),
                success: (_) =>
                    const Center(child: CircularProgressIndicator()),
                loaded: (entries, summary, status, folder, tags, q, setup) {
                  if (entries.isEmpty) {
                    return const Center(child: Text('No journal entries'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                            onPressed: () =>
                                cubit.removeJournalEntry(entry.id),
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
            ),
          ),
        ),
      ),
    );
  }
}
