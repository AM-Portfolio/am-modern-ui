import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../internal/data/dtos/journal_entry_dto.dart';
import '../../../internal/domain/entities/journal_entry.dart';
import '../../../internal/domain/entities/notebook_item.dart';
import '../../../internal/domain/enums/notebook_item_type.dart';
import '../../../journal_providers.dart';
import '../../../notebook_providers.dart';
import '../../cubit/journal/journal_cubit.dart';
import '../../cubit/journal/journal_state.dart';
import '../../notebook/cubit/notebook_cubit.dart';
import '../../journal_template/pages/template_browser_page.dart';
import '../models/journal_folder_filter.dart';
import '../widgets/add_folder_dialog.dart';
import '../widgets/journal_import_dialog.dart';
import '../widgets/journal_metrics_header.dart';
import '../widgets/journal_three_column_layout.dart';
import 'journal_insights_page.dart';
import 'weekly_review_page.dart';

/// Journal hub: Entries | Playbooks | Insights | Weekly Review.
class JournalWebPage extends ConsumerStatefulWidget {
  const JournalWebPage({this.portfolioId, super.key});

  final String? portfolioId;

  @override
  ConsumerState<JournalWebPage> createState() => _JournalWebPageState();
}

enum _JournalTab { entries, playbooks, insights, weekly }

class _JournalWebPageState extends ConsumerState<JournalWebPage> {
  List<JournalEntry> _entries = const [];
  _JournalTab _tab = _JournalTab.entries;

  @override
  void initState() {
    super.initState();
    AppLogger.info('Initializing Journal Web Page', tag: 'JournalWebPage');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final journalCubit = await ref.read(journalCubitProvider.future);
      final notebookCubit = await ref.read(notebookCubitProvider.future);
      if (!mounted) return;
      journalCubit.loadJournalEntries();
      notebookCubit.loadNotebook();
    });
  }

  Future<void> _exportCsv(JournalCubit cubit) async {
    try {
      final csv = await cubit.exportCsv();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Export CSV'),
          content: SizedBox(
            width: 560,
            height: 360,
            child: SingleChildScrollView(child: SelectableText(csv)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _import(JournalCubit cubit) async {
    await showDialog<void>(
      context: context,
      builder: (_) => JournalImportDialog(journalCubit: cubit),
    );
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
            body: Column(
              children: [
                _buildSubnav(context, journalCubit),
                Expanded(
                  child: BlocConsumer<JournalCubit, JournalState>(
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
                      final summary = state.maybeWhen(
                        loaded: (e, s, status, folder, tags, q, setup) => s,
                        orElse: () => null,
                      );
                      final isInitialLoading = state.maybeWhen(
                            loading: () => true,
                            orElse: () => false,
                          ) &&
                          loadedEntries.isEmpty &&
                          _tab == _JournalTab.entries;

                      if (isInitialLoading) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: ModuleColors.trade,
                          ),
                        );
                      }

                      return IndexedStack(
                        index: _tab.index,
                        children: [
                          _buildEntries(
                            journalCubit,
                            notebookCubit,
                            loadedEntries,
                            summary,
                          ),
                          const TemplateBrowserPage(embedded: true),
                          JournalInsightsPage(journalCubit: journalCubit),
                          WeeklyReviewPage(journalCubit: journalCubit),
                        ],
                      );
                    },
                  ),
                ),
              ],
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

  Widget _buildSubnav(BuildContext context, JournalCubit cubit) {
    final colors = context.colors;
    return Material(
      color: colors.cardSurface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            for (final tab in _JournalTab.values) ...[
              if (tab.index > 0) const SizedBox(width: AppSpacing.sm),
              ChoiceChip(
                label: Text(_tabLabel(tab)),
                selected: _tab == tab,
                onSelected: (_) {
                  setState(() => _tab = tab);
                  if (tab == _JournalTab.entries) {
                    cubit.setFilters(status: 'ALL', reload: true);
                  }
                },
                selectedColor: ModuleColors.trade.withValues(alpha: 0.25),
              ),
            ],
            const Spacer(),
            if (_tab == _JournalTab.entries) ...[
              AppButton(
                text: 'Import',
                type: AppButtonType.secondary,
                isOutlined: true,
                icon: Icons.upload_file_outlined,
                onPressed: () => _import(cubit),
                height: 36,
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                text: 'Export',
                type: AppButtonType.secondary,
                isOutlined: true,
                icon: Icons.download_outlined,
                onPressed: () => _exportCsv(cubit),
                height: 36,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _tabLabel(_JournalTab tab) => switch (tab) {
        _JournalTab.entries => 'Entries',
        _JournalTab.playbooks => 'Playbooks',
        _JournalTab.insights => 'Insights',
        _JournalTab.weekly => 'Weekly Review',
      };

  Widget _buildEntries(
    JournalCubit journalCubit,
    NotebookCubit notebookCubit,
    List<JournalEntry> loadedEntries,
    JournalSummaryDto? summary,
  ) {
    return Column(
      children: [
        JournalMetricsHeader(summary: summary),
        Expanded(
          child: JournalThreeColumnLayout(
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
              final mapping = JournalFolderFilter.dropTargetMapping(targetId);
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
                  behaviorPatternSummaries: entry.behaviorPatternSummaries,
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
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Moved "${entry.title}"'),
                    backgroundColor: ModuleColors.trade,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to move entry: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
