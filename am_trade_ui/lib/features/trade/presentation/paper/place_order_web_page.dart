import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_design_system/am_design_system.dart';

import '../cubit/oms_cubit.dart';
import '../cubit/oms_state.dart';
import '../../internal/data/dtos/oms_dto.dart';

class PlaceOrderWebPage extends StatefulWidget {
  const PlaceOrderWebPage({
    super.key,
    this.wallet,
    this.onFilled,
  });

  final OmsWallet? wallet;
  final VoidCallback? onFilled;

  @override
  State<PlaceOrderWebPage> createState() => _PlaceOrderWebPageState();
}

class _PlaceOrderWebPageState extends State<PlaceOrderWebPage> {
  final _symbol = TextEditingController();
  final _qty = TextEditingController(text: '1');
  String _side = 'BUY';

  @override
  void dispose() {
    _symbol.dispose();
    _qty.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final symbol = _symbol.text.trim();
    final qty = _qty.text.trim();
    if (symbol.isEmpty || qty.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a symbol and quantity.')),
      );
      return;
    }
    final order = await context.read<OmsCubit>().placeMarketOrder(
          symbol: symbol,
          side: _side,
          quantity: qty,
        );
    if (order != null && order.isFilled) {
      widget.onFilled?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OmsCubit, OmsState>(
      builder: (context, state) {
        final wallet = state.paperWallet ?? widget.wallet;
        if (wallet == null) {
          return const Center(
            child: Text('Create a paper wallet to place orders.'),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Place order',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(height: 6),
              Text(
                'Equity MARKET on paper. Practice with virtual cash — not a live broker order.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Available ₹${wallet.available}  ·  Reserved ₹${wallet.reserved}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ModuleColors.trade,
                    ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _symbol,
                      decoration: const InputDecoration(
                        labelText: 'Symbol',
                        hintText: 'RELIANCE',
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'BUY', label: Text('BUY')),
                      ButtonSegment(value: 'SELL', label: Text('SELL')),
                    ],
                    selected: {_side},
                    onSelectionChanged: (v) => setState(() => _side = v.first),
                  ),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _qty,
                      decoration: const InputDecoration(labelText: 'Qty'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  FilledButton(
                    onPressed: state.submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: ModuleColors.trade,
                      foregroundColor: Colors.white,
                    ),
                    child: state.submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Place MARKET'),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('Blotter',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Expanded(child: _Blotter(orders: state.orders)),
            ],
          ),
        );
      },
    );
  }
}

class _Blotter extends StatelessWidget {
  const _Blotter({required this.orders});
  final List<OmsOrder> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          'No paper orders yet.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final o = orders[i];
        final color = o.isRejected
            ? Colors.red
            : o.isFilled
                ? const Color(0xFF10B981)
                : Theme.of(context).colorScheme.onSurface;
        return ListTile(
          dense: true,
          title: Text('${o.side} ${o.quantity} ${o.symbol}'),
          subtitle: Text(
            o.isRejected
                ? omsRejectMessage(o.rejectReason)
                : 'Fill ${o.fillPrice ?? '—'}',
          ),
          trailing: Text(
            o.status,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        );
      },
    );
  }
}
