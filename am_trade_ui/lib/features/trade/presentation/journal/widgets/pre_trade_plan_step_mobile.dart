import 'package:flutter/material.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import 'pre_trade_plan_step.dart';

/// Mobile Pre-Trade layout — stacked Symbol then Long/Short via `compactLayout`.
///
/// Web [PreTradePlanStep] keeps Symbol | Long/Short on one row (incl. 3-col).
class PreTradePlanStepMobile extends StatefulWidget {
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
  State<PreTradePlanStepMobile> createState() => PreTradePlanStepMobileState();
}

class PreTradePlanStepMobileState extends State<PreTradePlanStepMobile> {
  final _stepKey = GlobalKey<PreTradePlanStepState>();

  bool validate() => _stepKey.currentState?.validate() ?? true;

  String? validationMessage() => _stepKey.currentState?.validationMessage();

  @override
  Widget build(BuildContext context) {
    return PreTradePlanStep(
      key: _stepKey,
      entry: widget.entry,
      onUpdate: widget.onUpdate,
      applyDefaultChecklist: widget.applyDefaultChecklist,
      compactLayout: true,
    );
  }
}
