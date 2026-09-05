import 'dart:ui';

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

/// Sticky bottom bar: glass capsule that auto slides up/down with company nav.
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

  static const double _actionHeight = 40;
  static const double _capsuleRadius = 28;

  Widget _buildStat(BuildContext context, BasketStatItem stat) {
    final theme = Theme.of(context);
    final shortLabel = _shortStatLabel(stat.label);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$shortLabel ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          TextSpan(
            text: stat.value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: stat.highlight
                  ? context.statusSuccess
                  : context.colors.textPrimary,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _shortStatLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('available')) return 'Avail';
    if (lower.contains('match')) return 'Match';
    if (lower.contains('target')) return 'Target';
    if (lower.contains('allocation')) return 'Alloc';
    if (lower.contains('holding')) return 'Held';
    return label;
  }

  String _compactPrimaryLabel(String label, bool isMobile) {
    if (!isMobile) return label;
    if (label.toLowerCase().startsWith('customize')) return 'Customize';
    if (label.toLowerCase().startsWith('confirm')) return 'Confirm';
    return label;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = BasketResponsive.isDesktop(context);
    final isMobile = BasketResponsive.isMobile(context);
    final isTablet = BasketResponsive.isTablet(context);
    final btnColor = primaryColor ?? context.colors.actionPrimaryBg;
    final navReserveFull = PlatformConstants.globalBottomNavReserve(context);
    final isDark = context.isDark;
    final hasSecondary = secondaryLabel != null && onSecondary != null;
    final ctaLabel = _compactPrimaryLabel(primaryLabel, isMobile);

    final statsRow = Wrap(
      spacing: isMobile ? AppSpacing.md : AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
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
        isLoading ? 'Please wait…' : ctaLabel,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
      style: FilledButton.styleFrom(
        backgroundColor: btnColor,
        foregroundColor: Colors.white,
        minimumSize: Size(isDesktop ? 200 : 0, _actionHeight),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? AppSpacing.lg : AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md + 2),
        ),
      ),
    );

    final Widget? backButton = onBack == null
        ? null
        : (isMobile
            ? IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                style: IconButton.styleFrom(
                  minimumSize: const Size(_actionHeight, _actionHeight),
                  side: BorderSide(color: context.colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
              )
            : OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: (isDesktop || isTablet)
                    ? const Text('Back')
                    : const SizedBox.shrink(),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(isDesktop ? 100 : 44, _actionHeight),
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? AppSpacing.md : AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  side: BorderSide(color: context.colors.border),
                ),
              ));

    late final Widget content;
    if (isMobile && hasSecondary) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (backButton != null) ...[
                backButton,
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(child: statsRow),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      (secondaryEnabled && !isLoading) ? onSecondary : null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, _actionHeight),
                  ),
                  child: Text(
                    secondaryLabel!,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: primaryButton),
            ],
          ),
        ],
      );
    } else if (isMobile) {
      content = Row(
        children: [
          if (backButton != null) ...[
            backButton,
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(child: statsRow),
          const SizedBox(width: AppSpacing.sm),
          primaryButton,
        ],
      );
    } else {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (backButton != null) ...[
            backButton,
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(child: statsRow),
          const SizedBox(width: AppSpacing.lg),
          if (hasSecondary) ...[
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
      );
    }

    final glassFill = isDark
        ? const Color(0xFF1a1a2e).withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.85);
    final glassBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final glass = ClipRRect(
      borderRadius: BorderRadius.circular(_capsuleRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: glassFill,
            borderRadius: BorderRadius.circular(_capsuleRadius),
            border: Border.all(color: glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: content,
        ),
      ),
    );

    // Desktop / no company nav: static glass bar.
    if (navReserveFull <= 0) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: glass,
      );
    }

    return ValueListenableBuilder<double>(
      valueListenable: GlobalBottomNavVisibility.factor,
      builder: (context, navFactor, _) {
        final t = navFactor.clamp(0.0, 1.0);
        // Lift above company nav when shown; settle to bottom when nav hides.
        final bottomInset = AppSpacing.sm +
            (navReserveFull * t) +
            MediaQuery.viewInsetsOf(context).bottom;
        // Extra slide (same language as company nav SlideTransition).
        final slideDown = 16.0 * (1.0 - t);

        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            bottomInset,
          ),
          child: Transform.translate(
            offset: Offset(0, slideDown),
            child: glass,
          ),
        );
      },
    );
  }
}
