import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../internal/domain/entities/portfolio_analytics.dart';
import 'movers_join.dart';
import 'movers_tabs.dart';

/// Main-branch compact mover row. Metric tabs only swap the right-hand numbers.
class MoverTile extends StatefulWidget {
  const MoverTile({
    super.key,
    required this.stock,
    required this.isGainer,
    this.metric = MoverMetric.today,
    this.isLast = false,
  });

  final Stock stock;
  final bool isGainer;
  final MoverMetric metric;
  final bool isLast;

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

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.only(bottom: widget.isLast ? 0 : 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        transform: _hovered
            ? (Matrix4.diagonal3Values(1.015, 1.015, 1.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: _hovered
              ? color.withValues(alpha: 0.08)
              : context.colors.surface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered
                ? color.withValues(alpha: 0.35)
                : color.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.12),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                isPositive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 14,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                stock.symbol,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(widget.metric),
                child: _MetricNumbers(
                  stock: stock,
                  metric: widget.metric,
                  color: color,
                ),
              ),
            ),
            if (widget.metric == MoverMetric.today) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color.withValues(alpha: 0.35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 6,
                      spreadRadius: -1,
                    ),
                  ],
                ),
                child: Text(
                  stock.changePercent.abs() < 0.005
                      ? '0.00%'
                      : '${stock.changePercent >= 0 ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricNumbers extends StatelessWidget {
  const _MetricNumbers({
    required this.stock,
    required this.metric,
    required this.color,
  });

  final Stock stock;
  final MoverMetric metric;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    final secondary = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: Theme.of(context)
          .colorScheme
          .onSurfaceVariant
          .withValues(alpha: 0.75),
    );
    final pos = context.colors.marketPositiveIndicator;
    final neg = context.colors.marketNegativeIndicator;

    switch (metric) {
      case MoverMetric.today:
        return _StackedPair(
          primary: _Line('₹${stock.lastPrice.toStringAsFixed(2)}'),
          secondary: _Line(stock.formattedChangeAmount, color: color),
          muted: muted,
          caption: secondary,
        );
      case MoverMetric.pnl:
        final pnl = moverDisplayPnl(stock);
        Color? pnlColor;
        if (pnl != null && pnl > 0) pnlColor = pos;
        if (pnl != null && pnl < 0) pnlColor = neg;
        return _SplitPair(
          mid: _Line(pnl == null ? '—' : formatSignedInr(pnl), color: pnlColor),
          right: _Line(
            stock.marketValue == null
                ? '—'
                : formatMoverInr(stock.marketValue!),
          ),
          muted: muted,
          caption: secondary,
        );
      case MoverMetric.cost:
        final qty = stock.quantity;
        final hasQty = qty != null && qty > 0;
        final invested = stock.investedAmount;
        final avg = stock.avgPrice;
        final investedText = stock.hasCostBasis &&
                invested != null &&
                invested > 0
            ? formatMoverInr(invested)
            : '—';
        return _SplitPair(
          mid: _Line(hasQty ? formatMoverQty(qty) : '—'),
          midCaption: hasQty ? 'shares' : null,
          right: _Line(investedText),
          rightCaption: stock.hasCostBasis && avg != null && avg > 0
              ? 'avg ₹${avg.toStringAsFixed(2)}'
              : null,
          muted: muted,
          caption: secondary,
        );
    }
  }
}

class _Line {
  const _Line(this.text, {this.color});
  final String text;
  final Color? color;
}

class _StackedPair extends StatelessWidget {
  const _StackedPair({
    required this.primary,
    required this.secondary,
    required this.muted,
    required this.caption,
  });

  final _Line primary;
  final _Line secondary;
  final TextStyle? muted;
  final TextStyle caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          primary.text,
          style: primary.color != null
              ? muted?.copyWith(color: primary.color)
              : muted,
        ),
        Text(
          secondary.text,
          style: caption.copyWith(color: secondary.color ?? caption.color),
        ),
      ],
    );
  }
}

/// Qty / P&L on the left of a rule, invested / value on the right.
class _SplitPair extends StatelessWidget {
  const _SplitPair({
    required this.mid,
    this.midCaption,
    required this.right,
    this.rightCaption,
    required this.muted,
    required this.caption,
  });

  final _Line mid;
  final String? midCaption;
  final _Line right;
  final String? rightCaption;
  final TextStyle? muted;
  final TextStyle caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _captioned(mid, midCaption),
        Container(
          key: const ValueKey('mover-metric-split'),
          width: 1,
          height: 22,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant
              .withValues(alpha: 0.28),
        ),
        _captioned(right, rightCaption),
      ],
    );
  }

  Widget _captioned(_Line primary, String? sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          primary.text,
          style: primary.color != null
              ? muted?.copyWith(color: primary.color)
              : muted,
        ),
        if (sub != null) Text(sub, style: caption),
      ],
    );
  }
}
