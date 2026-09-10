import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/quote_models.dart';

class OrderTicketHeaderBlock extends StatelessWidget {
  const OrderTicketHeaderBlock({
    super.key,
    required this.title,
    required this.loading,
    required this.ltp,
    required this.change,
    required this.changePct,
    required this.priceColor,
    required this.fmt,
    required this.quote,
    required this.isBuy,
    required this.onBuy,
    required this.onSell,
    this.compact = false,
    this.exchange = 'NSE',
    this.onExchangeChanged,
    this.floating = false,
    this.onToggleFloat,
    this.onCloseFloat,
    this.onHeaderDragUpdate,
    this.onHeaderDragEnd,
  });

  final String title;
  final bool loading;
  final double ltp;
  final double change;
  final double changePct;
  final Color priceColor;
  final NumberFormat fmt;
  final QuoteDetail? quote;
  final bool isBuy;
  final VoidCallback onBuy;
  final VoidCallback onSell;
  final bool compact;
  final String exchange;
  final ValueChanged<String>? onExchangeChanged;
  final bool floating;
  final VoidCallback? onToggleFloat;
  final VoidCallback? onCloseFloat;
  final GestureDragUpdateCallback? onHeaderDragUpdate;
  final GestureDragEndCallback? onHeaderDragEnd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final titleRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: (compact
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.titleLarge)
                ?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        ),
        if (!compact && onToggleFloat != null)
          IconButton(
            tooltip: floating ? 'Cycle float position' : 'Float order ticket',
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            onPressed: onToggleFloat,
            icon: Icon(
              floating ? Icons.filter_none : Icons.open_in_full,
              color: colors.textTertiary,
            ),
          ),
        if (onCloseFloat != null)
          IconButton(
            tooltip: floating ? 'Dock order ticket' : 'Close',
            visualDensity: VisualDensity.compact,
            iconSize: compact ? 20 : 18,
            onPressed: onCloseFloat,
            icon: Icon(Icons.close, color: colors.textTertiary),
          )
        else if (!compact)
          Icon(Icons.open_in_new, size: 18, color: colors.textTertiary),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: onHeaderDragUpdate,
          onPanEnd: onHeaderDragEnd,
          child: MouseRegion(
            cursor: onHeaderDragUpdate != null
                ? SystemMouseCursors.move
                : SystemMouseCursors.basic,
            child: titleRow,
          ),
        ),
        SizedBox(height: compact ? 4 : 8),
        if (loading)
          LinearProgressIndicator(
            minHeight: 2,
            color: colors.actionPrimaryBg,
            backgroundColor: colors.divider,
          )
        else if (ltp > 0)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                fmt.format(ltp),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 18 : 22,
                    ),
              ),
              Icon(
                change < 0 ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                color: priceColor,
                size: compact ? 18 : 22,
              ),
              Text(
                '${change >= 0 ? '+' : ''}${fmt.format(change)} (${changePct.toStringAsFixed(2)}%)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: priceColor,
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 12 : null,
                    ),
              ),
              if (!compact)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colors.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Live',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.textTertiary,
                          ),
                    ),
                  ],
                ),
            ],
          )
        else
          Text(
            'Search a stock in the watchlist to load prices',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
        if (!compact && quote != null && ltp > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.marketCardSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.marketBorderMuted),
            ),
            child: Row(
              children: [
                OrderTicketMiniStat(
                  'Open',
                  quote!.open != null ? fmt.format(quote!.open) : '—',
                ),
                OrderTicketMiniStat(
                  'High',
                  quote!.high != null ? fmt.format(quote!.high) : '—',
                ),
                OrderTicketMiniStat(
                  'Low',
                  quote!.low != null ? fmt.format(quote!.low) : '—',
                ),
                OrderTicketMiniStat(
                  'Prev',
                  quote!.previousClose != null
                      ? fmt.format(quote!.previousClose)
                      : '—',
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: compact ? 8 : 12),
        Row(
          children: [
            OrderTicketBuySellToggle(
              isBuy: isBuy,
              onBuy: onBuy,
              onSell: onSell,
            ),
            const Spacer(),
            OrderTicketExchangeToggle(
              exchange: exchange,
              onChanged: onExchangeChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class OrderTicketMiniStat extends StatelessWidget {
  const OrderTicketMiniStat(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class OrderTicketBalanceBar extends StatelessWidget {
  const OrderTicketBalanceBar({
    super.key,
    required this.available,
    this.compact = false,
  });

  final String available;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: compact ? 14 : 16, color: colors.textSecondary),
          const SizedBox(width: 8),
          Text(
            'Paper cash',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const Spacer(),
          Text(
            '₹$available',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 13 : null,
                ),
          ),
        ],
      ),
    );
  }
}

class OrderTicketBuySellToggle extends StatelessWidget {
  const OrderTicketBuySellToggle({
    super.key,
    required this.isBuy,
    required this.onBuy,
    required this.onSell,
  });

  final bool isBuy;
  final VoidCallback onBuy;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.scaffoldBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.marketBorderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OrderTicketSeg(
            label: 'Buy',
            selected: isBuy,
            color: colors.actionPrimaryBg,
            onTap: onBuy,
          ),
          OrderTicketSeg(
            label: 'Sell',
            selected: !isBuy,
            color: colors.marketNegativeIndicator,
            onTap: onSell,
          ),
        ],
      ),
    );
  }
}

class OrderTicketExchangeToggle extends StatelessWidget {
  const OrderTicketExchangeToggle({
    super.key,
    required this.exchange,
    this.onChanged,
  });

  final String exchange;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isNse = exchange.toUpperCase() != 'BSE';
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.scaffoldBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.marketBorderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OrderTicketSeg(
            label: 'NSE',
            selected: isNse,
            color: colors.actionPrimaryBg,
            onTap: () => onChanged?.call('NSE'),
          ),
          OrderTicketSeg(
            label: 'BSE',
            selected: !isNse,
            color: colors.actionPrimaryBg,
            onTap: () => onChanged?.call('BSE'),
          ),
        ],
      ),
    );
  }
}

class OrderTicketSeg extends StatelessWidget {
  const OrderTicketSeg({
    super.key,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : context.colors.cardSurface.withValues(alpha: 0),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? context.colors.actionPrimaryFg
                      : context.colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class OrderTicketProductTile extends StatelessWidget {
  const OrderTicketProductTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = colors.actionPrimaryBg;
    return Material(
      color: selected ? accent.withValues(alpha: 0.12) : colors.cardSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : colors.marketBorderDefault,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? accent : colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected
                          ? accent.withValues(alpha: 0.85)
                          : colors.textTertiary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderTicketOrderCard extends StatelessWidget {
  const OrderTicketOrderCard({
    super.key,
    required this.child,
    this.compact = false,
  });

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(compact ? 10 : 14),
        border: Border.all(color: colors.marketBorderDefault),
        boxShadow: compact
            ? null
            : [
                BoxShadow(
                  color: colors.textPrimary.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}

class OrderTicketTypeTab extends StatelessWidget {
  const OrderTicketTypeTab({
    super.key,
    required this.label,
    required this.badge,
    required this.selected,
    required this.onTap,
    this.superStyle = false,
    this.compact = false,
  });

  final String label;
  final String badge;
  final bool selected;
  final bool superStyle;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = colors.actionPrimaryBg;
    return Material(
      color: selected
          ? colors.actionPrimaryBg.withValues(alpha: 0.12)
          : colors.cardSurface,
      borderRadius: BorderRadius.circular(compact ? 8 : 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: compact ? 6 : 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 8 : 10),
            border: Border.all(
              color: selected ? accent : colors.divider,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: compact
              ? Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: selected ? accent : colors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                )
              : Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: selected ? 1 : 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: selected
                              ? colors.actionPrimaryFg
                              : accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style:
                          Theme.of(context).textTheme.labelMedium?.copyWith(
                                color:
                                    selected ? accent : colors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class OrderTicketFieldRow extends StatelessWidget {
  const OrderTicketFieldRow({
    super.key,
    required this.label,
    this.child,
    this.trailing,
    this.compact = false,
  });

  final String label;
  final Widget? child;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 13 : null,
                    ),
              ),
            ),
            if (trailing != null) trailing!,
            if (child != null) ...[
              const SizedBox(width: 8),
              SizedBox(width: compact ? 118 : 132, child: child),
            ],
          ],
        ),
      ],
    );
  }
}

class OrderTicketCheckFieldRow extends StatelessWidget {
  const OrderTicketCheckFieldRow({
    super.key,
    required this.checked,
    required this.onChecked,
    required this.label,
    required this.controller,
    required this.onMinus,
    required this.onPlus,
  });

  final bool checked;
  final ValueChanged<bool> onChecked;
  final String label;
  final TextEditingController controller;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: checked,
            activeColor: colors.actionPrimaryBg,
            onChanged: (v) => onChecked(v ?? false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Opacity(
          opacity: checked ? 1 : 0.4,
          child: IgnorePointer(
            ignoring: !checked,
            child: SizedBox(
              width: 132,
              child: OrderTicketPriceStepper(
                controller: controller,
                onMinus: onMinus,
                onPlus: onPlus,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class OrderTicketPriceStepper extends StatelessWidget {
  const OrderTicketPriceStepper({
    super.key,
    required this.controller,
    required this.onMinus,
    required this.onPlus,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.compact = false,
  });

  final TextEditingController controller;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final TextInputType keyboardType;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final h = compact ? 36.0 : 42.0;
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: colors.scaffoldBackground,
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(color: colors.marketBorderDefault),
      ),
      child: Row(
        children: [
          OrderTicketStepBtn(icon: Icons.remove, onTap: onMinus, height: h),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: keyboardType,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 13 : null,
                  ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          OrderTicketStepBtn(icon: Icons.add, onTap: onPlus, height: h),
        ],
      ),
    );
  }
}

class OrderTicketStepBtn extends StatelessWidget {
  const OrderTicketStepBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.height = 42,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 36,
        height: height,
        child: Icon(icon, size: 18, color: context.colors.textSecondary),
      ),
    );
  }
}

class OrderTicketLegChip extends StatelessWidget {
  const OrderTicketLegChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(value: false, onChanged: null),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
