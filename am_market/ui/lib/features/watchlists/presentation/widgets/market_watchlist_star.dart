import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/watchlist_provider.dart';
import 'add_to_watchlist_popup.dart';

/// Compact star used by Equity Insider and F&O header cards.
class MarketWatchlistStar extends ConsumerWidget {
  const MarketWatchlistStar({required this.symbol, super.key});

  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(watchlistCheckStatusProvider(symbol));
    return statusAsync.when(
      data: (statuses) {
        final isAdded = statuses.any((s) => s.containsSymbol);
        return IconButton(
          tooltip: isAdded ? 'Remove from watchlist' : 'Add to watchlist',
          onPressed: () async {
            if (isAdded) {
              final name = statuses.firstWhere((s) => s.containsSymbol).name;
              final confirm = await ConfirmationDialog.show(
                context: context,
                title: 'Remove Stock',
                subtitle: 'Watchlist Management',
                message:
                    'Are you sure you want to remove $symbol from $name?',
                icon: Icons.star_rounded,
                confirmText: 'Remove',
                isDestructive: true,
              );
              if (confirm) {
                final wid =
                    statuses.firstWhere((s) => s.containsSymbol).watchlistId;
                ref.read(watchlistsProvider.notifier).removeStock(wid, symbol);
                ref.invalidate(watchlistCheckStatusProvider(symbol));
              }
            } else {
              AddToWatchlistPopup.show(context, symbol);
            }
          },
          icon: Icon(
            isAdded ? Icons.star_rounded : Icons.star_border_rounded,
            size: AppTypeScale.h3,
            color: isAdded ? ModuleColors.market : context.textSecondary,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
        );
      },
      loading: () => const SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox(width: 36, height: 36),
    );
  }
}
