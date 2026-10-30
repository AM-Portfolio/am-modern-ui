// Unused backup of the six-column table experiment.
// Overview uses compact MoverTile + Value/Percentage toggle instead. Do not delete.
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../internal/domain/entities/portfolio_analytics.dart';
import 'movers_join.dart';
import 'movers_mobile_rows.dart';
import 'movers_table_cells.dart';

class MoversTable extends StatelessWidget {
  const MoversTable({
    super.key,
    required this.stocks,
    required this.showCost,
    required this.isGainers,
    this.compact = false,
    this.maxRows = 5,
  });

  final List<Stock> stocks;
  final bool showCost;
  final bool isGainers;
  final bool compact;
  final int maxRows;

  static const double minWideWithCost = 760;
  static const double minWideNoCost = 560;

  @override
  Widget build(BuildContext context) {
    if (stocks.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 12 : 20),
        child: Center(
          child: Text(
            'No ${isGainers ? 'gainers' : 'losers'} today',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final shown = stocks.take(maxRows).toList();
    final minWide = showCost ? minWideWithCost : minWideNoCost;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < minWide) {
          return MoversMobileRows(
            stocks: shown,
            showCost: showCost,
          );
        }
        if (!showCost) {
          return _MoversNoCostRows(
            stocks: shown,
            isGainers: isGainers,
            compact: compact,
          );
        }
        return _MoversDesktopTable(
          stocks: shown,
          isGainers: isGainers,
          compact: compact,
        );
      },
    );
  }
}

class _MoversDesktopTable extends StatelessWidget {
  const _MoversDesktopTable({
    required this.stocks,
    required this.isGainers,
    required this.compact,
  });

  final List<Stock> stocks;
  final bool isGainers;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context)
        .colorScheme
        .onSurfaceVariant
        .withValues(alpha: 0.75);
    final pnlAccent = isGainers
        ? context.colors.marketPositiveIndicator
        : context.colors.marketNegativeIndicator;
    const cellPad = EdgeInsets.symmetric(horizontal: 8, vertical: 10);
    final widths = <int, TableColumnWidth>{
      0: const FlexColumnWidth(22),
      1: const FlexColumnWidth(8),
      2: const FlexColumnWidth(13),
      3: const FlexColumnWidth(13),
      4: const FlexColumnWidth(13),
      5: const FlexColumnWidth(12),
    };

    Widget cell(
      Widget child, {
      Alignment align = Alignment.centerRight,
    }) {
      return Padding(
        padding: cellPad,
        child: SizedBox(
          width: double.infinity,
          child: Align(alignment: align, child: child),
        ),
      );
    }

    Widget headerLabel(
      String label, {
      bool end = true,
      Color? color,
    }) {
      return cell(
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color ?? muted,
          ),
        ),
        align: end ? Alignment.centerRight : Alignment.centerLeft,
      );
    }

    Widget money({
      required String primary,
      String? secondary,
      Color? secondaryColor,
    }) {
      return cell(
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              primary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 12 : 13,
                  ),
            ),
            if (secondary != null)
              Text(
                secondary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: secondaryColor ??
                      Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      );
    }

    final header = TableRow(
      children: [
        headerLabel('Stock', end: false),
        headerLabel('Qty'),
        headerLabel('Invested'),
        headerLabel('LTP'),
        headerLabel('Current Value'),
        headerLabel('P&L', color: pnlAccent),
      ],
    );

    TableRow dataRow(Stock stock) {
      final subtitle = moverSubtitle(stock);
      final qty = (stock.quantity != null && stock.quantity! > 0)
          ? formatMoverQty(stock.quantity!)
          : '—';
      final invested = stock.hasCostBasis && stock.investedAmount != null
          ? formatMoverInr(stock.investedAmount!)
          : null;
      final avg = stock.hasCostBasis && stock.avgPrice != null
          ? '${formatMoverInr(stock.avgPrice!)} avg'
          : null;
      final ltp = stock.lastPrice > 0 ? formatMoverInr(stock.lastPrice) : '—';
      final dayColor = stock.changePercent > 0.005
          ? context.colors.marketPositiveIndicator
          : stock.changePercent < -0.005
              ? context.colors.marketNegativeIndicator
              : Theme.of(context).colorScheme.onSurfaceVariant;
      final dayLine = stock.lastPrice > 0 &&
              (stock.changeAmount != 0 || stock.changePercent != 0)
          ? '${formatSignedInr(stock.changeAmount)} (${formatSignedPct(stock.changePercent)})'
          : null;
      final value = stock.marketValue != null && stock.marketValue! > 0
          ? formatMoverInr(stock.marketValue!)
          : '—';
      final pnl = moverDisplayPnl(stock);
      final pnlPct = moverDisplayPnlPercent(stock);

      return TableRow(
        decoration: BoxDecoration(
          color: context.colors.surface.withValues(alpha: 0.06),
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
            ),
          ),
        ),
        children: [
          cell(
            Row(
              children: [
                MoverSymbolAvatar(
                  symbol: stock.symbol,
                  size: compact ? 32 : 36,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stock.symbol,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: compact ? 12 : 13,
                                ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            align: Alignment.centerLeft,
          ),
          money(primary: qty),
          money(primary: invested ?? '—', secondary: avg),
          money(primary: ltp, secondary: dayLine, secondaryColor: dayColor),
          money(primary: value),
          cell(
            MoverPnlChip(
              amount: pnl,
              percent: pnlPct,
              compact: compact,
            ),
          ),
        ],
      );
    }

    return Table(
      columnWidths: widths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [header, ...stocks.map(dataRow)],
    );
  }
}

/// Dhan-style books: no Invested. Packed card rows instead of a stretched table.
class _MoversNoCostRows extends StatelessWidget {
  const _MoversNoCostRows({
    required this.stocks,
    required this.isGainers,
    required this.compact,
  });

  final List<Stock> stocks;
  final bool isGainers;
  final bool compact;

  static const _flex = [5, 2, 3, 3, 2];

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context)
        .colorScheme
        .onSurfaceVariant
        .withValues(alpha: 0.75);
    final pnlAccent = isGainers
        ? context.colors.marketPositiveIndicator
        : context.colors.marketNegativeIndicator;

    Widget head(String label, int flex, {bool end = true, Color? color}) {
      return Expanded(
        flex: flex,
        child: Align(
          alignment: end ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color ?? muted,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              head('Stock', _flex[0], end: false),
              head('Qty', _flex[1]),
              head('LTP', _flex[2]),
              head('Current Value', _flex[3]),
              const SizedBox(width: 10),
              head('P&L', _flex[4], color: pnlAccent),
            ],
          ),
        ),
        ...stocks.map(
          (stock) => _NoCostMoverCard(
            stock: stock,
            compact: compact,
          ),
        ),
      ],
    );
  }
}

class _NoCostMoverCard extends StatelessWidget {
  const _NoCostMoverCard({
    required this.stock,
    required this.compact,
  });

  final Stock stock;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final subtitle = moverSubtitle(stock);
    final qty = (stock.quantity != null && stock.quantity! > 0)
        ? formatMoverQty(stock.quantity!)
        : '—';
    final ltp = stock.lastPrice > 0 ? formatMoverInr(stock.lastPrice) : '—';
    final dayColor = stock.changePercent > 0.005
        ? context.colors.marketPositiveIndicator
        : stock.changePercent < -0.005
            ? context.colors.marketNegativeIndicator
            : Theme.of(context).colorScheme.onSurfaceVariant;
    final dayLine = stock.lastPrice > 0 &&
            (stock.changeAmount != 0 || stock.changePercent != 0)
        ? '${formatSignedInr(stock.changeAmount)} (${formatSignedPct(stock.changePercent)})'
        : null;
    final value = stock.marketValue != null && stock.marketValue! > 0
        ? formatMoverInr(stock.marketValue!)
        : '—';
    final fontSize = compact ? 12.0 : 13.0;

    Widget col({
      required int flex,
      required String primary,
      String? secondary,
      Color? secondaryColor,
      bool end = true,
      Widget? child,
    }) {
      return Expanded(
        flex: flex,
        child: Align(
          alignment: end ? Alignment.centerRight : Alignment.centerLeft,
          child: child ??
              Column(
                crossAxisAlignment:
                    end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    primary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: fontSize,
                        ),
                  ),
                  if (secondary != null)
                    Text(
                      secondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: secondaryColor ??
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.colors.surface.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          children: [
            col(
              flex: _MoversNoCostRows._flex[0],
              primary: '',
              end: false,
              child: Row(
                children: [
                  MoverSymbolAvatar(
                    symbol: stock.symbol,
                    size: compact ? 28 : 32,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          stock.symbol,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: fontSize,
                                  ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            col(flex: _MoversNoCostRows._flex[1], primary: qty),
            col(
              flex: _MoversNoCostRows._flex[2],
              primary: ltp,
              secondary: dayLine,
              secondaryColor: dayColor,
            ),
            col(flex: _MoversNoCostRows._flex[3], primary: value),
            const SizedBox(width: 10),
            col(
              flex: _MoversNoCostRows._flex[4],
              primary: '',
              child: MoverPnlChip(
                amount: moverDisplayPnl(stock),
                percent: moverDisplayPnlPercent(stock),
                compact: true,
                minWidth: 72,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
