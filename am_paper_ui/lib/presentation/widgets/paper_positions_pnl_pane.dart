import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/oms_models.dart';
import '../../data/paper_market_client.dart';
import '../paper_oms_cubit.dart';
import '../paper_oms_state.dart';

class _PosRow {
  const _PosRow({
    required this.symbol,
    required this.qty,
    required this.avg,
    required this.ltp,
    required this.unrealized,
    required this.unrealizedPct,
  });

  final String symbol;
  final double qty;
  final double avg;
  final double ltp;
  final double unrealized;
  final double unrealizedPct;
}

/// Open positions with today's P&L — adaptive table/card.
class PaperPositionsPnlPane extends StatefulWidget {
  const PaperPositionsPnlPane({super.key});

  @override
  State<PaperPositionsPnlPane> createState() => _PaperPositionsPnlPaneState();
}

class _PaperPositionsPnlPaneState extends State<PaperPositionsPnlPane> {
  final _market = PaperMarketClient();
  final Map<String, double> _ltpBySymbol = {};
  bool _loadingLtp = false;
  String? _lastPosKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeRefreshLtps();
  }

  void _maybeRefreshLtps() {
    final state = context.read<PaperOmsCubit>().state;
    final key = state.positions.map((p) => '${p.symbol}:${p.qty}').join('|');
    if (key == _lastPosKey && _ltpBySymbol.isNotEmpty) return;
    _lastPosKey = key;
    _loadLtps(state.positions);
  }

  Future<void> _loadLtps(List<OmsPosition> positions) async {
    if (positions.isEmpty) {
      if (mounted) {
        setState(() {
          _ltpBySymbol.clear();
          _loadingLtp = false;
        });
      }
      return;
    }
    setState(() => _loadingLtp = true);
    final next = <String, double>{};
    await Future.wait(positions.map((p) async {
      final sym = p.symbol.trim().toUpperCase();
      if (sym.isEmpty) return;
      final q = await _market.fetchQuoteDetail(sym, forceRefresh: true);
      if (q != null && q.ltp > 0) {
        next[sym] = q.ltp;
      }
    }));
    if (!mounted) return;
    setState(() {
      _ltpBySymbol
        ..clear()
        ..addAll(next);
      _loadingLtp = false;
    });
  }

  static ({Map<String, double> avg, double todayRealized}) _computeFromFills(
    List<OmsOrder> orders,
  ) {
    final filled = orders.where((o) => o.isFilled).toList()
      ..sort((a, b) {
        final ac = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bc = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ac.compareTo(bc);
      });

    final qty = <String, double>{};
    final avg = <String, double>{};
    var todayRealized = 0.0;

    for (final o in filled) {
      final sym = o.symbol.trim().toUpperCase();
      if (sym.isEmpty) continue;
      final q = o.filledQuantityAsDouble;
      final px = o.fillPriceAsDouble;
      if (q <= 0) continue;

      final side = o.side.toUpperCase();
      final curQty = qty[sym] ?? 0;
      final curAvg = avg[sym] ?? 0;

      if (side == 'BUY') {
        final newQty = curQty + q;
        avg[sym] = newQty <= 0 ? 0 : ((curAvg * curQty) + (px * q)) / newQty;
        qty[sym] = newQty;
      } else if (side == 'SELL') {
        final sellQty = q.clamp(0, curQty > 0 ? curQty : q);
        final realized = (px - curAvg) * sellQty;
        if (o.isCreatedToday) {
          todayRealized += realized;
        }
        final newQty = curQty - sellQty;
        qty[sym] = newQty;
        if (newQty <= 0) {
          avg[sym] = 0;
          qty[sym] = 0;
        }
      }
    }

    return (avg: avg, todayRealized: todayRealized);
  }

  List<_PosRow> _rows(PaperOmsState state) {
    final computed = _computeFromFills(state.orders);
    final rows = <_PosRow>[];
    for (final p in state.positions) {
      final sym = p.symbol.trim().toUpperCase();
      final q = double.tryParse(p.qty) ?? 0;
      if (sym.isEmpty || q == 0) continue;
      final avg = computed.avg[sym] ?? 0;
      final ltp = _ltpBySymbol[sym] ?? 0;
      final cost = avg * q.abs();
      final unrealized = ltp > 0 && avg > 0 ? (ltp - avg) * q : 0.0;
      final pct = cost > 0 ? (unrealized / cost) * 100 : 0.0;
      rows.add(
        _PosRow(
          symbol: sym,
          qty: q,
          avg: avg,
          ltp: ltp,
          unrealized: unrealized,
          unrealizedPct: pct,
        ),
      );
    }
    return rows;
  }

  Color _pnlColor(BuildContext context, double v) {
    final colors = context.colors;
    if (v < 0) return colors.statusError;
    if (v > 0) return colors.marketPositiveIndicator;
    return colors.textPrimary;
  }

  Widget _buildTable(BuildContext context, List<_PosRow> items) {
    final fmt = NumberFormat('#,##0.00');
    return SortableTable<_PosRow>(
      items: items,
      initialSortColumnIndex: 0,
      initialSortDirection: SortDirection.ascending,
      columns: [
        SortableColumn(
          title: 'Symbol',
          flex: 2,
          sortBy: (p) => p.symbol,
          builder: (p) => Text(
            p.symbol,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        SortableColumn(
          title: 'Qty',
          sortBy: (p) => p.qty,
          textAlign: TextAlign.end,
          builder: (p) => Text(
            p.qty.toStringAsFixed(0),
            textAlign: TextAlign.end,
          ),
        ),
        SortableColumn(
          title: 'Avg',
          sortBy: (p) => p.avg,
          textAlign: TextAlign.end,
          builder: (p) => Text(
            p.avg > 0 ? fmt.format(p.avg) : '—',
            textAlign: TextAlign.end,
          ),
        ),
        SortableColumn(
          title: 'LTP',
          sortBy: (p) => p.ltp,
          textAlign: TextAlign.end,
          builder: (p) => Text(
            p.ltp > 0 ? fmt.format(p.ltp) : '—',
            textAlign: TextAlign.end,
          ),
        ),
        SortableColumn(
          title: 'P&L',
          sortBy: (p) => p.unrealized,
          textAlign: TextAlign.end,
          builder: (p) => Text(
            '₹${fmt.format(p.unrealized)}',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _pnlColor(context, p.unrealized),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        SortableColumn(
          title: 'P&L %',
          sortBy: (p) => p.unrealizedPct,
          textAlign: TextAlign.end,
          builder: (p) => Text(
            '${p.unrealizedPct.toStringAsFixed(2)}%',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _pnlColor(context, p.unrealizedPct),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, _PosRow p, int index) {
    final colors = context.colors;
    final fmt = NumberFormat('#,##0.00');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  p.symbol,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                '₹${fmt.format(p.unrealized)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: _pnlColor(context, p.unrealized),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Qty ${p.qty.toStringAsFixed(0)} · Avg ${p.avg > 0 ? fmt.format(p.avg) : '—'} · LTP ${p.ltp > 0 ? fmt.format(p.ltp) : '—'} · ${p.unrealizedPct.toStringAsFixed(2)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fmt = NumberFormat('#,##0.00');

    return BlocConsumer<PaperOmsCubit, PaperOmsState>(
      listenWhen: (p, c) => p.positions != c.positions || p.orders != c.orders,
      listener: (context, state) {
        _lastPosKey = null;
        _maybeRefreshLtps();
      },
      builder: (context, state) {
        final computed = _computeFromFills(state.orders);
        final rows = _rows(state);
        final unrealizedTotal =
            rows.fold<double>(0, (s, r) => s + r.unrealized);
        final todayPnl = computed.todayRealized + unrealizedTotal;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Text(
                    'Positions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  if (_loadingLtp)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: () {
                        context.read<PaperOmsCubit>().refreshBooks();
                        _lastPosKey = null;
                        _maybeRefreshLtps();
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.cardSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.divider),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's P&L",
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: colors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${fmt.format(todayPnl)}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: _pnlColor(context, todayPnl),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Realized ₹${fmt.format(computed.todayRealized)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Unrealized ₹${fmt.format(unrealizedTotal)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: AmAdaptiveTableCardView<_PosRow>(
                  items: rows,
                  breakpoint: 720,
                  spacing: 10,
                  emptyWidget: Center(
                    child: Text(
                      'No open positions.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ),
                  tableBuilder: _buildTable,
                  cardBuilder: _buildCard,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
