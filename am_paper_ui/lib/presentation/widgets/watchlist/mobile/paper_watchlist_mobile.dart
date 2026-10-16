import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../common/watchlist_atoms.dart';
import '../common/watchlist_list_body.dart';
import '../watchlist_controller.dart';

class PaperWatchlistMobile extends StatefulWidget {
  const PaperWatchlistMobile({
    super.key,
    required this.controller,
    required this.selectedSymbol,
    required this.onSelectSymbol,
    required this.onBuySell,
    this.onOpenFundamentals,
    this.showSearch = true,
    this.onOpenAllIndices,
  });

  final WatchlistController controller;
  final String selectedSymbol;
  final ValueChanged<String> onSelectSymbol;
  final WatchlistSideCallback onBuySell;
  final ValueChanged<String>? onOpenFundamentals;
  final bool showSearch;
  final VoidCallback? onOpenAllIndices;

  @override
  State<PaperWatchlistMobile> createState() => _PaperWatchlistMobileState();
}

class _PaperWatchlistMobileState extends State<PaperWatchlistMobile> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = widget.controller;

    return Material(
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: WatchlistSourceDropdown(
                    selected: controller.selectedSource,
                    sources: List.of(controller.sources),
                    onSelected: (id) => controller.selectSource(id),
                    onBrowseAllIndices: widget.onOpenAllIndices,
                  ),
                ),
                if (widget.onOpenAllIndices != null) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'All Market Indices',
                    child: InkWell(
                      onTap: widget.onOpenAllIndices,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_graph_rounded,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Indices',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (controller.pageCount > 1) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: WatchlistPageChips(
                pageCount: controller.pageCount,
                pageIndex: controller.pageIndex,
                onSelect: controller.setPage,
              ),
            ),
          ],
          if (controller.quotesUnavailable &&
              !controller.loadingList &&
              !controller.refreshing) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Quotes unavailable — pull down to refresh',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Divider(height: 1, color: colors.divider),
          WatchlistListBody(
            controller: controller,
            selectedSymbol: widget.selectedSymbol,
            compact: true,
            onBuySell: widget.onBuySell,
            onOpenFundamentals: widget.onOpenFundamentals,
            onSelectSymbol: widget.onSelectSymbol,
          ),
        ],
      ),
    );
  }
}
