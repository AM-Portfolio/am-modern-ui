import 'package:flutter/material.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import 'pre_trade_plan_step.dart';

/// Mobile Pre-Trade layout — stacked Symbol then Long/Short.
///
/// Web keeps [PreTradePlanStep] with `compactLayout: false` (Symbol | Long/Short row).
class PreTradePlanStepMobile extends StatelessWidget {
  const PreTradePlanStepMobile({
    super.key,
    required this.entry,
    required this.onUpdate,
    this.applyDefaultChecklist = false,
  });

  final JournalEntry entry;
  final ValueChanged<JournalEntry> onUpdate;
  final bool applyDefaultChecklist;

  @override
  Widget build(BuildContext context) {
    return PreTradePlanStep(
      entry: entry,
      onUpdate: onUpdate,
      applyDefaultChecklist: applyDefaultChecklist,
      compactLayout: true,
    );
  }
}
