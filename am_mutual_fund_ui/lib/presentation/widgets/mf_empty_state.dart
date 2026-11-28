import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

class MfEmptyState extends StatelessWidget {
  const MfEmptyState({
    required this.title,
    this.body,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? body;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final accent =
        ModuleColorProvider.maybeOf(context) ?? ModuleColors.mutualFund;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xl,
        horizontal: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            child: Icon(icon, color: accent, size: 28),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
          ),
          if (body != null && body!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.textSecondary,
                    height: 1.45,
                  ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(backgroundColor: accent),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class MfErrorBanner extends StatelessWidget {
  const MfErrorBanner({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.marketNegative.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: context.marketNegative.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: context.marketNegative, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.marketNegative,
                  ),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class MfLoadingBlock extends StatelessWidget {
  const MfLoadingBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class MfQuietNote extends StatelessWidget {
  const MfQuietNote({required this.message, this.compact = false, super.key});

  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: compact ? AppSpacing.sm : AppSpacing.md),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: compact ? AppSpacing.sm : AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.85),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: compact ? 16 : 18,
            color: context.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: context.text.caption().copyWith(
                    color: context.textSecondary,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
