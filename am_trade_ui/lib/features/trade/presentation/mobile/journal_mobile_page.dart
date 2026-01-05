import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../journal_providers.dart';
import '../cubit/journal/journal_cubit.dart';
import '../cubit/journal/journal_state.dart';
import '../widgets/journal/journal_entry_form.dart';

class JournalMobilePage extends ConsumerStatefulWidget {
  const JournalMobilePage({required this.userId, super.key, this.portfolioId});

  final String userId;
  final String? portfolioId;

  @override
  ConsumerState<JournalMobilePage> createState() => _JournalMobilePageState();
}

class _JournalMobilePageState extends ConsumerState<JournalMobilePage> {
  late final JournalCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = ref.read(journalCubitProvider);
    _cubit.loadJournalEntries(widget.userId);
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    child: Scaffold(
      appBar: AppBar(title: const Text('Trade Journal')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => JournalEntryForm(
                userId: widget.userId,
                cubit: _cubit,
                portfolioId: widget.portfolioId ?? '8a57024c-05c2-475b-a2c4-0545865efa4a',
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<JournalCubit, JournalState>(
        builder: (context, state) => state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (message) => Center(child: Text('Error: $message')),
          success: (message) => const Center(child: CircularProgressIndicator()),
          loaded: (entries) {
            if (entries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.book_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No journal entries',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => JournalEntryForm(
                            userId: widget.userId,
                            cubit: _cubit,
                            portfolioId: widget.portfolioId ?? '8a57024c-05c2-475b-a2c4-0545865efa4a',
                            entry: entry,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.entryDate.toString().split(' ')[0],
                                style: Theme.of(
                                  context,
                                ).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  _cubit.removeJournalEntry(widget.userId, entry.id);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.content,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
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
      ),
    ),
  );
}
