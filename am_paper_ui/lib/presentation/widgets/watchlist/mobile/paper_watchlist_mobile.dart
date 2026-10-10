import 'package:am_common/am_common.dart' show MobileSearchScope;
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
  });

  final WatchlistController controller;
  final String selectedSymbol;
  final ValueChanged<String> onSelectSymbol;
  final WatchlistSideCallback onBuySell;
  final ValueChanged<String>? onOpenFundamentals;

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
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => MobileSearchScope.tryOpenGlobalSearch(context),
                icon: Icon(Icons.search_rounded, size: 18, color: ModuleColors.market),
                label: Text(
                  'Add stocks via global search',
                  style: TextStyle(color: ModuleColors.market, fontSize: 13),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: WatchlistSourceDropdown(
              selected: controller.selectedSource,
              sources: List.of(controller.sources),
              onSelected: (id) => controller.selectSource(id),
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
