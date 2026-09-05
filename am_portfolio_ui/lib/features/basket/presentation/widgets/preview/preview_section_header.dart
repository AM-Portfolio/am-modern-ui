import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../domain/models/basket_opportunity.dart';
import '../../utils/basket_responsive.dart';
import 'preview_table_layout.dart';

class PreviewSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final ItemStatus statusType;
  final int itemCount;

  const PreviewSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusType,
    this.itemCount = 0,
  });

  Color _colorForStatus(BuildContext context) {
    switch (statusType) {
      case ItemStatus.held:
        return context.statusSuccess;
      case ItemStatus.substitute:
        return ModuleColors.portfolio;
      case ItemStatus.missing:
        return context.statusError;
      case ItemStatus.excluded:
        return context.colors.textTertiary;
    }
  }

  IconData _iconForStatus() {
    switch (statusType) {
      case ItemStatus.held:
        return Icons.check_circle_outline_rounded;
      case ItemStatus.substitute:
        return Icons.swap_horiz_rounded;
      case ItemStatus.missing:
        return Icons.error_outline_rounded;
      case ItemStatus.excluded:
        return Icons.block_rounded;
    }
  }

  TextStyle _groupLabelStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall!.copyWith(
          color: context.colors.textTertiary,
          fontWeight: FontWeight.w800,
          fontSize: 9,
          letterSpacing: 0.8,
        );
  }

  TextStyle _colLabelStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall!.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        );
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForStatus(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = PreviewTableLayout.useCompactTable(context, constraints);
        return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Row(
            children: [
              Icon(_iconForStatus(), color: color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary,
                              ),
                        ),
                        if (itemCount > 0) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$itemCount',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!compact)
          Container(
            decoration: BoxDecoration(
              color: context.colors.cardSurface,
              border: Border(
                bottom: BorderSide(color: context.colors.border.withValues(alpha: 0.7)),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: PreviewTableLayout.headerPadding.copyWith(bottom: 4),
                  child: PreviewTableLayout.scrollableTable(
                    context: context,
                    child: Row(
                      children: [
                        Expanded(
                          flex: PreviewTableLayout.etfPanelFlex,
                          child: Row(
                            children: [
                              Icon(Icons.pie_chart_outline_rounded,
                                  size: 11, color: context.colors.textTertiary),
                              const SizedBox(width: 4),
                              Text('ETF INDEX', style: _groupLabelStyle(context)),
                            ],
                          ),
                        ),
                        SizedBox(width: PreviewTableLayout.colGap * 2 + 1),
                        Expanded(
                          flex: PreviewTableLayout.portfolioPanelFlex,
                          child: Row(
                            children: [
                              Icon(Icons.account_balance_wallet_outlined,
                                  size: 11, color: context.colors.textTertiary),
                              const SizedBox(width: 4),
                              Text('YOUR HOLDINGS', style: _groupLabelStyle(context)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: PreviewTableLayout.colGap + PreviewTableLayout.statusWidth,
                        ),
                      ],
                    ),
                  ),
                ),
                PreviewTableLayout.row(
                  context: context,
                  padding: PreviewTableLayout.headerPadding.copyWith(top: 0),
                  crossAxisAlignment: CrossAxisAlignment.end,
                  etfName: Text('Constituent', style: _colLabelStyle(context)),
                  etfWeight: Text('Weight', style: _colLabelStyle(context)),
                  units: Text('Units', style: _colLabelStyle(context)),
                  value: Text('Value', style: _colLabelStyle(context)),
                  status: Text(
                    'Status',
                    style: _colLabelStyle(context),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            decoration: BoxDecoration(
              color: context.colors.cardSurface,
              border: Border(
                bottom: BorderSide(color: context.colors.border.withValues(alpha: 0.7)),
              ),
            ),
            child: Text(
              'ETF target vs your holdings',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
      ],
        );
      },
    );
  }
}

/// Card wrapper for a preview section (header + rows).
class PreviewSectionCard extends StatelessWidget {
  final Widget child;

  const PreviewSectionCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: BasketResponsive.pagePadding(context).copyWith(top: 0, bottom: AppSpacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.colors.border.withValues(alpha: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      ),
    );
  }
}
