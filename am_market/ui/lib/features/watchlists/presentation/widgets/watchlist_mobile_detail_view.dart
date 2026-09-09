import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../providers/watchlist_provider.dart';
import '../../data/models/watchlist_model.dart';
import 'add_to_watchlist_popup.dart';
import 'edit_watchlist_dialog.dart';
import 'watchlist_gainers_losers_card.dart';

class WatchlistMobileDetailView extends ConsumerStatefulWidget {
  final Watchlist watchlist;
  final VoidCallback onBack;
  final ValueChanged<String>? onStockSelected;

  const WatchlistMobileDetailView({
    super.key,
    required this.watchlist,
    required this.onBack,
    this.onStockSelected,
  });

  @override
  ConsumerState<WatchlistMobileDetailView> createState() => _WatchlistMobileDetailViewState();
}

class _WatchlistMobileDetailViewState extends ConsumerState<WatchlistMobileDetailView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final watchlist = widget.watchlist;

    final symbolsKey = watchlist.items.map((e) => e.symbol.toUpperCase()).join(',');
    final quotesAsync = ref.watch(watchlistQuotesProvider(symbolsKey));
    final quotesMap = quotesAsync.value ?? {};

    // Filter items based on search
    final filteredItems = watchlist.items.where((item) {
      if (_searchQuery.isEmpty) return true;
      final quote = quotesMap[item.symbol.toUpperCase()];
      final name = quote?.companyName.toLowerCase() ?? '';
      return item.symbol.toLowerCase().contains(_searchQuery) || name.contains(_searchQuery);
    }).toList();

    // Calculate totals and gainers/losers
    double totalValue = 0.0;
    double totalDayChange = 0.0;
    int gainers = 0;
    int losers = 0;
    int unchanged = 0;

    for (final item in watchlist.items) {
      final quote = quotesMap[item.symbol.toUpperCase()];
      final ltp = quote?.lastPrice ?? 0.0;
      final change = quote?.change ?? 0.0;

      totalValue += ltp;
      totalDayChange += change;

      if (change > 0) {
        gainers++;
      } else if (change < 0) {
        losers++;
      } else {
        unchanged++;
      }
    }

    final prevTotal = totalValue - totalDayChange;
    final totalPnlPercent = prevTotal > 0 ? (totalDayChange / prevTotal) * 100 : 0.0;
    final isPosPnl = totalDayChange >= 0;
    final pnlColor = totalDayChange == 0.0
        ? colors.textSecondary
        : (isPosPnl ? colors.marketPositiveIndicator : colors.marketNegativeIndicator);
    final pnlSign = isPosPnl && totalDayChange > 0 ? '+' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // App Bar / Top Navigation
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 22),
              color: colors.textPrimary,
              onPressed: widget.onBack,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                watchlist.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!watchlist.isDefault) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: colors.textSecondary,
                tooltip: 'Edit Watchlist Name',
                onPressed: () {
                  EditWatchlistDialog.show(
                    context,
                    currentName: watchlist.name,
                    onSaved: (newName) {
                      ref.read(watchlistsProvider.notifier).updateWatchlist(watchlist.id, newName);
                    },
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 20, color: colors.textSecondary),
                onSelected: (val) async {
                  if (val == 'delete') {
                    final confirm = await ConfirmationDialog.show(
                      context: context,
                      title: 'Delete Watchlist',
                      subtitle: 'This action cannot be undone',
                      message: 'Are you sure you want to delete "${watchlist.name}"?',
                      icon: Icons.warning_amber_rounded,
                      confirmText: 'Delete',
                      isDestructive: true,
                    );
                    if (confirm) {
                      ref.read(watchlistsProvider.notifier).deleteWatchlist(watchlist.id);
                      widget.onBack();
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: colors.statusError, size: 18),
                        const SizedBox(width: 10),
                        Text('Delete Watchlist', style: TextStyle(color: colors.statusError)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // Watchlist Info Header (Star, Name, Badge, Count)
        Row(
          children: [
            Icon(Icons.star, color: ModuleColors.market, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          watchlist.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (watchlist.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: ModuleColors.market.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ModuleColors.market,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${watchlist.items.length} stocks',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Search Input
        TextField(
          controller: _searchController,
          style: TextStyle(color: colors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search stocks in this watchlist...',
            hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.6), fontSize: 13),
            prefixIcon: Icon(Icons.search, size: 18, color: colors.textSecondary),
            filled: true,
            fillColor: colors.surface.withValues(alpha: 0.6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ModuleColors.market, width: 1.2),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Summary Card (Today's P&L and Total Value)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's P&L",
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$pnlSign₹${totalDayChange.abs().toStringAsFixed(2)} ($pnlSign${totalPnlPercent.toStringAsFixed(2)}%)',
                      style: TextStyle(
                        color: pnlColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Value',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${totalValue.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Table Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              const Expanded(
                flex: 4,
                child: Text('Symbol', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const Expanded(
                flex: 3,
                child: Text('LTP (₹)', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const Expanded(
                flex: 3,
                child: Text('Day Chg', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const Expanded(
                flex: 3,
                child: Text('% Chg', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 32), // Space for 3-dots
            ],
          ),
        ),
        const Divider(height: 1, thickness: 0.8),

        // Stocks List
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: Text(
                    watchlist.items.isEmpty
                        ? 'No stocks in this watchlist.'
                        : 'No stocks matching "$_searchQuery"',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                )
              : ListView.separated(
                  itemCount: filteredItems.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 0.5,
                    color: colors.border.withValues(alpha: 0.3),
                  ),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final quote = quotesMap[item.symbol.toUpperCase()];
                    final companyName = (quote != null && quote.companyName.isNotEmpty)
                        ? quote.companyName
                        : item.symbol;
                    final ltp = quote?.lastPrice ?? 0.0;
                    final dayChg = quote?.change ?? 0.0;
                    final pctChg = quote?.changePercent ?? 0.0;

                    final isPos = dayChg >= 0;
                    final changeColor = dayChg == 0.0
                        ? colors.textSecondary
                        : (isPos ? colors.marketPositiveIndicator : colors.marketNegativeIndicator);
                    final sign = isPos && dayChg > 0 ? '+' : '';

                    return InkWell(
                      onTap: () => widget.onStockSelected?.call(item.symbol),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        child: Row(
                          children: [
                            // Symbol & Company
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.symbol,
                                    style: TextStyle(
                                      color: ModuleColors.market,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    companyName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // LTP
                            Expanded(
                              flex: 3,
                              child: Text(
                                ltp > 0 ? ltp.toStringAsFixed(2) : '0.00',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            // Day Chg
                            Expanded(
                              flex: 3,
                              child: Text(
                                '$sign${dayChg.toStringAsFixed(2)}',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: changeColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // % Chg
                            Expanded(
                              flex: 3,
                              child: Text(
                                '$sign${pctChg.toStringAsFixed(2)}%',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: changeColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // 3-dots Menu
                            SizedBox(
                              width: 32,
                              child: PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: Icon(Icons.more_vert, size: 18, color: colors.textSecondary),
                                onSelected: (action) async {
                                  if (action == 'move') {
                                    AddToWatchlistPopup.show(context, item.symbol, sourceWatchlistId: watchlist.id);
                                  } else if (action == 'delete') {
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
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'move',
                                    child: Row(
                                      children: [
                                        Icon(Icons.drive_file_move_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('Move Stock'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, color: colors.statusError, size: 18),
                                        const SizedBox(width: 8),
                                        Text('Remove', style: TextStyle(color: colors.statusError)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Bottom Gainers & Losers Card
        const SizedBox(height: 12),
        WatchlistGainersLosersCard(
          gainers: gainers,
          losers: losers,
          unchanged: unchanged,
        ),
      ],
    );
  }
}
