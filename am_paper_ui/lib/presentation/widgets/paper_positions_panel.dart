import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../paper_oms_cubit.dart';
import '../paper_oms_state.dart';

class PaperPositionsPanel extends StatelessWidget {
  const PaperPositionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaperOmsCubit, PaperOmsState>(
      builder: (context, state) {
        final working = state.orders.where((o) => o.isWorking).toList();
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('Positions', style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: () => context.read<PaperOmsCubit>().refreshBooks(),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                if (state.positions.isEmpty)
                  Text(
                    'No open positions yet.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                  )
                else
                  ...state.positions.map(
                    (p) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(p.symbol),
                      trailing: Text('Qty ${p.qty}'),
                    ),
                  ),
                const Divider(),
                Text('Working orders', style: Theme.of(context).textTheme.titleSmall),
                if (working.isEmpty)
                  Text(
                    'No working Limit / Super / Trail orders.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                  )
                else
                  ...working.map(
                    (o) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('${o.orderType} ${o.side} ${o.symbol}'),
                      subtitle: Text(
                        'Qty ${o.quantity}'
                        '${o.limitPrice != null ? ' @ ${o.limitPrice}' : ''}'
                        '${o.triggerPrice != null ? ' trig ${o.triggerPrice}' : ''}',
                      ),
                      trailing: TextButton(
                        onPressed: state.submitting
                            ? null
                            : () => context.read<PaperOmsCubit>().cancel(o.orderId),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                const Divider(),
                Text('Recent blotter', style: Theme.of(context).textTheme.titleSmall),
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    itemCount: state.orders.take(20).length,
                    itemBuilder: (context, i) {
                      final o = state.orders[i];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('${o.status} ${o.side} ${o.symbol}'),
                        subtitle: Text(
                          '${o.orderType} qty ${o.quantity}'
                          '${o.fillPrice != null ? ' @ ${o.fillPrice}' : ''}',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
