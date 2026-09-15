import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../providers/watchlist_provider.dart';
import '../../data/models/watchlist_model.dart';
import 'add_to_watchlist_popup.dart';
import 'edit_watchlist_dialog.dart';
import 'watchlist_gainers_losers_card.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';

class WatchlistManagementView extends ConsumerWidget {
  final Watchlist watchlist;
  final ValueChanged<String>? onStockSelected;

  const WatchlistManagementView({
    super.key,
    required this.watchlist,
    this.onStockSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbolsKey = watchlist.items.map((e) => e.symbol.toUpperCase()).join(',');
    final quotesAsync = ref.watch(watchlistQuotesProvider(symbolsKey));
    final quotesMap = quotesAsync.value ?? {};

    int gainers = 0;
    int losers = 0;
    int unchanged = 0;

    for (final item in watchlist.items) {
      final quote = quotesMap[item.symbol.toUpperCase()];
      final change = quote?.change ?? 0.0;
      if (change > 0) {
        gainers++;
      } else if (change < 0) {
        losers++;
      } else {
        unchanged++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context, ref),
        const SizedBox(height: 16),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: _buildTable(context, ref, quotesMap),
          ),
        ),
        if (watchlist.items.isNotEmpty) ...[
          const SizedBox(height: 16),
          WatchlistGainersLosersCard(
            gainers: gainers,
            losers: losers,
            unchanged: unchanged,
          ),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Icon(Icons.star, color: ModuleColors.market, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  watchlist.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${watchlist.items.length} stocks${watchlist.isDefault ? '  •  Default list' : ''}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          if (!watchlist.isDefault) ...[
            OutlinedButton.icon(
              onPressed: () {
                EditWatchlistDialog.show(
                  context,
                  currentName: watchlist.name,
                  onSaved: (newName) {
                    ref.read(watchlistsProvider.notifier).updateWatchlist(watchlist.id, newName);
                  },
                );
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await ConfirmationDialog.show(
                  context: context,
                  title: 'Delete Watchlist',
                  subtitle: 'This action cannot be undone',
                  message: 'Are you sure you want to delete "${watchlist.name}"? All stocks inside will be removed from this list.',
                  icon: Icons.warning_amber_rounded,
                  confirmText: 'Delete',
                  isDestructive: true,
                );
                if (confirm) {
                  ref.read(watchlistsProvider.notifier).deleteWatchlist(watchlist.id);
                }
              },
              icon: Icon(Icons.delete_outline, size: 16, color: colors.statusError),
              label: Text('Delete', style: TextStyle(color: colors.statusError)),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.statusError,
                side: BorderSide(color: colors.statusError.withValues(alpha: 0.5)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, WidgetRef ref, Map<String, WatchlistStockQuote> quotesMap) {
    final colors = context.colors;

    if (watchlist.items.isEmpty) {
      return const Center(child: Text('No stocks added to this watchlist.'));
    }

    return SingleChildScrollView(
      child: DataTable(
        headingTextStyle: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
        dataTextStyle: TextStyle(color: colors.textPrimary, fontSize: 14),
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('Symbol')),
          DataColumn(label: Text('Company')),
          DataColumn(label: Text('LTP (₹)')),
          DataColumn(label: Text('Day Chg')),
          DataColumn(label: Text('% Chg')),
          DataColumn(label: Text('Action')),
        ],
        rows: watchlist.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          final quote = quotesMap[item.symbol.toUpperCase()];
          final companyName = (quote != null && quote.companyName.isNotEmpty) ? quote.companyName : item.symbol;
          final ltp = quote?.lastPrice ?? 0.0;
          final dayChg = quote?.change ?? 0.0;
          final pctChg = quote?.changePercent ?? 0.0;

          final isPos = dayChg >= 0;
          final changeColor = dayChg == 0.0
              ? colors.textSecondary
              : (isPos ? context.marketTheme.positive : context.marketTheme.negative);
          final sign = isPos && dayChg > 0 ? '+' : '';

          return DataRow(
            cells: [
              DataCell(Text('${index + 1}')),
              DataCell(
                InkWell(
                  onTap: () => onStockSelected?.call(item.symbol),
                  child: Text(
                    item.symbol,
                    style: TextStyle(
                      color: ModuleColors.market,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: ModuleColors.market,
                    ),
                  ),
                ),
              ),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Text(
                    companyName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textPrimary),
                  ),
                ),
              ),
              DataCell(Text(ltp > 0 ? ltp.toStringAsFixed(2) : '0.00')),
              DataCell(
                Text(
                  '$sign${dayChg.toStringAsFixed(2)}',
                  style: TextStyle(color: changeColor, fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(
                Text(
                  '$sign${pctChg.toStringAsFixed(2)}%',
                  style: TextStyle(color: changeColor, fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.drive_file_move_outline, size: 18),
                      tooltip: 'Move to different watchlist',
                      onPressed: () {
                        AddToWatchlistPopup.show(context, item.symbol, sourceWatchlistId: watchlist.id);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 18, color: colors.statusError),
                      tooltip: 'Remove from watchlist',
                      onPressed: () async {
                        final confirm = await ConfirmationDialog.show(
                          context: context,
                          title: 'Remove Stock',
                          subtitle: 'Remove from ${watchlist.name}',
                          message: 'Are you sure you want to remove ${item.symbol} from this watchlist?',
                          icon: Icons.delete_outline,
                          confirmText: 'Remove',
                          isDestructive: true,
                        );
                        if (confirm) {
                          ref.read(watchlistsProvider.notifier).removeStock(watchlist.id, item.symbol);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
