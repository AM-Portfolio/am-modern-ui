import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

class MfStatusChip extends StatelessWidget {
  const MfStatusChip({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    late final Color bg;
    late final Color fg;
    switch (normalized) {
      case 'allotted':
      case 'paid':
      case 'active':
      case 'ok':
        bg = context.marketPositive.withValues(alpha: 0.15);
        fg = context.marketPositive;
      case 'failed':
      case 'rejected':
      case 'cancelled':
        bg = context.marketNegative.withValues(alpha: 0.15);
        fg = context.marketNegative;
      case 'submitted':
      case 'payment_pending':
      case 'pending':
      case 'created':
        bg = context.statusWarning.withValues(alpha: 0.15);
        fg = context.statusWarning;
      default:
        bg = context.surfaceColor;
        fg = context.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: context.borderColor),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
      ),
    );
  }
}
