import 'package:flutter/material.dart';

import 'common/watchlist_list_body.dart';
import 'mobile/paper_watchlist_mobile.dart';
import 'watchlist_controller.dart';
import 'web/paper_watchlist_web.dart';

export 'common/watchlist_list_body.dart' show WatchlistSideCallback;

/// Watchlist with Nifty 50 default, user lists, 20/page, auto LTP for visible page.
class PaperWatchlistPane extends StatefulWidget {
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

  /// Mobile: hide title/refresh row; search sits at the top; pull-to-refresh.
  final bool compactChrome;

  @override
  State<PaperWatchlistPane> createState() => _PaperWatchlistPaneState();
}

class _PaperWatchlistPaneState extends State<PaperWatchlistPane> {
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

  @override
  Widget build(BuildContext context) {
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
