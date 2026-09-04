import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/basket_opportunity.dart';
import '../../shared/basket_item_status_theme.dart';
import '../../utils/basket_responsive.dart';
import '../final_preview/fp_status_pill.dart';
import 'preview_layout.dart';

/// Step-1 Preview: read-only ETF Index vs Your Holdings with aligned rows.
class PreviewComparisonPanels extends StatelessWidget {
  final BasketOpportunity opportunity;

  const PreviewComparisonPanels({
    super.key,
    required this.opportunity,
  });

  /// ETF weight order keeps left/right rows horizontally scannable.
  static List<BasketItem> orderedItems(List<BasketItem> composition) {
    final items = List<BasketItem>.from(composition);
    items.sort((a, b) => b.etfWeight.compareTo(a.etfWeight));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = orderedItems(opportunity.composition);
    final sideBySide = BasketResponsive.isDesktop(context) ||
        (BasketResponsive.isTablet(context) &&
            MediaQuery.sizeOf(context).width >= 900);

    final pagePad = BasketResponsive.previewPagePadding(context).copyWith(
      top: 0,
      bottom: PreviewLayout.sectionGap,
    );

    // Always size to full content — parent page scrolls, not the tables.
    return Padding(
      padding: pagePad,
      child: sideBySide
          ? _AlignedSideBySideGrid(
              items: items,
              etfIsin: opportunity.etfIsin,
            )
          : _StackedPanels(
              items: items,
              etfIsin: opportunity.etfIsin,
            ),
    );
  }
}

class _AlignedSideBySideGrid extends StatelessWidget {
  final List<BasketItem> items;
  final String etfIsin;

  const _AlignedSideBySideGrid({
    required this.items,
    required this.etfIsin,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _PreviewTableCard(
            header: _PanelHeader(
              icon: Icons.pie_chart_outline,
              iconColor: context.colors.actionPrimaryBg,
              title: 'ETF Index',
              subtitle: '$etfIsin · Target allocation',
            ),
            columnHeader: const _IndexColumnHeader(),
            footer: const _IndexFooter(),
            shrinkWrap: true,
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < items.length; i++)
                  _IndexDataRow(item: items[i], striped: i.isEven),
              ],
            ),
          ),
        ),
        const SizedBox(width: PreviewLayout.sectionGap),
        Expanded(
          child: _PreviewTableCard(
            header: _PanelHeader(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: context.statusSuccess,
              title: 'Your Holdings',
              subtitle: 'Current portfolio exposure',
            ),
            columnHeader: const _HoldingsColumnHeader(),
            footer: const SizedBox(height: PreviewLayout.cardPadding),
            shrinkWrap: true,
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < items.length; i++)
                  _HoldingsDataRow(item: items[i], striped: i.isEven),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StackedPanels extends StatelessWidget {
  final List<BasketItem> items;
  final String etfIsin;

  const _StackedPanels({
    required this.items,
    required this.etfIsin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PreviewTableCard(
          header: _PanelHeader(
            icon: Icons.pie_chart_outline,
            iconColor: context.colors.actionPrimaryBg,
            title: 'ETF Index',
            subtitle: '$etfIsin · Target allocation',
          ),
          columnHeader: const _IndexColumnHeader(),
          footer: const _IndexFooter(),
          shrinkWrap: true,
          body: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                _IndexDataRow(item: items[i], striped: i.isEven),
            ],
          ),
        ),
        const SizedBox(height: PreviewLayout.sectionGap),
        _PreviewTableCard(
          header: _PanelHeader(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: context.statusSuccess,
            title: 'Your Holdings',
            subtitle: 'Current portfolio exposure',
          ),
          columnHeader: const _HoldingsColumnHeader(),
          shrinkWrap: true,
          body: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                _HoldingsDataRow(item: items[i], striped: i.isEven),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewTableCard extends StatelessWidget {
  final Widget header;
  final Widget columnHeader;
  final Widget body;
  final Widget? footer;
  final bool shrinkWrap;

  const _PreviewTableCard({
    required this.header,
    required this.columnHeader,
    required this.body,
    this.footer,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          columnHeader,
          Divider(color: context.colors.border, height: 1),
          if (shrinkWrap) body else Expanded(child: body),
          if (footer != null) ...[
            Divider(color: context.colors.border, height: 1),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _PanelHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PreviewLayout.panelHeaderHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PreviewLayout.cardPadding,
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.colors.textSecondary,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndexColumnHeader extends StatelessWidget {
  const _IndexColumnHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        );
    return SizedBox(
      height: PreviewLayout.columnHeaderHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PreviewLayout.cardPadding,
        ),
        child: Row(
          children: [
            Expanded(flex: 58, child: Text('Stock', style: style)),
            Expanded(
              flex: 42,
              child: Text('Weight', style: style, textAlign: TextAlign.right),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldingsColumnHeader extends StatelessWidget {
  const _HoldingsColumnHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        );
    return SizedBox(
      height: PreviewLayout.columnHeaderHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PreviewLayout.cardPadding,
        ),
        child: Row(
          children: [
            Expanded(flex: 25, child: Text('Units', style: style)),
            Expanded(flex: 45, child: Text('Value', style: style)),
            Expanded(
              flex: 30,
              child: Text('Status', style: style, textAlign: TextAlign.right),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockAvatar extends StatelessWidget {
  final String symbol;

  const _StockAvatar({required this.symbol});

  @override
  Widget build(BuildContext context) {
    final letter = symbol.isNotEmpty ? symbol[0].toUpperCase() : '?';
    final hue = (symbol.hashCode.abs() % 360).toDouble();
    final color = HSLColor.fromAHSL(1, hue, 0.45, 0.45).toColor();

    return Container(
      width: PreviewLayout.avatarSize,
      height: PreviewLayout.avatarSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _IndexDataRow extends StatelessWidget {
  final BasketItem item;
  final bool striped;

  const _IndexDataRow({required this.item, required this.striped});

  @override
  Widget build(BuildContext context) {
    final w = item.etfWeight.clamp(0.0, 100.0);
    return Container(
      height: PreviewLayout.dataRowHeight,
      color: striped
          ? context.colors.cardSurface.withValues(alpha: 0.35)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: PreviewLayout.cardPadding,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 58,
            child: Row(
              children: [
                _StockAvatar(symbol: item.stockSymbol),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.stockSymbol,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 42,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${w.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: LinearProgressIndicator(
                    value: (w / 100.0).clamp(0.0, 1.0),
                    minHeight: 3,
                    backgroundColor:
                        context.colors.border.withValues(alpha: 0.4),
                    color: context.colors.actionPrimaryBg,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IndexFooter extends StatelessWidget {
  const _IndexFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PreviewLayout.cardPadding,
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            '100.0%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _HoldingsDataRow extends StatelessWidget {
  final BasketItem item;
  final bool striped;

  const _HoldingsDataRow({
    required this.item,
    required this.striped,
  });

  @override
  Widget build(BuildContext context) {
    final fmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final priceFmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final isMissing = item.status == ItemStatus.missing;
    final qty = isMissing ? null : item.heldQuantity;
    final avg = item.heldAveragePrice;
    final price = item.lastPrice;
    final value =
        (qty != null && price != null && qty > 0) ? qty * price : null;
    final themeLabel = BasketItemStatusTheme.labelFor(item.status);
    final themeColor = BasketItemStatusTheme.colorFor(context, item.status);

    return Container(
      height: PreviewLayout.dataRowHeight,
      color: striped
          ? context.colors.cardSurface.withValues(alpha: 0.35)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: PreviewLayout.cardPadding,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 25,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMissing ? '0' : (qty?.toStringAsFixed(0) ?? '—'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (avg != null && !isMissing)
                  Text(
                    'avg ${priceFmt.format(avg)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.colors.textTertiary,
                          fontSize: 10,
                        ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 45,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMissing
                        ? '₹0'
                        : (value != null ? fmt.format(value) : '—'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (price != null && !isMissing)
                    Text(
                      '@ ${priceFmt.format(price)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: context.colors.textTertiary,
                            fontSize: 10,
                          ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 30,
            child: Align(
              alignment: Alignment.centerRight,
              child: FpStatusPill(label: themeLabel, color: themeColor),
            ),
          ),
        ],
      ),
    );
  }
}
