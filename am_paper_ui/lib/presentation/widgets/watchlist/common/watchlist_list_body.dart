import 'dart:async';

import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../watchlist_controller.dart';
import 'watchlist_atoms.dart';

typedef WatchlistSideCallback = void Function(String symbol, String side);

class WatchlistListBody extends StatelessWidget {
  const WatchlistListBody({
    super.key,
    required this.controller,
    required this.selectedSymbol,
    required this.compact,
    required this.onBuySell,
    this.onOpenFundamentals,
    required this.onSelectSymbol,
  });

  final WatchlistController controller;
  final String selectedSymbol;
  final bool compact;
  final WatchlistSideCallback onBuySell;
  final ValueChanged<String>? onOpenFundamentals;
  final ValueChanged<String> onSelectSymbol;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pageRows = controller.pageRows;

    return Expanded(
      child: RefreshIndicator(
        color: colors.actionPrimaryBg,
        onRefresh: controller.pullToRefresh,
        child: controller.loadingList
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : controller.listError != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 200,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  controller.listError!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: colors.statusError,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => controller
                                      .selectSource(controller.selectedSourceId),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : pageRows.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: 200,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  controller.isNifty
                                      ? 'No Nifty 50 stocks loaded'
                                      : 'Search by symbol or name to add stocks',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: pageRows.length,
                        itemBuilder: (context, index) {
                          final stock = pageRows[index];
                          final selected = stock.symbol ==
                              selectedSymbol.toUpperCase();
                          final hovered = !compact &&
                              controller.hoveredSymbol == stock.symbol;
                          final expanded =
                              controller.expandedDepthSymbol == stock.symbol;
                          final showActions = compact
                              ? controller.actionSymbol == stock.symbol
                              : (hovered || selected || expanded);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (index > 0)
                                Divider(
                                  height: 1,
                                  color: colors.divider,
                                ),
                              WatchlistRow(
                                stock: stock,
                                selected: selected ||
                                    controller.actionSymbol == stock.symbol,
                                showActions: showActions,
                                depthExpanded: expanded,
                                enableHover: !compact,
                                onHover: (h) => controller.setHoveredSymbol(
                                  h ? stock.symbol : null,
                                ),
                                onTap: () {
                                  unawaited(controller.onCardTap(stock));
                                },
                                onBuy: () => onBuySell(stock.symbol, 'BUY'),
                                onSell: () => onBuySell(stock.symbol, 'SELL'),
                                onFundamentals: () {
                                  final cb = onOpenFundamentals;
                                  if (cb != null) {
                                    cb(stock.symbol);
                                  } else {
                                    onSelectSymbol(stock.symbol);
                                  }
                                },
                                onRemove: () => controller.remove(stock.symbol),
                              ),
                              AnimatedCrossFade(
                                firstChild: const SizedBox.shrink(),
                                secondChild: WatchlistDepthExpandPanel(
                                  loading: controller.depthLoading && expanded,
                                  quote: expanded ? controller.depthQuote : null,
                                ),
                                crossFadeState: expanded
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 200),
                              ),
                            ],
                          );
                        },
                      ),
      ),
    );
  }
}
