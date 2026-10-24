import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_news_ui/am_news_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import '../../../internal/domain/entities/notebook_item.dart';
import '../../../internal/domain/entities/notebook_tag.dart';
import '../../../internal/domain/enums/notebook_item_type.dart';
import '../../../journal_providers.dart';
import '../../../notebook_providers.dart';
import '../../cubit/journal/journal_cubit.dart';
import '../../cubit/journal/journal_state.dart';
import '../../notebook/cubit/notebook_cubit.dart';
import '../../notebook/cubit/notebook_state.dart';
import '../../journal_template/pages/template_browser_page.dart';
import '../models/journal_folder_filter.dart';
import '../models/journal_template_api_mapper.dart';
import '../widgets/add_folder_dialog.dart';
import '../widgets/journal_filter_bar.dart';
import '../widgets/journal_import_dialog.dart';
import '../widgets/journal_three_column_layout.dart';
import '../widgets/simple_template_dialog.dart';
import 'journal_insights_page.dart';
import 'weekly_review_page.dart';

/// Journal hub: Entries | Playbooks | Insights | Weekly Review.
class JournalWebPage extends ConsumerStatefulWidget {
  const JournalWebPage({
    this.portfolioId,
    this.initialTab = 'entries',
    this.onOpenAnalysis,
    this.onInitialTabApplied,
    super.key,
  });

  final String? portfolioId;

  /// `entries` | `playbooks` | `insights` | `weekly`
  final String initialTab;
  final VoidCallback? onOpenAnalysis;
  final VoidCallback? onInitialTabApplied;

  @override
  ConsumerState<JournalWebPage> createState() => _JournalWebPageState();
}

enum _JournalTab { entries, playbooks, insights, weekly }

_JournalTab _journalTabFromSlug(String slug) => switch (slug.toLowerCase()) {
      'playbooks' => _JournalTab.playbooks,
      'insights' => _JournalTab.insights,
      'weekly' => _JournalTab.weekly,
      _ => _JournalTab.entries,
    };

class _JournalWebPageState extends ConsumerState<JournalWebPage> {
  List<JournalEntry> _entries = const [];
  late _JournalTab _tab;
  String _journalSymbol = '';

  String _selectedFolder = JournalFolderFilter.allNotes;
  String? _selectedTagId;
  String? _selectedTradeType;
  String? _selectedOutcome;
  JournalSortOrder _sortOrder = JournalSortOrder.latestFirst;
  DateTimeRange? _dateRange;
  bool _composerOpen = false;
  JournalTemplateSelection? _pendingPlaybook;
  final GlobalKey<JournalInsightsPageState> _insightsKey =
      GlobalKey<JournalInsightsPageState>();
  String? _focusEntryId;

  @override
  void initState() {
    super.initState();
    _tab = _journalTabFromSlug(widget.initialTab);
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: DateTime(now.year - 1, now.month, now.day),
      end: DateTime(now.year, now.month, now.day),
    );
    AppLogger.info('Initializing Journal Web Page', tag: 'JournalWebPage');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      widget.onInitialTabApplied?.call();
      final journalCubit = await ref.read(journalCubitProvider.future);
      final notebookCubit = await ref.read(notebookCubitProvider.future);
      if (!mounted) return;
      journalCubit.setPortfolioId(widget.portfolioId, reload: false);
      journalCubit.setFilters(
        startDate: _dateRange!.start,
        endDate: _dateRange!.end,
        reload: false,
      );
      journalCubit.loadJournalEntries();
      notebookCubit.loadNotebook();
      JournalSearchBridge.bind(
        applySearchQuery: (q) {
          if (!mounted) return;
          journalCubit.setFilters(searchQuery: q);
        },
        focusEntry: (entryId) {
          if (!mounted) return;
          setState(() => _focusEntryId = entryId);
        },
      );
    });
  }

  @override
  void dispose() {
    JournalSearchBridge.unbind();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant JournalWebPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.portfolioId != widget.portfolioId) {
      ref.read(journalCubitProvider.future).then((cubit) {
        if (!mounted) return;
        cubit.setPortfolioId(widget.portfolioId);
      });
    }
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

  Future<void> _pickDateRange(JournalCubit cubit) async {
    final initial = _dateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 365)),
          end: DateTime.now(),
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: initial,
    );
    if (picked == null || !mounted) return;
    setState(() => _dateRange = picked);
    cubit.setFilters(startDate: picked.start, endDate: picked.end);
  }

  List<JournalEntry> _applyLocalFilters(
    List<JournalEntry> source, {
    List<NotebookItem> notebookFolders = const [],
  }) {
    var list = JournalFolderFilter.filter(
      entries: source,
      folder: _selectedFolder,
      notebookFolders: notebookFolders,
    );

    if (_selectedTradeType != null && _selectedTradeType!.isNotEmpty) {
      final want = _selectedTradeType!.toUpperCase();
      list = list.where((e) {
        final type = (e.entryType ?? '').toUpperCase();
        if (want == 'GENERAL') {
          return type == 'GENERAL' || type.isEmpty;
        }
        if (want == 'TRADE_NOTE') {
          return JournalFolderFilter.isTradeLikeEntry(e);
        }
        return type == want;
      }).toList();
    }

    if (_selectedOutcome != null && _selectedOutcome!.isNotEmpty) {
      final want = _selectedOutcome!.toLowerCase();
      list = list.where((e) {
        final outcome = e.postTradeReview?.tradeOutcome?.toLowerCase();
        return outcome != null && outcome == want;
      }).toList();
    }

    list = List<JournalEntry>.from(list);
    list.sort((a, b) {
      final cmp = a.entryDate.compareTo(b.entryDate);
      return _sortOrder == JournalSortOrder.latestFirst ? -cmp : cmp;
    });
    return list;
  }

  List<NotebookItem> _notebookFolders = const [];
  List<NotebookTag> _notebookTags = const [];

  List<String> _availableOutcomes(List<JournalEntry> entries) {
    final set = <String>{};
    for (final e in entries) {
      final o = e.postTradeReview?.tradeOutcome?.trim();
      if (o != null && o.isNotEmpty) set.add(o);
    }
    final list = set.toList()..sort();
    return list;
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
          child: BlocConsumer<NotebookCubit, NotebookState>(
            listener: (context, state) {
              if (state is NotebookLoaded) {
                setState(() {
                  _notebookFolders = state.items;
                  _notebookTags = state.tags;
                });
              }
            },
            builder: (context, notebookState) {
              final folders = notebookState is NotebookLoaded
                  ? notebookState.items
                  : _notebookFolders;
              final tags = notebookState is NotebookLoaded
                  ? notebookState.tags
                  : _notebookTags;
              return Scaffold(
              backgroundColor: colors.surface,
              body: Column(
                children: [
                  _buildHeader(context, journalCubit),
                  Expanded(
                    child: BlocConsumer<JournalCubit, JournalState>(
                      listener: (context, state) {
                        state.maybeWhen(
                          loaded: (entries, summary, adherence, status, folder,
                              tags, q, setup) {
                            setState(() => _entries = entries);
                            _publishJournalSearchIndex(entries);
                          },
                          orElse: () {},
                        );
                      },
                      builder: (context, state) {
                        final loadedEntries = state.maybeWhen(
                          loaded: (e, summary, adherence, status, folder, tags,
                                  q, setup) =>
                              e,
                          orElse: () => _entries,
                        );
                        final loadError = state.maybeWhen(
                          error: (message) => message,
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

                        if (loadError != null &&
                            loadedEntries.isEmpty &&
                            _tab == _JournalTab.entries) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Could not load journal entries',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    loadError,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  AppButton(
                                    text: 'Retry',
                                    type: AppButtonType.primary,
                                    onPressed: () =>
                                        journalCubit.loadJournalEntries(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final filtered = _applyLocalFilters(
                          loadedEntries,
                          notebookFolders: folders,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_tab == _JournalTab.entries) ...[
                              AnimatedSize(
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutCubic,
                                alignment: Alignment.topCenter,
                                child: _composerOpen
                                    ? const SizedBox(width: double.infinity)
                                    : JournalFilterBar(
                                        selectedFolder: _selectedFolder,
                                        onFolderChanged: (folder) => setState(
                                          () => _selectedFolder = folder,
                                        ),
                                        selectedTagId: _selectedTagId,
                                        onTagChanged: (id) {
                                          setState(() => _selectedTagId = id);
                                          journalCubit.setFilters(
                                            tagIds: id == null
                                                ? <String>[]
                                                : [id],
                                          );
                                        },
                                        selectedTradeType: _selectedTradeType,
                                        onTradeTypeChanged: (t) => setState(
                                          () => _selectedTradeType = t,
                                        ),
                                        selectedOutcome: _selectedOutcome,
                                        onOutcomeChanged: (o) => setState(
                                          () => _selectedOutcome = o,
                                        ),
                                        sortOrder: _sortOrder,
                                        onSortChanged: (s) =>
                                            setState(() => _sortOrder = s),
                                        notebookFolders: folders,
                                        notebookTags: tags,
                                        availableOutcomes: _availableOutcomes(
                                          loadedEntries,
                                        ),
                                      ),
                              ),
                            ],
                            Expanded(
                              child: IndexedStack(
                                index: _tab.index,
                                children: [
                                  _buildEntries(
                                    journalCubit,
                                    notebookCubit,
                                    filtered,
                                  ),
                                  TemplateBrowserPage(
                                    embedded: true,
                                    onTemplateSelected: (template) async {
                                      if (!mounted) return;
                                      setState(() {
                                        _pendingPlaybook =
                                            journalTemplateToSelection(
                                          template,
                                        );
                                        _tab = _JournalTab.entries;
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Opening Log Day with "${template.name}"',
                                          ),
                                          backgroundColor: ModuleColors.trade,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                  ),
                                  JournalInsightsPage(
                                    key: _insightsKey,
                                    journalCubit: journalCubit,
                                    startDate: _dateRange?.start,
                                    endDate: _dateRange?.end,
                                    onReviewTrades: () => setState(
                                      () => _tab = _JournalTab.entries,
                                    ),
                                  ),
                                  WeeklyReviewPage(
                                    journalCubit: journalCubit,
                                  ),
                                ],
                              ),
                            ),
                            if (_tab == _JournalTab.entries && !_composerOpen)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: SymbolNewsSection(
                                  symbol: _journalSymbol,
                                  surface: NewsUiSurface.tradeJournal,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
            },
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

  Widget _buildHeader(BuildContext context, JournalCubit cubit) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final rangeLabel = _dateRange == null
        ? 'Date range'
        : '${DateFormat('d MMM yyyy').format(_dateRange!.start)} - ${DateFormat('d MMM yyyy').format(_dateRange!.end)}';

    return Material(
      color: colors.cardSurface,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colors.border.withValues(alpha: 0.35),
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.md,
          0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final tab in _JournalTab.values) ...[
              if (tab.index > 0) const SizedBox(width: AppSpacing.md),
              _JournalHeaderTab(
                label: _tabLabel(tab),
                selected: _tab == tab,
                onTap: () {
                  setState(() => _tab = tab);
                  if (tab == _JournalTab.entries) {
                    cubit.setFilters(status: 'ALL', reload: true);
                  } else if (tab == _JournalTab.insights) {
                    // Entries may have changed since Insights last loaded.
                    _insightsKey.currentState?.reload();
                  }
                },
              ),
            ],
            const Spacer(),
            if (_tab == _JournalTab.entries) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
              OutlinedButton.icon(
                onPressed: () => _pickDateRange(cubit),
                icon: Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: colors.textSecondary,
                ),
                label: Text(
                  rangeLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  side: BorderSide(
                    color: colors.border.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadii.card,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Use the filter row below for tags, types, and outcomes.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: Icon(
                  Icons.filter_list_rounded,
                  size: 18,
                  color: colors.textSecondary,
                ),
                label: Text(
                  'Filters',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  side: BorderSide(
                    color: colors.border.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadii.card,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              PopupMenuButton<_HeaderMenuAction>(
                tooltip: 'More',
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: colors.textSecondary,
                ),
                onSelected: (action) async {
                  switch (action) {
                    case _HeaderMenuAction.import:
                      await _import(cubit);
                    case _HeaderMenuAction.export:
                      await _exportCsv(cubit);
                    case _HeaderMenuAction.openAnalysis:
                      widget.onOpenAnalysis?.call();
                    case _HeaderMenuAction.addFolder:
                      await _addFolder();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _HeaderMenuAction.import,
                    child: Text('Import'),
                  ),
                  const PopupMenuItem(
                    value: _HeaderMenuAction.export,
                    child: Text('Export CSV'),
                  ),
                  if (widget.onOpenAnalysis != null)
                    const PopupMenuItem(
                      value: _HeaderMenuAction.openAnalysis,
                      child: Text('Open Analysis'),
                    ),
                  const PopupMenuItem(
                    value: _HeaderMenuAction.addFolder,
                    child: Text('Add folder'),
                  ),
                ],
              ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _addFolder() async {
    final notebookCubit = await ref.read(notebookCubitProvider.future);
    if (!mounted) return;
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
    List<JournalEntry> filteredEntries,
  ) {
    return JournalThreeColumnLayout(
      entries: filteredEntries,
      journalCubit: journalCubit,
      notebookCubit: notebookCubit,
      selectedFolder: _selectedFolder,
      portfolioId: widget.portfolioId ?? '',
      pendingTemplate: _pendingPlaybook,
      onPendingTemplateConsumed: () {
        if (_pendingPlaybook == null) return;
        setState(() => _pendingPlaybook = null);
      },
      onSelectedSymbolChanged: (symbol) {
        final next = symbol?.trim() ?? '';
        if (next == _journalSymbol) return;
        setState(() => _journalSymbol = next);
      },
      onEntryCreated: (_) {
        // Log Day saved: refresh hub lists + Insights so the unlock is honest.
        journalCubit.loadJournalEntries();
        _insightsKey.currentState?.reload();
      },
      onComposerOpenChanged: (open) {
        if (_composerOpen == open) return;
        setState(() => _composerOpen = open);
      },
      focusEntryId: _focusEntryId,
    );
  }

  void _publishJournalSearchIndex(List<JournalEntry> entries) {
    JournalSearchBridge.updateIndex(
      entries.map((e) {
        final mistake = e.postTradeReview?.mistakeCategory?.trim() ?? '';
        final plain = _plainJournalText(e.content ?? '');
        final sym = e.symbol?.trim() ?? '';
        final haystack = [
          e.title,
          sym,
          plain,
          mistake,
          e.setup ?? '',
        ].join(' ').toLowerCase();
        final subtitleParts = <String>[
          if (sym.isNotEmpty) sym,
          if (mistake.isNotEmpty) mistake,
          DateFormat.yMMMd().format(e.entryDate),
        ];
        return JournalSearchIndexEntry(
          id: e.id,
          title: e.title,
          subtitle: subtitleParts.join(' · '),
          haystack: haystack,
        );
      }).toList(),
    );
  }

  String _plainJournalText(String raw) {
    if (raw.isEmpty) return '';
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

enum _HeaderMenuAction { import, export, openAnalysis, addFolder }

class _JournalHeaderTab extends StatelessWidget {
  const _JournalHeaderTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? ModuleColors.trade
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                  fontSize: 15,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              width: selected ? 36 : 0,
              decoration: BoxDecoration(
                color: ModuleColors.trade,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
