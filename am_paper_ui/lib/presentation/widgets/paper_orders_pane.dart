import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/oms_models.dart';
import '../paper_oms_cubit.dart';
import '../paper_oms_state.dart';
import 'paper_order_mobile_card.dart';

class _OrderRow {
  const _OrderRow({
    required this.order,
    required this.side,
    required this.symbol,
    required this.orderType,
    required this.qty,
    required this.price,
    required this.status,
    required this.time,
    required this.timeLabel,
  });

  final OmsOrder order;
  final String side;
  final String symbol;
  final String orderType;
  final double qty;
  final double price;
  final String status;
  final DateTime time;
  final String timeLabel;
}

/// Today's executed paper orders (+ working with cancel) — adaptive table/card.
class PaperOrdersPane extends StatelessWidget {
  const PaperOrdersPane({super.key});

  List<_OrderRow> _todayRows(PaperOmsState state) {
    final timeFmt = DateFormat('HH:mm:ss');
    final todayFilled = state.orders
        .where((o) => o.isFilled && o.isCreatedToday)
        .toList()
      ..sort((a, b) {
        final ac = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bc = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bc.compareTo(ac);
      });

    return [
      for (final o in todayFilled)
        _OrderRow(
          order: o,
          side: o.side.toUpperCase(),
          symbol: o.symbol.trim().toUpperCase(),
          orderType: o.orderType.toUpperCase(),
          qty: o.filledQuantityAsDouble,
          price: o.fillPriceAsDouble,
          status: o.status,
          time: o.createdAt?.toLocal() ??
              DateTime.fromMillisecondsSinceEpoch(0),
          timeLabel: o.createdAt != null
              ? timeFmt.format(o.createdAt!.toLocal())
              : '—',
        ),
    ];
  }

  Color _sideColor(BuildContext context, String side) {
    final colors = context.colors;
    return side == 'SELL'
        ? colors.statusError
        : colors.marketPositiveIndicator;
  }

  Widget _buildTable(BuildContext context, List<_OrderRow> items) {
    final fmt = NumberFormat('#,##0.00');
    return SortableTable<_OrderRow>(
      items: items,
      initialSortColumnIndex: 0,
      initialSortDirection: SortDirection.descending,
      columns: [
        SortableColumn(
          title: 'Time',
          sortBy: (r) => r.time.millisecondsSinceEpoch,
          builder: (r) => Text(r.timeLabel),
        ),
        SortableColumn(
          title: 'Side',
          sortBy: (r) => r.side,
          builder: (r) => Text(
            r.side,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _sideColor(context, r.side),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        SortableColumn(
          title: 'Symbol',
          flex: 2,
          sortBy: (r) => r.symbol,
          builder: (r) => Text(
            r.symbol,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        SortableColumn(
          title: 'Type',
          sortBy: (r) => r.orderType,
          builder: (r) => Text(r.orderType),
        ),
        SortableColumn(
          title: 'Qty',
          sortBy: (r) => r.qty,
          textAlign: TextAlign.end,
          builder: (r) => Text(
            r.qty.toStringAsFixed(r.qty == r.qty.roundToDouble() ? 0 : 2),
            textAlign: TextAlign.end,
          ),
        ),
        SortableColumn(
          title: 'Price',
          sortBy: (r) => r.price,
          textAlign: TextAlign.end,
          builder: (r) => Text(
            r.price > 0 ? '₹${fmt.format(r.price)}' : '—',
            textAlign: TextAlign.end,
          ),
        ),
        SortableColumn(
          title: 'Status',
          sortBy: (r) => r.status,
          builder: (r) => Text(
            r.status,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, _OrderRow r, int index) {
    return PaperOrderMobileCard(
      side: r.side,
      symbol: r.symbol,
      orderType: r.orderType,
      qty: r.qty,
      price: r.price,
      status: r.status,
      timeLabel: r.timeLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final priceFmt = NumberFormat('#,##0.00');

    return BlocBuilder<PaperOmsCubit, PaperOmsState>(
      builder: (context, state) {
        final rows = _todayRows(state);
        final working = state.orders.where((o) => o.isWorking).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Text(
                    "Today's orders",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: () =>
                        context.read<PaperOmsCubit>().refreshBooks(),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Executed buys and sells for today',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: AmAdaptiveTableCardView<_OrderRow>(
                  items: rows,
                  breakpoint: 720,
                  spacing: 10,
                  emptyWidget: Center(
                    child: Text(
                      'No executed orders today.',
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
            Divider(height: 1, color: colors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Working orders',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (working.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'No open Limit / Super / Trail orders.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              )
            else
              SizedBox(
                height: 140,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  itemCount: working.length,
                  itemBuilder: (context, i) {
                    final o = working[i];
                    final lim = double.tryParse(o.limitPrice ?? '') ?? 0;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('${o.orderType} ${o.side} ${o.symbol}'),
                      subtitle: Text(
                        'Qty ${o.quantity}'
                        '${lim > 0 ? ' @ ₹${priceFmt.format(lim)}' : ''}',
                      ),
                      trailing: TextButton(
                        onPressed: state.submitting
                            ? null
                            : () => context
                                .read<PaperOmsCubit>()
                                .cancel(o.orderId),
                        child: const Text('Cancel'),
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
