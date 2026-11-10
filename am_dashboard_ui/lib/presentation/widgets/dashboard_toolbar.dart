import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_customize_sheet.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_store.dart';
import 'package:am_dashboard_ui/presentation/widgets/dashboard_greeting.dart';
import 'package:am_dashboard_ui/presentation/widgets/dashboard_portfolio_selector.dart';
import 'package:am_dashboard_ui/presentation/widgets/paper_trading_nav_chip.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dashboard sticky controls: Paper | Advanced · Family · Portfolio · +
/// Mobile brand row shows a time-based greeting instead of the product name.
class DashboardToolbar extends ConsumerWidget {
  const DashboardToolbar({
    super.key,
    required this.userId,
    this.onSearch,
    this.onOpenPaper,
    this.onOpenUsers,
    this.onQuickAdd,
    this.onProfileTap,
    this.profileLeading,
    this.brandLabel = 'AM Investment',
    this.showDemoBadge = false,
    this.glass = true,
    this.onSurface,
    this.now,
  });

  final String userId;
  final VoidCallback? onSearch;
  final VoidCallback? onOpenPaper;
  final VoidCallback? onOpenUsers;
  final ValueChanged<GlobalAddActionKind>? onQuickAdd;
  final VoidCallback? onProfileTap;
  final Widget? profileLeading;
  final String brandLabel;
  final bool showDemoBadge;
  final bool glass;
  final Color? onSurface;

  /// Injectable clock for greeting tests.
  final DateTime Function()? now;

  static const double _controlSize = 36;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ModuleColors.dashboard;
    final width = MediaQuery.sizeOf(context).width;
    final mobileChrome = AmBreakpoints.isMobileContext(context);
    final compact = width < 900;
    final demoCompact = width < 360;
    final iconColor = onSurface ?? context.textPrimary;

    if (mobileChrome) {
      return _mobileChrome(
        context: context,
        isDark: isDark,
        accent: accent,
        demoCompact: demoCompact,
      );
    }

    final cluster = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onSearch != null) ...[
          _ToolbarIconWell(
            icon: Icons.search_rounded,
            accent: accent,
            tooltip: 'Search',
            onTap: onSearch!,
          ),
          const SizedBox(width: AppSpacing.xs),
          _Hairline(isDark: isDark),
          const SizedBox(width: AppSpacing.xs),
        ],
        if (showDemoBadge) ...[
          DemoAccountBadge(compact: demoCompact),
          const SizedBox(width: AppSpacing.xs),
        ],
        if (kDashboardCustomizeEnabled)
          IconButton(
            tooltip: 'Customize dashboard',
            onPressed: () => DashboardCustomizeSheet.show(context),
            icon: Icon(Icons.tune, color: iconColor, size: AppTypeScale.h3),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: _controlSize,
              minHeight: _controlSize,
            ),
          ),
        if (onOpenPaper != null) ...[
          PaperTradingNavChip(
            onTap: onOpenPaper!,
            onAdvanced: onOpenUsers,
            compact: compact,
          ),
          const SizedBox(width: AppSpacing.sm),
          _Hairline(isDark: isDark, tall: true),
          const SizedBox(width: AppSpacing.sm),
        ],
        SizedBox(
          width: compact ? 260 : 310,
          child: DashboardPortfolioSelector(
            userId: userId,
            compact: true,
            layout: FamilyAwarePortfolioPickerLayout.row,
          ),
        ),
        if (onQuickAdd != null) ...[
          const SizedBox(width: AppSpacing.xs),
          _GoldAddButton(
            accent: accent,
            child: SyncQuickActionsControl(
              accentColor: accent,
              iconColor: context.colors.actionPrimaryFg,
              icon: Icons.add_rounded,
              iconSize: 20,
              actions: buildGlobalAddMenuActions(onQuickAdd!),
              showSubtitles: false,
            ),
          ),
        ],
      ],
    );

    final scaled = Align(
      alignment: Alignment.centerRight,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: cluster,
      ),
    );

    if (!glass) {
      return KeyedSubtree(
        key: const Key('dashboard-toolbar'),
        child: scaled,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: NavigationChrome.glass(
        context: context,
        isDark: isDark,
        borderRadius: AppRadii.pill,
        child: SizedBox(
          key: const Key('dashboard-toolbar'),
          height: _controlSize + AppSpacing.xs * 2,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: scaled,
          ),
        ),
      ),
    );
  }

  Widget _mobileChrome({
    required BuildContext context,
    required bool isDark,
    required Color accent,
    required bool demoCompact,
  }) {
    final greeting = dashboardTimeGreeting(now?.call());

    final brand = _BrandProfileControl(
      brandLabel: brandLabel,
      greetingPhrase: greeting,
      useGreeting: true,
      accent: accent,
      leading: profileLeading,
      onTap: onProfileTap,
    );

    final row1Trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onSearch != null) ...[
          _ToolbarIconWell(
            icon: Icons.search_rounded,
            accent: accent,
            tooltip: 'Search',
            onTap: onSearch!,
            square: true,
          ),
          const SizedBox(width: 6),
        ],
        if (showDemoBadge) ...[
          DemoAccountBadge(compact: demoCompact),
          const SizedBox(width: 6),
        ],
        if (onOpenPaper != null)
          PaperTradingNavChip(
            onTap: onOpenPaper!,
            onAdvanced: onOpenUsers,
            compact: true,
          ),
      ],
    );

    final row2 = Row(
      children: [
        Flexible(
          child: DashboardPortfolioSelector(
            userId: userId,
            compact: true,
            layout: FamilyAwarePortfolioPickerLayout.row,
          ),
        ),
        if (onQuickAdd != null) ...[
          const SizedBox(width: 6),
          _GoldAddButton(
            accent: accent,
            child: SyncQuickActionsControl(
              accentColor: accent,
              iconColor: context.colors.actionPrimaryFg,
              icon: Icons.add_rounded,
              iconSize: 20,
              actions: buildGlobalAddMenuActions(onQuickAdd!),
              showSubtitles: false,
            ),
          ),
        ],
      ],
    );

    final body = Column(
      key: const Key('dashboard-toolbar'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: brand),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: row1Trailing,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        row2,
      ],
    );

    if (!glass) return body;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: NavigationChrome.glass(
        context: context,
        isDark: isDark,
        borderRadius: 18,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: body,
        ),
      ),
    );
  }
}

class _BrandProfileControl extends StatelessWidget {
  const _BrandProfileControl({
    required this.brandLabel,
    required this.accent,
    this.greetingPhrase,
    this.useGreeting = false,
    this.leading,
    this.onTap,
  });

  final String brandLabel;
  final String? greetingPhrase;
  final bool useGreeting;
  final Color accent;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = leading ??
        CircleAvatar(
          radius: 16,
          backgroundColor: accent.withValues(alpha: 0.18),
          child: Icon(Icons.person_rounded, size: 18, color: accent),
        );

    final label = Text(
      useGreeting ? (greetingPhrase ?? 'Hello') : brandLabel,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
      style: TextStyle(
        fontSize: AppTypeScale.md,
        fontWeight: FontWeight.w700,
        color: context.textPrimary,
      ),
    );

    return InkWell(
      key: const Key('dashboard-toolbar-profile'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(alpha: 0.75),
                width: 1.4,
              ),
            ),
            padding: const EdgeInsets.all(1.5),
            child: avatar,
          ),
          if (useGreeting) ...[
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 22,
              color: context.colors.border.withValues(alpha: 0.55),
            ),
          ],
          const SizedBox(width: 8),
          Flexible(child: label),
        ],
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline({required this.isDark, this.tall = false});

  final bool isDark;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: tall ? 22 : AppTypeScale.h4,
      color: NavigationChrome.borderColor(isDark: isDark),
    );
  }
}

class _GoldAddButton extends StatelessWidget {
  const _GoldAddButton({required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: DashboardToolbar._controlSize,
      height: DashboardToolbar._controlSize,
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: child),
    );
  }
}

class _ToolbarIconWell extends StatelessWidget {
  const _ToolbarIconWell({
    required this.icon,
    required this.accent,
    required this.tooltip,
    this.onTap,
    this.iconColor,
    this.child,
    this.square = false,
  });

  final IconData icon;
  final Color accent;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Widget? child;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: square ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: square ? BorderRadius.circular(10) : null,
          color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
          border: Border.all(
            color: NavigationChrome.borderColor(isDark: isDark),
          ),
        ),
        child: SizedBox(
          width: DashboardToolbar._controlSize,
          height: DashboardToolbar._controlSize,
          child: child ??
              IconButton(
                tooltip: tooltip,
                onPressed: onTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: DashboardToolbar._controlSize,
                  minHeight: DashboardToolbar._controlSize,
                ),
                icon: Icon(
                  icon,
                  color: iconColor ?? accent,
                  size: AppTypeScale.h3,
                ),
              ),
        ),
      ),
    );
  }
}
