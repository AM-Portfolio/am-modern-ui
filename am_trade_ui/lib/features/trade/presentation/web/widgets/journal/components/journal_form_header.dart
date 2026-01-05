import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JournalFormHeader extends StatelessWidget {
  const JournalFormHeader({required this.entryDate, required this.isEditMode, required this.onDateSelect, super.key});

  final DateTime entryDate;
  final bool isEditMode;
  final VoidCallback onDateSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: isEditMode ? onDateSelect : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          label: Container(padding: const EdgeInsets.symmetric(horizontal: 4), child: const Text('Entry Date')),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          prefixIcon: const Icon(Icons.calendar_today, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        child: Text(DateFormat('MMM dd, yyyy').format(entryDate), style: theme.textTheme.bodyMedium),
      ),
    );
  }
}
