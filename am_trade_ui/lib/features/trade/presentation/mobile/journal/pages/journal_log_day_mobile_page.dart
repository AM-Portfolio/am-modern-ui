import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../../internal/domain/entities/journal_entry.dart';
import '../../../cubit/journal/journal_cubit.dart';
import '../../../web/widgets/journal/journal_entry_form.dart';

/// Log day composer for mobile — full route or inline body inside Entries.
class JournalLogDayMobilePage extends StatelessWidget {
  const JournalLogDayMobilePage({
    required this.journalCubit,
    required this.portfolioId,
    this.initialEntry,
    this.defaultEntryType = 'DAILY',
    this.embedded = false,
    this.onDone,
    this.onCancel,
    super.key,
  });

  final JournalCubit journalCubit;
  final String? portfolioId;
  final JournalEntry? initialEntry;
  final String defaultEntryType;

  /// When true, render form only (no Scaffold) for in-tab Entries composer.
  final bool embedded;
  final VoidCallback? onDone;
  final VoidCallback? onCancel;

  static Future<bool?> open(
    BuildContext context, {
    required JournalCubit journalCubit,
    String? portfolioId,
    JournalEntry? initialEntry,
    String defaultEntryType = 'DAILY',
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => JournalLogDayMobilePage(
          journalCubit: journalCubit,
          portfolioId: portfolioId,
          initialEntry: initialEntry,
          defaultEntryType: defaultEntryType,
        ),
      ),
    );
  }

  void _finish(BuildContext context, {required bool saved}) {
    if (embedded) {
      if (saved) {
        onDone?.call();
      } else {
        onCancel?.call();
      }
      return;
    }
    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final form = JournalEntryForm(
      cubit: journalCubit,
      portfolioId: portfolioId ?? '',
      entry: initialEntry,
      defaultEntryType: defaultEntryType,
      compact: true,
      onCreated: (_) => _finish(context, saved: true),
      onCancelCreate: () => _finish(context, saved: false),
    );

    if (embedded) {
      return ColoredBox(color: colors.surface, child: form);
    }

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _finish(context, saved: false),
        ),
        title: Text(initialEntry == null ? 'Log day' : 'Edit Log day'),
      ),
      body: SafeArea(child: form),
    );
  }
}
