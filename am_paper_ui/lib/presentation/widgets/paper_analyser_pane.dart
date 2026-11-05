import 'package:am_market_ui/am_market_ui.dart';
import 'package:flutter/material.dart';

import '../../data/paper_market_client.dart';

/// Paper desk Overview: Equity Insider for stocks, F&O for index underliers.
class PaperAnalyserPane extends StatelessWidget {
  const PaperAnalyserPane({super.key, this.symbol});

  final String? symbol;

  @override
  Widget build(BuildContext context) {
    final sym = symbol?.trim().toUpperCase();
    final hasSymbol = sym != null && sym.isNotEmpty;
    if (!hasSymbol) {
      return const SizedBox.shrink();
    }

    if (PaperMarketClient.isIndexSymbol(sym)) {
      final foSym = PaperMarketClient.toFoUnderlier(sym);
      return FoPage(
        key: ValueKey('fo-$foSym'),
        initialSymbol: foSym,
      );
    }

    return EquityInsiderPage(
      key: ValueKey('ei-$sym'),
      initialSymbol: sym,
      showPeers: false,
      showHeroDescription: false,
    );
  }
}
