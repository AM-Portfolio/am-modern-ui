import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_customize_sheet.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_store.dart';
import 'package:am_dashboard_ui/presentation/widgets/dashboard_portfolio_selector.dart';
import 'package:am_dashboard_ui/presentation/widgets/paper_trading_nav_chip.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// Dashboard sticky controls matching the header mock:
/// Paper Trading | Advanced · Family · Portfolio · Timeframe · +
class DashboardToolbar extends StatelessWidget {
  const DashboardToolbar({
    super.key,
    required this.userId,
    this.onSearch,
    this.onOpenPaper,
    this.onOpenUsers,
    this.onQuickAdd,
    this.showDemoBadge = false,
    this.glass = true,
    this.onSurface,
  });

  final String userId;
  final VoidCallback? onSearch;
  final VoidCallback? onOpenPaper;
  final VoidCallback? onOpenUsers;
  final ValueChanged<GlobalAddActionKind>? onQuickAdd;
  final bool showDemoBadge;
  final bool glass;
  final Color? onSurface;

  static const double _controlSize = 36;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ModuleColors.dashboard;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 900;
    final demoCompact = width < 360;
    final iconColor = onSurface ?? context.textPrimary;

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
        const SizedBox(width: AppSpacing.sm),
        GlobalTimeFrameBar(
          key: const Key('dashboard-toolbar-timeframe'),
          variant: GlobalTimeFrameVariant.dropdown,
          dropdownWidth: compact ? 78 : 92,
          primaryColor: accent,
          dropdownTrailingDivider: false,
          dropdownLeading: Icon(
            Icons.calendar_today_outlined,
            size: AppTypeScale.sm,
            color: accent,
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
