import 'package:am_market_ui/am_market_ui.dart';
import 'package:flutter/material.dart';

/// Reuses Market Equity Insider as the paper desk mid-pane analyser.
class PaperAnalyserPane extends StatelessWidget {
  const PaperAnalyserPane({super.key, this.symbol});

  final String? symbol;

  @override
  Widget build(BuildContext context) {
    final sym = symbol?.trim().toUpperCase();
    final hasSymbol = sym != null && sym.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasSymbol)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Text(
              'Analyser · $sym',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        Expanded(
          child: EquityInsiderPage(
            key: ValueKey(hasSymbol ? 'ei-$sym' : 'ei-empty'),
            initialSymbol: hasSymbol ? sym : null,
          ),
        ),
      ],
    );
  }
}
