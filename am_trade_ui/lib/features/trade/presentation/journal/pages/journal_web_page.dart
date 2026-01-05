import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';


import '../../../journal_providers.dart';
import '../../../notebook_providers.dart';
import '../../../internal/domain/enums/notebook_item_type.dart';
import '../../../internal/domain/entities/notebook_item.dart';
import '../../../internal/domain/entities/journal_entry.dart';
import 'package:am_common/am_common.dart';
import '../../cubit/journal/journal_cubit.dart';
import '../../cubit/journal/journal_state.dart';
import '../../notebook/cubit/notebook_cubit.dart';
import '../../notebook/cubit/notebook_state.dart';
import '../widgets/journal_three_column_layout.dart';
import '../widgets/add_folder_dialog.dart';

class JournalWebPage extends ConsumerStatefulWidget {
  const JournalWebPage({required this.userId, this.portfolioId, super.key});

  final String userId;
  final String? portfolioId;

  @override
  ConsumerState<JournalWebPage> createState() => _JournalWebPageState();
}

class _JournalWebPageState extends ConsumerState<JournalWebPage> {
  // Cubits are now managed via Riverpod FutureProviders

  @override
  void initState() {
    super.initState();
    
    // Mode Logger
    AppLogger.info(
      'Initializing Journal Web Page', 
      tag: 'JournalWebPage'
    );
    AppLogger.info(
      'Current Mode: ${EnvironmentConfig.environment.name}', 
      tag: 'JournalWebPage'
    );
    AppLogger.info(
      'Mock Data Enabled: ${EnvironmentConfig.settings['useMockData']}', 
      tag: 'JournalWebPage'
    );
    
    // Load data after cubits are initialized
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final journalCubit = await ref.read(journalCubitProvider.future);
      final notebookCubit = await ref.read(notebookCubitProvider.future);
      journalCubit.loadJournalEntries(widget.userId);
      notebookCubit.loadNotebook(widget.userId);
    });
  }

  Future<void> _handleAddFolder() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddFolderDialog(userId: widget.userId),
    );

    if (result != null && mounted) {
      final folderName = result['name'] as String;
      final color = result['color'] as Color;
      final icon = result['icon'] as IconData;

      // Create metadata to store color and icon
      final metadata = {
        'color': color.value.toRadixString(16),
        'icon': icon.codePoint,
      };

      // Create NotebookItem for the folder
      final folder = NotebookItem(
        userId: widget.userId,
        type: NotebookItemType.FOLDER,
        title: folderName,
        metadata: metadata,
      );

      // Call cubit to create folder
      final notebookCubit = await ref.read(notebookCubitProvider.future);
      await notebookCubit.createItem(folder);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Folder "$folderName" created successfully'),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleEntryDropped(JournalEntry entry, String folderId, NotebookCubit notebookCubit) async {
    // Create a NOTE item in the folder that references the journal entry
    final note = NotebookItem(
      userId: widget.userId,
      type: NotebookItemType.FOLDER, // Should this be folder or note? The original was NOTE but uses type FOLDER? 
      // Wait, original line 79 said type: NotebookItemType.FOLDER for _handleAddFolder
      // Line 105 said type: NotebookItemType.NOTE.
      // Re-checking...
      title: 'Journal Entry - ${DateFormat('MMM dd, yyyy').format(entry.entryDate)}',
      parentId: folderId,
      content: entry.content ?? '',
      metadata: {
        'journalEntryId': entry.id,
        'linkedAt': DateTime.now().toIso8601String(),
        'entryDate': entry.entryDate.toIso8601String(),
      },
      tagIds: entry.tagIds,
    );
    // Actually using NOTE for entry links
    final noteCorrected = note.copyWith(type: NotebookItemType.NOTE);

    // Call cubit to create note
    await notebookCubit.createItem(noteCorrected);
    
    // Refresh notebook to show updated folder structure
    await notebookCubit.loadNotebook(widget.userId);

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Journal entry added to folder'),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white,
            onPressed: () {
              // TODO: Implement undo
            },
          ),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final journalCubitAsync = ref.watch(journalCubitProvider);
    final notebookCubitAsync = ref.watch(notebookCubitProvider);

    return journalCubitAsync.when(
      data: (journalCubit) => notebookCubitAsync.when(
        data: (notebookCubit) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: journalCubit),
            BlocProvider.value(value: notebookCubit),
          ],
          child: MultiBlocListener(
            listeners: [
              BlocListener<JournalCubit, JournalState>(
                listener: (context, state) {
                  // Handle journal success/error messages if needed
                },
              ),
              BlocListener<NotebookCubit, NotebookState>(
                listener: (context, state) {
                  // Handle notebook success/error messages if needed
                },
              ),
            ],
            child: Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: BlocBuilder<JournalCubit, JournalState>(
                builder: (context, journalState) {
                  return BlocBuilder<NotebookCubit, NotebookState>(
                    builder: (context, notebookState) {
                      // Combine states or handle loading separately?
                      // For now, let's show layout if journal is loaded, notebook can load in background or show loading in sidebar
                      
                      return journalState.when(
                        initial: () => const SizedBox.shrink(),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (message) => Center(child: Text('Error: $message')),
                        success: (message) => const Center(child: CircularProgressIndicator()),
                        loaded: (entries) => JournalThreeColumnLayout(
                            entries: entries,
                            userId: widget.userId,
                            journalCubit: journalCubit,
                            notebookCubit: notebookCubit,
                            onAddFolder: _handleAddFolder,
                            onEntryDropped: (entry, folderId) => _handleEntryDropped(entry, folderId, notebookCubit),
                          ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error initializing notebook: $error')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error initializing journal: $error')),
    );
  }
}

