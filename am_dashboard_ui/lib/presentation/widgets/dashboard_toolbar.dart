import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_customize_sheet.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_store.dart';
import 'package:am_dashboard_ui/presentation/widgets/paper_trading_nav_chip.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// Dashboard sticky controls: search, paper CTA, timeframe, overflow.
///
/// Mobile wraps the row in [NavigationChrome.glass]. Desktop paints the
/// trailing cluster only (title stays in the page header).
class DashboardToolbar extends StatelessWidget {
  const DashboardToolbar({
    super.key,
    this.onSearch,
    this.onOpenPaper,
    this.onQuickAdd,
    this.showDemoBadge = false,
    this.glass = true,
    this.onSurface,
  });

  final VoidCallback? onSearch;
  final VoidCallback? onOpenPaper;
  final ValueChanged<GlobalAddActionKind>? onQuickAdd;
  final bool showDemoBadge;
  final bool glass;
  final Color? onSurface;

  static const double _controlSize = AppComponentSizes.iconButtonSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ModuleColors.dashboard;
    final width = MediaQuery.sizeOf(context).width;
    final hideTfLeading = width < 440;
    final demoCompact = width < 360;
    final iconColor = onSurface ?? context.textPrimary;

    final row = Row(
      mainAxisSize: glass ? MainAxisSize.max : MainAxisSize.min,
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
        if (onOpenPaper != null)
          PaperTradingNavChip(
            onTap: onOpenPaper!,
            compact: hideTfLeading,
          ),
        if (glass)
          const Spacer()
        else
          const SizedBox(width: AppSpacing.sm),
        GlobalTimeFrameBar(
          variant: GlobalTimeFrameVariant.dropdown,
          dropdownWidth: hideTfLeading ? 72 : 96,
          primaryColor: accent,
          dropdownTrailingDivider: true,
          dropdownLeading: hideTfLeading
              ? null
              : Icon(
                  Icons.bar_chart_rounded,
                  size: AppTypeScale.sm,
                  color: accent,
                ),
        ),
        if (onQuickAdd != null) ...[
          const SizedBox(width: AppSpacing.xs),
          _ToolbarIconWell(
            icon: Icons.more_horiz,
            accent: accent,
            iconColor: iconColor,
            tooltip: 'Quick actions',
            child: SyncQuickActionsControl(
              accentColor: accent,
              iconColor: iconColor,
              icon: Icons.more_horiz,
              actions: buildGlobalAddMenuActions(onQuickAdd!),
              showSubtitles: false,
            ),
          ),
        ],
      ],
    );

    if (!glass) {
      return KeyedSubtree(
        key: const Key('dashboard-toolbar'),
        child: row,
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
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: row,
          ),
        ),
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: AppTypeScale.h4,
      color: NavigationChrome.borderColor(isDark: isDark),
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
  });

  final IconData icon;
  final Color accent;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
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
