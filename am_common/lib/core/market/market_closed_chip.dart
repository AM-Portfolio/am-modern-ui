import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/am_common.dart';

/// Small chip shown when NSE market streaming is closed (REST still allowed).
class MarketClosedChip extends ConsumerWidget {
  const MarketClosedChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openAsync = ref.watch(marketIsOpenProvider);
    final isOpen = openAsync.maybeWhen(data: (v) => v, orElse: () => true);
    if (isOpen) return const SizedBox.shrink();

    final reason = ref.watch(marketStatusProvider)?.reason;
    final label = reason == null || reason.isEmpty || reason == 'UNKNOWN'
        ? 'Market closed'
        : 'Market closed · $reason';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}