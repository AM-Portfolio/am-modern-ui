import 'package:am_paper_ui/providers/paper_symbol_discovery_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

  final String selectedSymbol;
  final ValueChanged<String> onSelectSymbol;
  final WatchlistSideCallback onBuySell;

  /// Opens Equity Insider / fundamental analysis for the symbol.
  final ValueChanged<String>? onOpenFundamentals;

  /// Mobile: hide title/refresh row; discovery via Global Search.
  final bool compactChrome;

  @override
  ConsumerState<PaperWatchlistPane> createState() => _PaperWatchlistPaneState();
}

class _PaperWatchlistPaneState extends ConsumerState<PaperWatchlistPane> {
  late final WatchlistController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WatchlistController(
      onSelectSymbol: widget.onSelectSymbol,
    );
    _controller.bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
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
          return PaperWatchlistMobile(
            controller: _controller,
            selectedSymbol: widget.selectedSymbol,
            onSelectSymbol: widget.onSelectSymbol,
            onBuySell: widget.onBuySell,
            onOpenFundamentals: widget.onOpenFundamentals,
          );
        }
        return PaperWatchlistWeb(
          controller: _controller,
          selectedSymbol: widget.selectedSymbol,
          onSelectSymbol: widget.onSelectSymbol,
          onBuySell: widget.onBuySell,
          onOpenFundamentals: widget.onOpenFundamentals,
        );
      },
    );
  }
}
