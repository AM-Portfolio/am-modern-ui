import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import '../../../internal/domain/entities/notebook_item.dart';
import '../../../internal/domain/enums/notebook_item_type.dart';
import '../../../journal_providers.dart';
import '../../../notebook_providers.dart';
import '../../cubit/journal/journal_cubit.dart';
import '../../cubit/journal/journal_state.dart';
import '../models/journal_folder_filter.dart';
import '../widgets/add_folder_dialog.dart';
import '../widgets/journal_three_column_layout.dart';

/// Classic three-column journal (folders | log day | Quill form).
class JournalWebPage extends ConsumerStatefulWidget {
  const JournalWebPage({this.portfolioId, super.key});

  final String? portfolioId;

  @override
  ConsumerState<JournalWebPage> createState() => _JournalWebPageState();
}

class _JournalWebPageState extends ConsumerState<JournalWebPage> {
  /// Cached so loading/success states do not unmount create mode.
  List<JournalEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    AppLogger.info('Initializing classic Journal Web Page', tag: 'JournalWebPage');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final journalCubit = await ref.read(journalCubitProvider.future);
      final notebookCubit = await ref.read(notebookCubitProvider.future);
      if (!mounted) return;
      journalCubit.loadJournalEntries();
      notebookCubit.loadNotebook();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final journalCubitAsync = ref.watch(journalCubitProvider);
    final notebookCubitAsync = ref.watch(notebookCubitProvider);

    return journalCubitAsync.when(
      data: (journalCubit) => notebookCubitAsync.when(
        data: (notebookCubit) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: journalCubit),
            BlocProvider.value(value: notebookCubit),
          ],
          child: Scaffold(
            backgroundColor: colors.surface,
            body: BlocConsumer<JournalCubit, JournalState>(
              listener: (context, state) {
                state.maybeWhen(
                  loaded: (entries, summary, status, folder, tags, q, setup) {
                    setState(() => _entries = entries);
                  },
                  orElse: () {},
                );
              },
              builder: (context, state) {
                final loadedEntries = state.maybeWhen(
                  loaded: (e, summary, status, folder, tags, q, setup) => e,
                  orElse: () => _entries,
                );
                final isInitialLoading = state.maybeWhen(
                      loading: () => true,
                      orElse: () => false,
                    ) &&
                    loadedEntries.isEmpty;

                if (isInitialLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: ModuleColors.trade),
                  );
                }

                return JournalThreeColumnLayout(
                  entries: loadedEntries,
                  journalCubit: journalCubit,
                  notebookCubit: notebookCubit,
                  portfolioId: widget.portfolioId ?? '',
                  onAddFolder: () async {
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (_) => const AddFolderDialog(),
                    );
                    if (result == null) return;
                    final name = result['name'] as String? ?? '';
                    if (name.isEmpty) return;
                    final color = result['color'] as Color?;
                    await notebookCubit.createItem(
                      NotebookItem(
                        type: NotebookItemType.FOLDER,
                        title: name,
                        metadata: {
                          if (color != null)
                            'color':
                                '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}',
                        },
                      ),
                    );
                  },
                  onEntryDropped: (entry, targetId) async {
                    final mapping =
                        JournalFolderFilter.dropTargetMapping(targetId);
                    try {
                      await journalCubit.editJournalEntry(
                        entryId: entry.id,
                        title: entry.title,
                        content: entry.content ?? '',
                        entryDate: entry.entryDate,
                        tradeId: entry.tradeId,
                        entryType: mapping.entryType ?? entry.entryType,
                        journalStatus: entry.journalStatus,
                        symbol: entry.symbol,
                        setup: entry.setup,
                        tradeDirection: entry.tradeDirection,
                        folderId: mapping.folderId,
                        playbookId: entry.playbookId,
                        preTradePlan: entry.preTradePlan,
                        tradeExecution: entry.tradeExecution,
                        postTradeReview: entry.postTradeReview,
                        behaviorPatternSummaries:
                            entry.behaviorPatternSummaries,
                        customFields: entry.customFields,
                        imageUrls: entry.imageUrls,
                        attachments: entry.attachments,
                        relatedTradeIds: entry.relatedTradeIds,
                        tagIds: entry.tagIds,
                        chartUrls: entry.chartUrls,
                        documentUrls: entry.documentUrls,
                        videoUrls: entry.videoUrls,
                        externalUrls: entry.externalUrls,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Moved "${entry.title}"'),
                          backgroundColor: ModuleColors.trade,
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to move entry: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ),
        loading: () => Center(
          child: CircularProgressIndicator(color: ModuleColors.trade),
        ),
        error: (error, stack) =>
            Center(child: Text('Error initializing notebook: $error')),
      ),
      loading: () => Center(
        child: CircularProgressIndicator(color: ModuleColors.trade),
      ),
      error: (error, stack) =>
          Center(child: Text('Error initializing journal: $error')),
    );
  }
}
