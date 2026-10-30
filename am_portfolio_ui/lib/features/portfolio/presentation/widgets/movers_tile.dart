import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../internal/domain/entities/portfolio_analytics.dart';
import 'movers_join.dart';
import 'movers_tabs.dart';

/// Compact mover row: symbol + shares | Today (fixed) | total (Value/%).
/// [MoversDisplayMode] only swaps the right-hand total column.
class MoverTile extends StatefulWidget {
  const MoverTile({
    super.key,
    required this.stock,
    required this.isGainer,
    this.mode = MoversDisplayMode.value,
    this.isLast = false,
    this.compact = false,
    this.fillSlot = false,
  });

  final Stock stock;
  final bool isGainer;
  final MoversDisplayMode mode;
  final bool isLast;
  final bool compact;
  /// Peer-band slot: no outer margin; content centered in equal-height row.
  final bool fillSlot;

  @override
  State<MoverTile> createState() => _MoverTileState();
}

class _MoverTileState extends State<MoverTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final stock = widget.stock;
    final isPositive = stock.changeAmount != 0
        ? stock.changeAmount > 0
        : (stock.changePercent != 0
            ? stock.changePercent > 0
            : widget.isGainer);
    final color = isPositive
        ? context.colors.marketPositiveIndicator
        : context.colors.marketNegativeIndicator;
    final qty = stock.quantity;
    final hasQty = qty != null && qty > 0;
    final dayValue = moverDayValueChange(stock);
    final valueText = stock.marketValue != null
        ? formatMoverInrCompact(stock.marketValue!)
        : null;
    final investedText = stock.hasCostBasis &&
            stock.investedAmount != null &&
            stock.investedAmount! > 0
        ? formatMoverInrCompact(stock.investedAmount!)
        : null;
    final dayPct = moverDayReturnPercent(stock);
    final weight = stock.weight;
    final scheme = Theme.of(context).colorScheme;
    final dayColor = (dayPct ?? stock.changePercent) >= 0
        ? context.colors.marketPositiveIndicator
        : context.colors.marketNegativeIndicator;

    final primaryStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: widget.compact ? 12 : 13,
          height: 1.15,
        );
    final mutedStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: widget.compact ? 11 : 12,
          color: scheme.onSurfaceVariant,
        );
    final secondaryStyle = TextStyle(
      fontSize: widget.compact ? 9.5 : 10,
      fontWeight: FontWeight.w500,
      color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
    );

    // Today column — never changes with Value / Percentage.
    final centerPrimary = stock.formattedLastPrice;
    final centerSecondary =
        '${stock.formattedChangeAmount} (${stock.formattedChangePercent})';

    late final String rightPrimary;
    late final String? rightSecondary;
    Widget? rightSecondaryWidget;
    Color? rightPrimaryColor;

    if (widget.mode == MoversDisplayMode.value) {
      rightPrimary = valueText ?? '—';
      rightPrimaryColor = null;
      if (investedText != null || dayValue != null) {
        rightSecondaryWidget = Text.rich(
          TextSpan(
            style: secondaryStyle,
            children: [
              if (investedText != null)
                TextSpan(text: 'Inv $investedText'),
              if (investedText != null && dayValue != null)
                TextSpan(
                  text: ' · ',
                  style: secondaryStyle,
                ),
              if (dayValue != null)
                TextSpan(
                  text: formatSignedInrCompact(dayValue),
                  style: secondaryStyle.copyWith(
                    color: dayColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
        );
      }
      rightSecondary = null;
    } else {
      // Today's return % (same sign as day move) + weight — never lifetime P&L %.
      final pct = dayPct ?? stock.changePercent;
      rightPrimary = formatSignedPct(pct);
      rightPrimaryColor = dayColor;
      if (weight != null && weight > 0) {
        rightSecondary = '${weight.toStringAsFixed(1)}% of portfolio';
      } else if (valueText != null) {
        rightSecondary = valueText;
      } else {
        rightSecondary = null;
      }
    }

    final vPad = widget.fillSlot
        ? (widget.compact ? 2.0 : 4.0)
        : (widget.compact ? 3.0 : 5.0);
    final gap = widget.compact ? 2.0 : 3.0;

    final row = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(
        bottom: widget.fillSlot || widget.isLast ? 0 : gap,
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: vPad),
      decoration: BoxDecoration(
        color: _hovered
            ? color.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          bottom: widget.isLast
              ? BorderSide.none
              : BorderSide(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.12),
                ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stock.symbol,
                    style: primaryStyle,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasQty) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${formatMoverQty(qty)} shares',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: _MoneyColumn(
                primary: centerPrimary,
                secondary: centerSecondary,
                primaryStyle: mutedStyle,
                secondaryStyle: secondaryStyle.copyWith(color: dayColor),
              ),
            ),
            Container(
              key: const ValueKey('mover-metric-split'),
              width: 1,
              height: 28,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: scheme.onSurfaceVariant.withValues(alpha: 0.28),
            ),
            Expanded(
              flex: 3,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey('right-${widget.mode}'),
                  child: _MoneyColumn(
                    primary: rightPrimary,
                    secondary: rightSecondary,
                    secondaryWidget: rightSecondaryWidget,
                    primaryStyle: rightPrimaryColor != null
                        ? mutedStyle?.copyWith(color: rightPrimaryColor)
                        : mutedStyle,
                    secondaryStyle: secondaryStyle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: widget.fillSlot
          ? SizedBox.expand(
              child: Align(alignment: Alignment.center, child: row),
            )
          : row,
    );
  }
}

class _MoneyColumn extends StatelessWidget {
  const _MoneyColumn({
    required this.primary,
    required this.primaryStyle,
    required this.secondaryStyle,
    this.secondary,
    this.secondaryWidget,
  });

  final String primary;
  final String? secondary;
  final Widget? secondaryWidget;
  final TextStyle? primaryStyle;
  final TextStyle secondaryStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            primary,
            maxLines: 1,
            style: primaryStyle,
          ),
        ),
        if (secondaryWidget != null)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: secondaryWidget!,
          )
        else if (secondary != null)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              secondary!,
              maxLines: 1,
              style: secondaryStyle,
            ),
          ),
      ],
    );
  }
}
