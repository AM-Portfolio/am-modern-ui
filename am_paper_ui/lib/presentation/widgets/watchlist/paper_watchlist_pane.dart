import 'package:am_paper_ui/providers/paper_symbol_discovery_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chart_sidebar_holdings.dart';
import 'common/watchlist_list_body.dart';
import 'mobile/paper_watchlist_mobile.dart';
import 'watchlist_controller.dart';
import 'web/paper_watchlist_web.dart';

export 'common/watchlist_list_body.dart' show WatchlistSideCallback;

/// Watchlist with Nifty 50 default, user lists, 20/page, auto LTP for visible page.
class PaperWatchlistPane extends ConsumerStatefulWidget {
  const PaperWatchlistPane({
    super.key,
    required this.selectedSymbol,
    required this.onSelectSymbol,
    required this.onBuySell,
    this.onOpenFundamentals,
    this.compactChrome = false,
    this.showRecentHistory = false,
    this.showSearch = true,
    this.onOpenAllIndices,
    this.controller,
  });

  final String selectedSymbol;
  final ValueChanged<String> onSelectSymbol;
  final WatchlistSideCallback onBuySell;

  /// Opens Equity Insider / fundamental analysis for the symbol.
  final ValueChanged<String>? onOpenFundamentals;

  /// Mobile: hide title/refresh row; discovery via Global Search.
  final bool compactChrome;

  /// Chart sidebar: collapsible Recent orders under the list.
  final bool showRecentHistory;

  /// When false, omit the Search stocks field (e.g. chart host uses header search).
  final bool showSearch;

  /// Triggered to open the All Market Indices drawer / view.
  final VoidCallback? onOpenAllIndices;

  /// Optional host-provided controller (e.g. for chart terminal synchronization).
  final WatchlistController? controller;

  @override
  ConsumerState<PaperWatchlistPane> createState() => _PaperWatchlistPaneState();
}

class _PaperWatchlistPaneState extends ConsumerState<PaperWatchlistPane> {
  late final WatchlistController _internalController;
  WatchlistController get _controller => widget.controller ?? _internalController;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController =
          WatchlistController(onSelectSymbol: widget.onSelectSymbol);
      _internalController.bootstrap();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  Future<void> _consumeDiscovery(String? symbol) async {
    final sym = symbol?.trim().toUpperCase();
    if (sym == null || sym.isEmpty) return;
    ref.read(paperSymbolDiscoveryProvider.notifier).clear();
    await _controller.addSymbol(sym);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(paperSymbolDiscoveryProvider, (prev, next) {
      if (next == null || next.isEmpty) return;
      _consumeDiscovery(next);
    });

    final pending = ref.watch(paperSymbolDiscoveryProvider);
    if (pending != null && pending.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ref.read(paperSymbolDiscoveryProvider) != pending) return;
        _consumeDiscovery(pending);
      });
    }

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (widget.compactChrome) {
          final mobile = PaperWatchlistMobile(
            controller: _controller,
            selectedSymbol: widget.selectedSymbol,
            onSelectSymbol: widget.onSelectSymbol,
            onBuySell: widget.onBuySell,
            onOpenFundamentals: widget.onOpenFundamentals,
            showSearch: widget.showSearch,
            onOpenAllIndices: widget.onOpenAllIndices,
          );
          if (!widget.showRecentHistory) return mobile;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: mobile),
              ChartSidebarRecentHistory(
                onSelectSymbol: widget.onSelectSymbol,
                limit: 8,
              ),
            ],
          );
        }
        final web = PaperWatchlistWeb(
          controller: _controller,
          selectedSymbol: widget.selectedSymbol,
          onSelectSymbol: widget.onSelectSymbol,
          onBuySell: widget.onBuySell,
          onOpenFundamentals: widget.onOpenFundamentals,
          showSearch: widget.showSearch,
        );
        if (!widget.showRecentHistory) return web;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: web),
            ChartSidebarRecentHistory(
              onSelectSymbol: widget.onSelectSymbol,
              limit: 8,
            ),
          ],
        );
      },
    );
  }
}
