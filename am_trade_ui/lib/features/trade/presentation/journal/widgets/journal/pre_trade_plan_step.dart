import 'package:flutter/material.dart';
import '../../../../internal/domain/entities/journal_entry.dart';

class PreTradePlanStep extends StatelessWidget {
  final PreTradePlan? initialPlan;
  final ValueChanged<PreTradePlan> onChanged;

  const PreTradePlanStep({
    super.key,
    this.initialPlan,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Pre-Trade Plan Step'));
  }
}
