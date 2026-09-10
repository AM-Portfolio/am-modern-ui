import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../paper_oms_cubit.dart';
import '../paper_oms_state.dart';

/// Today's executed paper orders (+ working with cancel).
class PaperOrdersPane extends StatelessWidget {
  const PaperOrdersPane({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final timeFmt = DateFormat('HH:mm:ss');
    final priceFmt = NumberFormat('#,##0.00');

    return BlocBuilder<PaperOmsCubit, PaperOmsState>(
      builder: (context, state) {
        final todayFilled = state.orders
            .where((o) => o.isFilled && o.isCreatedToday)
            .toList()
          ..sort((a, b) {
            final ac = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bc = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bc.compareTo(ac);
          });
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
              child: todayFilled.isEmpty
                  ? Center(
                      child: Text(
                        'No executed orders today.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: todayFilled.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: colors.divider),
                      itemBuilder: (context, i) {
                        final o = todayFilled[i];
                        final sideColor = o.side.toUpperCase() == 'SELL'
                            ? colors.statusError
                            : colors.marketPositiveIndicator;
                        final qty = o.filledQuantity ?? o.quantity;
                        final px = o.fillPrice;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${o.side} ${o.symbol}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: sideColor,
                                ),
                          ),
                          subtitle: Text(
                            '${o.orderType} · qty $qty'
                            '${px != null ? ' @ ₹${priceFmt.format(double.tryParse(px) ?? 0)}' : ''}'
                            '${o.createdAt != null ? ' · ${timeFmt.format(o.createdAt!.toLocal())}' : ''}',
                          ),
                          trailing: Text(
                            o.status,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: colors.textSecondary,
                                    ),
                          ),
                        );
                      },
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
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('${o.orderType} ${o.side} ${o.symbol}'),
                      subtitle: Text(
                        'Qty ${o.quantity}'
                        '${o.limitPrice != null ? ' @ ${o.limitPrice}' : ''}',
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
