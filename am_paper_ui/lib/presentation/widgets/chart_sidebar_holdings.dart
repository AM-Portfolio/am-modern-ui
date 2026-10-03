import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/oms_models.dart';
import '../../data/paper_market_client.dart';
import '../../data/watchlist_models.dart';
import '../paper_oms_cubit.dart';
import '../paper_oms_state.dart';

/// Compact holdings P&L for chart terminal sidebar. Hidden when empty.
class ChartSidebarHoldings extends StatefulWidget {
  const ChartSidebarHoldings({
    super.key,
    required this.onSelectSymbol,
    this.hideTitle = false,
  });

  final ValueChanged<String> onSelectSymbol;

  /// When true, skip the inner "Holdings" label (parent accordion already titles).
  final bool hideTitle;

  @override
  State<ChartSidebarHoldings> createState() => _ChartSidebarHoldingsState();
}

class _ChartSidebarHoldingsState extends State<ChartSidebarHoldings> {
  final _market = PaperMarketClient();
  final Map<String, double> _ltp = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final positions = context.read<PaperOmsCubit>().state.positions;
    _loadLtps(positions);
  }

  Future<void> _loadLtps(List<OmsPosition> positions) async {
    if (positions.isEmpty) return;
    final stubs = [
      for (final p in positions)
        if (p.symbol.trim().isNotEmpty)
          WatchlistStock(
            symbol: p.symbol.trim().toUpperCase(),
            name: p.symbol.trim().toUpperCase(),
            exchange: 'NSE',
            ltp: 0,
            change: 0,
            changePercent: 0,
          ),
    ];
    final enriched = await _market.enrichQuotes(stubs);
    if (!mounted) return;
    setState(() {
      _ltp
        ..clear()
        ..addAll({
          for (final r in enriched)
            if (r.ltp > 0) r.symbol: r.ltp,
        });
    });
  }

  Map<String, double> _avgFromFills(List<OmsOrder> orders) {
    final filled = orders.where((o) => o.isFilled).toList()
      ..sort((a, b) {
        final ac = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bc = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ac.compareTo(bc);
      });
    final qty = <String, double>{};
    final avg = <String, double>{};
    for (final o in filled) {
      final sym = o.symbol.trim().toUpperCase();
      if (sym.isEmpty) continue;
      final q = o.filledQuantityAsDouble;
      final px = o.fillPriceAsDouble;
      if (q <= 0) continue;
      final curQty = qty[sym] ?? 0;
      final curAvg = avg[sym] ?? 0;
      if (o.side == 'BUY') {
        final newQty = curQty + q;
        avg[sym] = newQty <= 0 ? 0 : ((curAvg * curQty) + (px * q)) / newQty;
        qty[sym] = newQty;
      } else if (o.side == 'SELL') {
        final sellQty = q.clamp(0, curQty > 0 ? curQty : q);
        final newQty = curQty - sellQty;
        qty[sym] = newQty;
        if (newQty <= 0) avg[sym] = 0;
      }
    }
    return avg;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaperOmsCubit, PaperOmsState>(
      buildWhen: (p, c) => p.positions != c.positions || p.orders != c.orders,
      builder: (context, state) {
        if (state.positions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'No paper positions',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        final avgs = _avgFromFills(state.orders);
        final fmt = NumberFormat('#,##0.00');
        final colors = context.colors;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.hideTitle) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                child: Text(
                  'Holdings',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: state.positions.length,
                itemBuilder: (context, i) {
                  final p = state.positions[i];
                  final sym = p.symbol.trim().toUpperCase();
                  final q = double.tryParse(p.qty) ?? 0;
                  if (sym.isEmpty || q == 0) return const SizedBox.shrink();
                  final avg = avgs[sym] ?? 0;
                  final ltp = _ltp[sym] ?? 0;
                  final unrealized =
                      ltp > 0 && avg > 0 ? (ltp - avg) * q : 0.0;
                  final cost = avg * q.abs();
                  final pct = cost > 0 ? (unrealized / cost) * 100 : 0.0;
                  final pnlColor = unrealized < 0
                      ? colors.statusError
                      : unrealized > 0
                          ? colors.marketPositiveIndicator
                          : colors.textPrimary;

                  return InkWell(
                    onTap: () => widget.onSelectSymbol(sym),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(sym,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                          Text('${q.toStringAsFixed(q % 1 == 0 ? 0 : 1)}',
                              style: const TextStyle(fontSize: 10)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ltp > 0 ? fmt.format(ltp) : '—',
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 72,
                            child: Text(
                              '${unrealized >= 0 ? '+' : ''}${fmt.format(unrealized)}\n${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: 9,
                                height: 1.2,
                                color: pnlColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Recent paper orders for chart terminal sidebar. Hidden when empty.
///
/// When [expanded] / [onToggle] are set, the list is collapsible under a header.
/// Otherwise defaults to collapsed with local toggle state.
class ChartSidebarRecentHistory extends StatefulWidget {
  const ChartSidebarRecentHistory({
    super.key,
    required this.onSelectSymbol,
    this.limit = 8,
    this.expanded,
    this.onToggle,
  });

  final ValueChanged<String> onSelectSymbol;
  final int limit;

  /// Controlled expand state. When null, uses local state (default collapsed).
  final bool? expanded;
  final VoidCallback? onToggle;

  @override
  State<ChartSidebarRecentHistory> createState() =>
      _ChartSidebarRecentHistoryState();
}

class _ChartSidebarRecentHistoryState extends State<ChartSidebarRecentHistory> {
  bool _localExpanded = false;

  bool get _expanded => widget.expanded ?? _localExpanded;

  void _toggle() {
    if (widget.onToggle != null) {
      widget.onToggle!();
    } else {
      setState(() => _localExpanded = !_localExpanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaperOmsCubit, PaperOmsState>(
      buildWhen: (p, c) => p.orders != c.orders,
      builder: (context, state) {
        if (state.orders.isEmpty) return const SizedBox.shrink();
        final orders = [...state.orders]
          ..sort((a, b) {
            final ac = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bc = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bc.compareTo(ac);
          });
        final slice = orders.take(widget.limit).toList();
        final timeFmt = DateFormat('HH:mm');
        final priceFmt = NumberFormat('#,##0.00');
        final colors = context.colors;
        final theme = Theme.of(context);
        final expanded = _expanded;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 1),
            InkWell(
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recent',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: theme.hintColor,
                    ),
                  ],
                ),
              ),
            ),
            if (expanded)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 168),
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 6),
                  shrinkWrap: true,
                  itemCount: slice.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 10,
                    endIndent: 10,
                    color: theme.dividerColor.withValues(alpha: 0.35),
                  ),
                  itemBuilder: (context, i) {
                    final o = slice[i];
                    final isBuy = o.side == 'BUY';
                    final sideColor = isBuy
                        ? colors.marketPositiveIndicator
                        : colors.statusError;
                    final fillPx = o.fillPriceAsDouble;
                    final showFill = o.isFilled && fillPx > 0;

                    return InkWell(
                      onTap: () {
                        final sym = o.symbol.trim().toUpperCase();
                        if (sym.isNotEmpty) widget.onSelectSymbol(sym);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sideColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isBuy ? 'BUY' : 'SELL',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                      color: sideColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${o.symbol.trim().toUpperCase()} · ${o.quantity}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    o.displayStatus,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: theme.hintColor,
                                    ),
                                  ),
                                ),
                                if (o.createdAt != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    timeFmt.format(o.createdAt!.toLocal()),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.hintColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (showFill) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Fill @ ${priceFmt.format(fillPx)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

