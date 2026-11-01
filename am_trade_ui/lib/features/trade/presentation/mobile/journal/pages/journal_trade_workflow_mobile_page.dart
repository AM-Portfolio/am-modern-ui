import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../../internal/domain/entities/journal_entry.dart';
import '../../../cubit/journal/journal_cubit.dart';
import '../../../journal/pages/trade_journal_workflow_page.dart';

/// Trade journal Pre → Execute → Post for mobile — full route or inline Entries.
class JournalTradeWorkflowMobilePage extends StatefulWidget {
  const JournalTradeWorkflowMobilePage({
    required this.journalCubit,
    this.initialEntry,
    this.portfolioId,
    this.startAtStep,
    this.initialReadOnly = false,
    this.embedded = false,
    this.onDone,
    this.onCancel,
    super.key,
  });

  final JournalCubit journalCubit;
  final JournalEntry? initialEntry;
  final String? portfolioId;
  final int? startAtStep;
  final bool initialReadOnly;

  /// When true, render workflow only (no outer Scaffold) for in-tab composer.
  final bool embedded;
  final VoidCallback? onDone;
  final VoidCallback? onCancel;

  static Future<void> open(
    BuildContext context, {
    required JournalCubit journalCubit,
    JournalEntry? initialEntry,
    String? portfolioId,
    int? startAtStep,
    bool initialReadOnly = false,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => JournalTradeWorkflowMobilePage(
          journalCubit: journalCubit,
          initialEntry: initialEntry,
          portfolioId: portfolioId,
          startAtStep: startAtStep,
          initialReadOnly: initialReadOnly,
        ),
      ),
    );
  }

  @override
  State<JournalTradeWorkflowMobilePage> createState() =>
      _JournalTradeWorkflowMobilePageState();
}

class _JournalTradeWorkflowMobilePageState
    extends State<JournalTradeWorkflowMobilePage> {
  final _workflowKey = GlobalKey<TradeJournalWorkflowPageState>();

  Future<void> _handleBack() async {
    final leave =
        await _workflowKey.currentState?.confirmLeaveIfUnsaved() ?? true;
    if (!leave || !mounted) return;
    if (widget.embedded) {
      widget.onCancel?.call();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _closeDone() {
    if (widget.embedded) {
      widget.onDone?.call();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final title = widget.initialEntry == null
        ? 'Trade journal'
        : (widget.initialEntry!.title.trim().isEmpty
            ? 'Trade journal'
            : widget.initialEntry!.title);

    final workflow = TradeJournalWorkflowPage(
      key: _workflowKey,
      journalCubit: widget.journalCubit,
      initialEntry: widget.initialEntry,
      portfolioId: widget.portfolioId,
      embedded: true,
      useMobileLayout: true,
      startAtStep: widget.startAtStep,
      initialReadOnly: widget.initialReadOnly,
      onEmbeddedDone: (_, {required bool complete}) => _closeDone(),
      onEmbeddedCancel: () {
        if (widget.embedded) {
          widget.onCancel?.call();
        } else if (mounted) {
          Navigator.of(context).pop();
        }
      },
      onEmbeddedDeleted: () => _closeDone(),
    );

    if (widget.embedded) {
      // Parent (Entries hub) owns the back chrome; body only here.
      return ColoredBox(color: colors.surface, child: workflow);
    }

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: workflow,
    );
  }
}
