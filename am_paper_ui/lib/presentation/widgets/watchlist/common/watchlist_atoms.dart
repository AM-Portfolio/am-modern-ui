import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/quote_models.dart';
import '../../../../data/watchlist_models.dart';
import '../watchlist_controller.dart';

/// Watchlist interactive chrome — theme brand (Imperial Gold → gold, not LTP teal).
Color _watchlistAccent(BuildContext context) => context.colors.actionPrimaryBg;

class WatchlistSourceDropdown extends StatelessWidget {
  const WatchlistSourceDropdown({
    super.key,
    required this.selected,
    required this.sources,
    required this.onSelected,
  });

  final WatchlistSource selected;
  final List<WatchlistSource> sources;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final accent = _watchlistAccent(context);
    return PopupMenuButton<String>(
      tooltip: 'Choose watchlist',
      onSelected: onSelected,
      offset: const Offset(0, 40),
      itemBuilder: (context) => [
        for (final s in sources)
          PopupMenuItem(
            value: s.id,
            child: Text(s.name),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: accent.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.bookmark, size: 18, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selected.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: accent),
          ],
        ),
      ),
    );
  }
}

class WatchlistPageChips extends StatelessWidget {
  const WatchlistPageChips({
    super.key,
    required this.pageCount,
    required this.pageIndex,
    required this.onSelect,
  });

  final int pageCount;
  final int pageIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = _watchlistAccent(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < pageCount; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            InkWell(
              onTap: () => onSelect(i),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: i == pageIndex ? accent : colors.border,
                  ),
                ),
                child: Text(
                  '${i + 1}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: i == pageIndex ? accent : colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class WatchlistRow extends StatelessWidget {
  const WatchlistRow({
    super.key,
    required this.stock,
    required this.selected,
    required this.showActions,
    required this.depthExpanded,
    required this.enableHover,
    required this.onHover,
    required this.onTap,
    required this.onBuy,
    required this.onSell,
    required this.onFundamentals,
    required this.onRemove,
  });

  final WatchlistStock stock;
  final bool selected;
  final bool showActions;
  final bool depthExpanded;
  final bool enableHover;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;
  final VoidCallback onBuy;
  final VoidCallback onSell;
  final VoidCallback onFundamentals;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final priceColor = stock.isNegative
        ? colors.marketNegativeIndicator
        : stock.isPositive
            ? colors.marketPositiveIndicator
            : colors.textPrimary;
    final fmt = NumberFormat('#,##0.00');

    final row = Material(
      color: selected || depthExpanded
          ? colors.actionPrimaryBg.withValues(alpha: 0.08)
          : colors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.symbol,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stock.exchange,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (showActions)
                WatchlistActionToolbar(
                  onBuy: onBuy,
                  onSell: onSell,
                  onFundamentals: onFundamentals,
                  onRemove: onRemove,
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          stock.ltp > 0 ? fmt.format(stock.ltp) : '—',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: priceColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        if (stock.ltp > 0) ...[
                          const SizedBox(width: 4),
                          Icon(
                            stock.isNegative
                                ? Icons.arrow_drop_down
                                : Icons.arrow_drop_up,
                            size: 18,
                            color: priceColor,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      stock.ltp > 0
                          ? '${fmt.format(stock.change)} (${stock.changePercent.toStringAsFixed(2)}%)'
                          : '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: priceColor,
                          ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );

    if (!enableHover) return row;
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: row,
    );
  }
}

class WatchlistActionToolbar extends StatelessWidget {
  const WatchlistActionToolbar({
    super.key,
    required this.onBuy,
    required this.onSell,
    required this.onFundamentals,
    required this.onRemove,
  });

  final VoidCallback onBuy;
  final VoidCallback onSell;
  final VoidCallback onFundamentals;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        WatchlistSq(
          label: 'B',
          bg: _watchlistAccent(context),
          onTap: onBuy,
        ),
        const SizedBox(width: 4),
        WatchlistSq(
          label: 'S',
          bg: colors.marketNegativeIndicator,
          onTap: onSell,
        ),
        const SizedBox(width: 2),
        IconButton(
          tooltip: 'Fundamental analysis',
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          onPressed: onFundamentals,
          icon: Icon(
            Icons.analytics_outlined,
            color: _watchlistAccent(context),
          ),
        ),
        IconButton(
          tooltip: 'Remove',
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          onPressed: onRemove,
          icon: Icon(Icons.close, color: colors.textSecondary),
        ),
      ],
    );
  }
}

class WatchlistDepthExpandPanel extends StatelessWidget {
  const WatchlistDepthExpandPanel({
    super.key,
    required this.loading,
    required this.quote,
  });

  final bool loading;
  final QuoteDetail? quote;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fmt = NumberFormat('#,##0.00');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: colors.scaffoldBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.divider),
      ),
      child: loading
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.actionPrimaryBg,
                  ),
                ),
              ),
            )
          : quote == null
              ? Text(
                  'Unable to load quote',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Market depth',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    WatchlistDepthPressureBar(quote: quote!),
                    const SizedBox(height: 8),
                    WatchlistDepthTable(quote: quote!, fmt: fmt),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1, color: colors.divider),
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        WatchlistStat(
                          label: 'LTP',
                          value: quote!.ltp > 0 ? fmt.format(quote!.ltp) : '—',
                        ),
                        WatchlistStat(
                          label: 'Open',
                          value: quote!.open != null
                              ? fmt.format(quote!.open)
                              : '—',
                        ),
                        WatchlistStat(
                          label: 'Prev close',
                          value: quote!.previousClose != null
                              ? fmt.format(quote!.previousClose)
                              : '—',
                        ),
                        WatchlistStat(
                          label: 'High',
                          value: quote!.high != null
                              ? fmt.format(quote!.high)
                              : '—',
                        ),
                        WatchlistStat(
                          label: 'Low',
                          value:
                              quote!.low != null ? fmt.format(quote!.low) : '—',
                        ),
                        WatchlistStat(
                          label: 'Vol traded',
                          value: quote!.volume != null && quote!.volume! > 0
                              ? NumberFormat.compact().format(quote!.volume)
                              : '—',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    WatchlistLtpRangeBar(
                      low: quote!.low,
                      high: quote!.high,
                      ltp: quote!.ltp,
                      fmt: fmt,
                    ),
                  ],
                ),
    );
  }
}

class WatchlistStat extends StatelessWidget {
  const WatchlistStat({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 88,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Bid vs ask book pressure (qty / orders) as a proportional bar.
class WatchlistDepthPressureBar extends StatelessWidget {
  const WatchlistDepthPressureBar({super.key, required this.quote});

  final QuoteDetail quote;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final buyQty = quote.totalBuyQty;
    final sellQty = quote.totalSellQty;
    final buyOrders = quote.totalBuyOrders;
    final sellOrders = quote.totalSellOrders;
    final totalQty = buyQty + sellQty;
    final buyFrac = totalQty > 0 ? buyQty / totalQty : 0.5;

    final hasOrders = buyOrders > 0 || sellOrders > 0;
    final meta = hasOrders
        ? 'Buy $buyQty ($buyOrders ord) · Sell $sellQty ($sellOrders ord)'
        : 'Buy $buyQty · Sell $sellQty';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Book',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                meta,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                Expanded(
                  flex: (buyFrac * 1000).round().clamp(1, 999),
                  child: ColoredBox(color: colors.marketPositiveIndicator),
                ),
                Expanded(
                  flex: ((1 - buyFrac) * 1000).round().clamp(1, 999),
                  child: ColoredBox(color: colors.marketNegativeIndicator),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Day range: Low ──●── High with LTP as the marker.
class WatchlistLtpRangeBar extends StatelessWidget {
  const WatchlistLtpRangeBar({
    super.key,
    required this.low,
    required this.high,
    required this.ltp,
    required this.fmt,
  });

  final double? low;
  final double? high;
  final double ltp;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lo = low;
    final hi = high;
    final hasRange = lo != null && hi != null && hi > lo && ltp > 0;
    final t = hasRange ? ((ltp - lo) / (hi - lo)).clamp(0.0, 1.0) : 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Day range',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const Spacer(),
            Text(
              hasRange ? 'LTP ${fmt.format(ltp)}' : 'Range unavailable',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final markerX = hasRange ? t * w : w * 0.5;
            return SizedBox(
              height: 18,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 7,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          colors: [
                            colors.marketPositiveIndicator.withValues(
                              alpha: 0.35,
                            ),
                            colors.actionPrimaryBg.withValues(alpha: 0.55),
                            colors.marketNegativeIndicator.withValues(
                              alpha: 0.35,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (markerX - 6).clamp(0.0, w - 12),
                    top: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors.actionPrimaryBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.actionPrimaryFg.withValues(alpha: 0.35),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.actionPrimaryBg.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'Min ${lo != null ? fmt.format(lo) : '—'}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const Spacer(),
            Text(
              'Max ${hi != null ? fmt.format(hi) : '—'}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class WatchlistDepthTable extends StatelessWidget {
  const WatchlistDepthTable({
    super.key,
    required this.quote,
    required this.fmt,
  });

  final QuoteDetail quote;
  final NumberFormat fmt;
  static const _rowCount = 5;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rows = _rowCount;
    var maxQty = 1;
    for (final e in quote.buyDepth) {
      if (e.quantity > maxQty) maxQty = e.quantity;
    }
    for (final e in quote.sellDepth) {
      if (e.quantity > maxQty) maxQty = e.quantity;
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Bid qty',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                'Bid',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.marketPositiveIndicator,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ask',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.marketNegativeIndicator,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                'Ask qty',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (var i = 0; i < rows; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: _DepthQtyCell(
                    quantity: i < quote.buyDepth.length
                        ? quote.buyDepth[i].quantity
                        : 0,
                    orders: i < quote.buyDepth.length
                        ? quote.buyDepth[i].orders
                        : null,
                    maxQuantity: maxQty,
                    barColor: colors.marketPositiveIndicator,
                    alignEnd: false,
                  ),
                ),
                Expanded(
                  child: Text(
                    i < quote.buyDepth.length
                        ? fmt.format(quote.buyDepth[i].price)
                        : fmt.format(0),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.marketPositiveIndicator,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    i < quote.sellDepth.length
                        ? fmt.format(quote.sellDepth[i].price)
                        : fmt.format(0),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.marketNegativeIndicator,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Expanded(
                  child: _DepthQtyCell(
                    quantity: i < quote.sellDepth.length
                        ? quote.sellDepth[i].quantity
                        : 0,
                    orders: i < quote.sellDepth.length
                        ? quote.sellDepth[i].orders
                        : null,
                    maxQuantity: maxQty,
                    barColor: colors.marketNegativeIndicator,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DepthQtyCell extends StatelessWidget {
  const _DepthQtyCell({
    required this.quantity,
    required this.orders,
    required this.maxQuantity,
    required this.barColor,
    required this.alignEnd,
  });

  final int quantity;
  final int? orders;
  final int maxQuantity;
  final Color barColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final frac = maxQuantity > 0 ? (quantity / maxQuantity).clamp(0.0, 1.0) : 0.0;
    final label = orders != null && orders! > 0
        ? '$quantity ($orders)'
        : '$quantity';

    return SizedBox(
      height: 20,
      child: Stack(
        children: [
          Positioned.fill(
            child: FractionallySizedBox(
              alignment:
                  alignEnd ? Alignment.centerRight : Alignment.centerLeft,
              widthFactor: frac,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Align(
            alignment:
                alignEnd ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class WatchlistSq extends StatelessWidget {
  const WatchlistSq({
    super.key,
    required this.label,
    required this.bg,
    required this.onTap,
  });

  final String label;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: context.colors.actionPrimaryFg,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
