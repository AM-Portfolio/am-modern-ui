import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../utils/basket_responsive.dart';

class BasketStatItem {
  final String label;
  final String value;
  final bool highlight;

  const BasketStatItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });
}

/// Sticky bottom bar: stats left, back + CTAs right — used across the basket flow.
class BasketStickyActionBar extends StatelessWidget {
  final List<BasketStatItem> stats;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool isLoading;
  final IconData? primaryIcon;
  final Color? primaryColor;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool secondaryEnabled;
  final VoidCallback? onBack;

  const BasketStickyActionBar({
    super.key,
    required this.stats,
    required this.primaryLabel,
    required this.onPrimary,
    this.isLoading = false,
    this.primaryIcon,
    this.primaryColor,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryEnabled = true,
    this.onBack,
  });

  static const double _actionHeight = 48;

  Widget _buildStat(BuildContext context, BasketStatItem stat) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stat.label,
          style: theme.textTheme.labelSmall?.copyWith(color: context.colors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          stat.value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: stat.highlight ? context.statusSuccess : context.colors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = BasketResponsive.isDesktop(context);
    final isMobile = BasketResponsive.isMobile(context);
    final isTablet = BasketResponsive.isTablet(context);
    final btnColor = primaryColor ?? context.colors.actionPrimaryBg;

    final statsRow = Wrap(
      spacing: isMobile ? AppSpacing.md : AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      children: stats.map((s) => _buildStat(context, s)).toList(),
    );

    final primaryButton = FilledButton.icon(
      onPressed: isLoading ? null : onPrimary,
      icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.colors.actionPrimaryFg,
              ),
            )
          : Icon(primaryIcon ?? Icons.arrow_forward, size: 18),
      label: Text(
        isLoading ? 'Please wait…' : primaryLabel,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        overflow: TextOverflow.ellipsis,
      ),
      style: FilledButton.styleFrom(
        backgroundColor: btnColor,
        foregroundColor: Colors.white,
        minimumSize: Size(isDesktop ? 220 : 120, _actionHeight),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? AppSpacing.lg : AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md + 2),
        ),
      ),
    );

    final backButton = onBack == null
        ? null
        : OutlinedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: (isDesktop || isTablet) ? const Text('Back') : const SizedBox.shrink(),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(isDesktop ? 100 : 44, _actionHeight),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? AppSpacing.md : AppSpacing.sm,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
              side: BorderSide(color: context.colors.border),
            ),
          );

    final actions = SizedBox(
      height: _actionHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (backButton != null) ...[
            backButton,
            const SizedBox(width: AppSpacing.sm),
          ],
          if (secondaryLabel != null && onSecondary != null) ...[
            OutlinedButton(
              onPressed: (secondaryEnabled && !isLoading) ? onSecondary : null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(80, _actionHeight),
              ),
              child: Text(secondaryLabel!, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          primaryButton,
        ],
      ),
    );

    final content = isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              statsRow,
              const SizedBox(height: AppSpacing.sm),
              actions,
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: statsRow,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              actions,
            ],
          );

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
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
      child: SafeArea(
        top: false,
        child: content,
      ),
    );
  }
}

