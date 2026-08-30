import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';

class FpSummaryBar extends StatelessWidget {
  final double intendedAmount;
  final double actualCost;
  final double unallocated;
  final double coverage;
  final VoidCallback onConfirm;
  final bool isSubmitting;

  const FpSummaryBar({
    super.key,
    required this.intendedAmount,
    required this.actualCost,
    required this.unallocated,
    required this.coverage,
    required this.onConfirm,
    required this.isSubmitting,
  });

  Widget _buildStat(BuildContext context, String label, String value, {bool isHighlight = false}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlight ? context.statusSuccess : context.colors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmtValue = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final isDesktop = MediaQuery.sizeOf(context).width >= AmBreakpoints.tablet;

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.md,
            children: [
              _buildStat(context, 'Intended Amount', fmtValue.format(intendedAmount)),
              _buildStat(context, 'Actual Cost', fmtValue.format(actualCost)),
              _buildStat(context, 'Unallocated', fmtValue.format(unallocated)),
              _buildStat(context, 'Coverage', '${coverage.toStringAsFixed(0)}%', isHighlight: coverage >= 90),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        FilledButton.icon(
          onPressed: isSubmitting ? null : onConfirm,
          icon: isSubmitting 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check, size: 18),
          label: Text(
            isSubmitting ? 'Creating...' : 'Confirm & Create Basket',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: context.statusSuccess,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16, 
              vertical: isDesktop ? 20 : 16,
            ),
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: isDesktop 
          ? content
          : SingleChildScrollView(scrollDirection: Axis.horizontal, child: content),
    );
  }
}
