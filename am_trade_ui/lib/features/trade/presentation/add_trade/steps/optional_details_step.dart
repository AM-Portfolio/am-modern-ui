import 'package:flutter/material.dart';

import '../../../internal/domain/enums/fundamental_reasons.dart';
import '../../../internal/domain/enums/psychology_factors.dart';
import '../../../internal/domain/enums/technical_reasons.dart';
import '../widgets/quick_selection_chips.dart';

/// Optional Details Step - Psychology, Reasoning & Notes
class OptionalDetailsStep extends StatelessWidget {
  const OptionalDetailsStep({
    required this.strategyController,
    required this.selectedEntryPsychology,
    required this.selectedExitPsychology,
    required this.selectedTechnicalReasons,
    required this.selectedFundamentalReasons,
    required this.notesController,
    required this.onEntryPsychologyChanged,
    required this.onExitPsychologyChanged,
    required this.onTechnicalReasonsChanged,
    required this.onFundamentalReasonsChanged,
    super.key,
  });

  final TextEditingController strategyController;
  final List<EntryPsychologyFactors> selectedEntryPsychology;
  final List<ExitPsychologyFactors> selectedExitPsychology;
  final List<TechnicalReasons> selectedTechnicalReasons;
  final List<FundamentalReasons> selectedFundamentalReasons;
  final TextEditingController notesController;

  final ValueChanged<List<EntryPsychologyFactors>> onEntryPsychologyChanged;
  final ValueChanged<List<ExitPsychologyFactors>> onExitPsychologyChanged;
  final ValueChanged<List<TechnicalReasons>> onTechnicalReasonsChanged;
  final ValueChanged<List<FundamentalReasons>> onFundamentalReasonsChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 1200;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.purple.shade50, Colors.purple.shade50.withOpacity(0.3)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.psychology, color: Colors.purple.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Optional Details',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Add psychology, reasoning & notes (Skip if not needed)',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Strategy
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
            child: TextField(
              controller: strategyController,
              decoration: const InputDecoration(
                labelText: 'Strategy',
                hintText: 'e.g., Breakout, Swing, Mean Reversion',
                prefixIcon: Icon(Icons.tips_and_updates, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Psychology Section
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.psychology_outlined, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Psychology', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text(
                        '${selectedEntryPsychology.length + selectedExitPsychology.length} selected',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Entry Psychology
                      QuickSelectionChips<EntryPsychologyFactors>(
                        title: 'Entry Psychology',
                        headerIcon: Icons.login,
                        availableOptions: EntryPsychologyFactors.values,
                        selectedOptions: selectedEntryPsychology,
                        onSelectionChanged: onEntryPsychologyChanged,
                        labelBuilder: (factor) => factor.toString().split('.').last.replaceAll('_', ' '),
                      ),
                      const SizedBox(height: 12),
                      // Exit Psychology
                      QuickSelectionChips<ExitPsychologyFactors>(
                        title: 'Exit Psychology',
                        headerIcon: Icons.logout,
                        availableOptions: ExitPsychologyFactors.values,
                        selectedOptions: selectedExitPsychology,
                        onSelectionChanged: onExitPsychologyChanged,
                        labelBuilder: (factor) => factor.toString().split('.').last.replaceAll('_', ' '),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Reasoning Section
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.analytics_outlined, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Reasoning', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text(
                        '${selectedTechnicalReasons.length + selectedFundamentalReasons.length} selected',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Technical
                      QuickSelectionChips<TechnicalReasons>(
                        title: 'Technical Reasons',
                        headerIcon: Icons.timeline,
                        availableOptions: TechnicalReasons.values,
                        selectedOptions: selectedTechnicalReasons,
                        onSelectionChanged: onTechnicalReasonsChanged,
                        labelBuilder: (reason) => reason.toString().split('.').last.replaceAll('_', ' '),
                      ),
                      const SizedBox(height: 12),
                      // Fundamental
                      QuickSelectionChips<FundamentalReasons>(
                        title: 'Fundamental Reasons',
                        headerIcon: Icons.insights,
                        availableOptions: FundamentalReasons.values,
                        selectedOptions: selectedFundamentalReasons,
                        onSelectionChanged: onFundamentalReasonsChanged,
                        labelBuilder: (reason) => reason.toString().split('.').last.replaceAll('_', ' '),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Notes
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
            child: TextField(
              controller: notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                hintText: 'Any other observations or comments...',
                prefixIcon: Icon(Icons.note_alt_outlined, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
