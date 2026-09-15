import 'package:flutter/material.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import '../../cubit/journal/journal_cubit.dart';

/// Lightweight form for DAILY / MISSED journal entries.
class SimpleJournalNotePage extends StatefulWidget {
  const SimpleJournalNotePage({
    super.key,
    required this.journalCubit,
    required this.entryType,
    this.initialEntry,
  });

  final JournalCubit journalCubit;
  final String entryType;
  final JournalEntry? initialEntry;

  @override
  State<SimpleJournalNotePage> createState() => _SimpleJournalNotePageState();
}

class _SimpleJournalNotePageState extends State<SimpleJournalNotePage> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  late final TextEditingController _symbol;
  late final TextEditingController _lesson;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.initialEntry;
    _title = TextEditingController(
      text: e?.title ??
          (widget.entryType == 'MISSED' ? 'Missed trade' : 'Daily journal'),
    );
    _content = TextEditingController(text: e?.content ?? '');
    _symbol = TextEditingController(text: e?.symbol ?? '');
    _lesson = TextEditingController(
      text: e?.postTradeReview?.lessonLearned ?? '',
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _symbol.dispose();
    _lesson.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.journalCubit.saveEntryFull(
        entryId: widget.initialEntry?.id,
        title: _title.text.trim().isEmpty ? 'Untitled' : _title.text.trim(),
        content: _content.text,
        entryDate: widget.initialEntry?.entryDate ?? DateTime.now(),
        entryType: widget.entryType,
        journalStatus:
            widget.entryType == 'MISSED' ? 'MISSED' : 'COMPLETED',
        symbol: _symbol.text.trim().isEmpty ? null : _symbol.text.trim(),
        postTradeReview: PostTradeReview(
          lessonLearned:
              _lesson.text.trim().isEmpty ? null : _lesson.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMissed = widget.entryType == 'MISSED';
    return Scaffold(
      appBar: AppBar(
        title: Text(isMissed ? 'Missed Trade' : 'Daily Note'),
        actions: [
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (isMissed) ...[
            TextField(
              controller: _symbol,
              decoration: const InputDecoration(
                labelText: 'Symbol',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _content,
            maxLines: 10,
            decoration: InputDecoration(
              labelText: isMissed
                  ? 'Why did you skip this setup?'
                  : 'Market bias, mood, goals…',
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lesson,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Lesson / takeaway',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}
