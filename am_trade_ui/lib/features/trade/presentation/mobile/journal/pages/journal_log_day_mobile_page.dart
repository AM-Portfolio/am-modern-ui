import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../../internal/domain/entities/journal_entry.dart';
import '../../../cubit/journal/journal_cubit.dart';
import '../../../web/widgets/journal/journal_entry_form.dart';

/// Log day composer for mobile — full route or inline body inside Entries.
class JournalLogDayMobilePage extends StatefulWidget {
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

  @override
  State<JournalLogDayMobilePage> createState() =>
      JournalLogDayMobilePageState();
}

class JournalLogDayMobilePageState extends State<JournalLogDayMobilePage> {
  final _formKey = GlobalKey<JournalEntryFormState>();

  Future<bool> confirmLeaveIfUnsaved({bool force = false}) async {
    return _formKey.currentState?.confirmLeaveIfUnsaved(force: force) ?? true;
  }

  void _finish({required bool saved}) {
    if (widget.embedded) {
      if (saved) {
        widget.onDone?.call();
      } else {
        widget.onCancel?.call();
      }
      return;
    }
    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final form = JournalEntryForm(
      key: _formKey,
      cubit: widget.journalCubit,
      portfolioId: widget.portfolioId ?? '',
      entry: widget.initialEntry,
      defaultEntryType: widget.defaultEntryType,
      compact: true,
      onCreated: (_) => _finish(saved: true),
      onCancelCreate: () => _finish(saved: false),
    );

    if (widget.embedded) {
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
          onPressed: () async {
            final leave = await confirmLeaveIfUnsaved();
            if (leave && mounted) _finish(saved: false);
          },
        ),
        title: const Text('Log day'),
      ),
      body: SafeArea(child: form),
    );
  }
}
