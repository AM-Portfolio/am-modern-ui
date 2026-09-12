import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/oms_models.dart';
import '../common/order_ticket_atoms.dart';
import '../order_ticket_controller.dart';

class PaperOrderTicketMobile extends StatelessWidget {
  const PaperOrderTicketMobile({
    super.key,
    required this.controller,
    required this.symbol,
    required this.wallet,
    required this.submitting,
    this.onOpenFundamentalAnalysis,
    this.onCloseFloat,
  });

  final OrderTicketController controller;
  final String symbol;
  final OmsWallet? wallet;
  final bool submitting;
  final VoidCallback? onOpenFundamentalAnalysis;
  final VoidCallback? onCloseFloat;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final c = controller;
    final isBuy = c.side == 'BUY';
    final ctaColor =
        isBuy ? colors.actionPrimaryBg : colors.marketNegativeIndicator;
    final fmt = NumberFormat('#,##0.00');
    final ltp = c.quote?.ltp ?? 0;
    final change = c.quote?.change ?? 0;
    final changePct = c.quote?.changePercent ?? 0;
    final priceColor = change < 0
        ? colors.marketNegativeIndicator
        : change > 0
            ? colors.marketPositiveIndicator
            : colors.textPrimary;
    final sym = symbol.trim().toUpperCase();
    const compact = true;
    const pad = EdgeInsets.fromLTRB(12, 6, 12, 4);

    return Material(
      color: colors.scaffoldBackground,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: pad,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OrderTicketHeaderBlock(
                    title: sym.isEmpty
                        ? 'Select a stock'
                        : (c.displayName.isNotEmpty ? c.displayName : sym),
                    loading: c.quoteLoading,
                    ltp: ltp,
                    change: change,
                    changePct: changePct,
                    priceColor: priceColor,
                    fmt: fmt,
                    quote: c.quote,
                    isBuy: isBuy,
                    compact: compact,
                    exchange: c.exchange,
                    onExchangeChanged: c.setExchange,
                    onBuy: () => c.setSide('BUY'),
                    onSell: () => c.setSide('SELL'),
                    floating: false,
                    onCloseFloat: onCloseFloat,
                  ),
                  if (onOpenFundamentalAnalysis != null && sym.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: onOpenFundamentalAnalysis,
                        icon: const Icon(Icons.analytics_outlined, size: 16),
                        label: const Text('Fundamentals'),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.actionPrimaryBg,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                  if (wallet != null) ...[
                    const SizedBox(height: 6),
                    OrderTicketBalanceBar(
                      available: wallet!.available,
                      compact: compact,
                    ),
                  ],
                  const SizedBox(height: 8),
                  OrderTicketOrderCard(
                    compact: compact,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            for (final t in const [
                              ('MARKET', 'Market', 'M', false),
                              ('LIMIT', 'Limit', 'L', false),
                              ('SUPER', 'SUPER', 'S', true),
                              ('TRAIL', 'Trail', 'T', false),
                            ]) ...[
                              if (t.$1 != 'MARKET') const SizedBox(width: 4),
                              Expanded(
                                child: OrderTicketTypeTab(
                                  label: t.$2,
                                  badge: t.$3,
                                  selected: c.orderType == t.$1,
                                  superStyle: t.$4,
                                  compact: compact,
                                  onTap: () => c.setOrderType(t.$1),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        OrderTicketFieldRow(
                          label: 'Shares',
                          compact: compact,
                          child: OrderTicketPriceStepper(
                            controller: c.qty,
                            onMinus: () => c.bumpQty(-1),
                            onPlus: () => c.bumpQty(1),
                            keyboardType: TextInputType.number,
                            compact: compact,
                          ),
                        ),
                        if (c.orderType == 'LIMIT' ||
                            (c.orderType == 'SUPER' && c.useLimit)) ...[
                          const SizedBox(height: 8),
                          if (c.orderType == 'SUPER')
                            OrderTicketFieldRow(
                              label: 'Limit Price',
                              compact: compact,
                              trailing: Switch.adaptive(
                                value: c.useLimit,
                                activeThumbColor: colors.actionPrimaryBg,
                                activeTrackColor: colors.actionPrimaryBg
                                    .withValues(alpha: 0.35),
                                onChanged: c.setUseLimit,
                              ),
                              child: c.useLimit
                                  ? OrderTicketPriceStepper(
                                      controller: c.limit,
                                      onMinus: () => c.bump(c.limit, -0.05),
                                      onPlus: () => c.bump(c.limit, 0.05),
                                      compact: compact,
                                    )
                                  : null,
                            )
                          else
                            OrderTicketFieldRow(
                              label: 'Limit Price',
                              compact: compact,
                              child: OrderTicketPriceStepper(
                                controller: c.limit,
                                onMinus: () => c.bump(c.limit, -0.05),
                                onPlus: () => c.bump(c.limit, 0.05),
                                compact: compact,
                              ),
                            ),
                        ],
                        if (c.orderType == 'MARKET') ...[
                          const SizedBox(height: 4),
                          Text(
                            'Executes at live market price.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: colors.textSecondary),
                          ),
                        ],
                        if (c.orderType == 'SUPER') ...[
                          const SizedBox(height: 14),
                          OrderTicketCheckFieldRow(
                            checked: c.useTarget,
                            onChecked: c.setUseTarget,
                            label: 'Target',
                            controller: c.target,
                            onMinus: () => c.bump(c.target, -0.05),
                            onPlus: () => c.bump(c.target, 0.05),
                          ),
                          const SizedBox(height: 12),
                          OrderTicketCheckFieldRow(
                            checked: c.useStop,
                            onChecked: c.setUseStop,
                            label: 'Stop Loss',
                            controller: c.stop,
                            onMinus: () => c.bump(c.stop, -0.05),
                            onPlus: () => c.bump(c.stop, 0.05),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: c.toggleShowTrigger,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: c.showTrigger,
                                      activeColor: colors.actionPrimaryBg,
                                      onChanged: (v) =>
                                          c.setShowTrigger(v ?? false),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add trigger price',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (c.showTrigger) ...[
                            const SizedBox(height: 8),
                            OrderTicketFieldRow(
                              label: 'Trigger',
                              compact: compact,
                              child: OrderTicketPriceStepper(
                                controller: c.trigger,
                                onMinus: () => c.bump(c.trigger, -0.05),
                                onPlus: () => c.bump(c.trigger, 0.05),
                                compact: compact,
                              ),
                            ),
                          ],
                        ],
                        if (c.orderType == 'TRAIL') ...[
                          const SizedBox(height: 8),
                          OrderTicketFieldRow(
                            label: 'Trail jump',
                            compact: compact,
                            child: OrderTicketPriceStepper(
                              controller: c.trail,
                              onMinus: () => c.bump(c.trail, -0.5),
                              onPlus: () => c.bump(c.trail, 0.5),
                              compact: compact,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (c.orderType == 'SUPER') ...[
                    const SizedBox(height: 8),
                    OrderTicketOrderCard(
                      compact: compact,
                      child: Column(
                        children: [
                          InkWell(
                            onTap: c.toggleBookProfitsOpen,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'On Target: Book Profits',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.actionPrimaryBg
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '100% × 1 Leg',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: colors.actionPrimaryBg,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  Icon(
                                    c.bookProfitsOpen
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: colors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (c.bookProfitsOpen) ...[
                            const SizedBox(height: 12),
                            Divider(height: 1, color: colors.divider),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Full Exit 100% at',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Qty ${c.qty.text}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: colors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 128,
                                  child: OrderTicketPriceStepper(
                                    controller: c.target,
                                    onMinus: () => c.bump(c.target, -0.05),
                                    onPlus: () => c.bump(c.target, 0.05),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'More options to exit',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: colors.textSecondary,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                OrderTicketLegChip(label: '50% × 2'),
                                OrderTicketLegChip(label: '33% × 3'),
                                OrderTicketLegChip(label: '25% × 4'),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(
              color: colors.cardSurface,
              border: Border(top: BorderSide(color: colors.divider)),
              boxShadow: [
                BoxShadow(
                  color: colors.textPrimary.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ctaColor,
                foregroundColor: colors.actionPrimaryFg,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: submitting || c.localSubmitting || sym.isEmpty
                  ? null
                  : () => c.submit(context, symbol: symbol),
              child: Text(
                submitting || c.localSubmitting
                    ? 'Submitting…'
                    : 'Instant ${isBuy ? 'Buy' : 'Sell'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
