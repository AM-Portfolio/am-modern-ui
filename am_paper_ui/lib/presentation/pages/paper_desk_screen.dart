import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../paper_oms_cubit.dart';
import '../paper_oms_state.dart';
import '../widgets/paper_analyser_pane.dart';
import '../widgets/paper_order_ticket.dart';
import '../widgets/paper_watchlist_pane.dart';

class PaperDeskScreen extends StatefulWidget {
  const PaperDeskScreen({super.key});

  @override
  State<PaperDeskScreen> createState() => _PaperDeskScreenState();
}

class _PaperDeskScreenState extends State<PaperDeskScreen> {
  String _symbol = '';
  String _side = 'BUY';

  void _selectSymbol(String symbol) {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return;
    setState(() => _symbol = sym);
  }

  void _buySell(String symbol, String side) {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return;
    setState(() {
      _symbol = sym;
      _side = side.toUpperCase() == 'SELL' ? 'SELL' : 'BUY';
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaperOmsCubit, PaperOmsState>(
      listenWhen: (p, c) => c.toast != null && c.toast != p.toast,
      listener: (context, state) {
        final toast = state.toast;
        if (toast == null) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toast)));
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1100;
          if (!wide) {
            return DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  _header(context),
                  const TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'Watchlist'),
                      Tab(text: 'Trade'),
                      Tab(text: 'Analyser'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        PaperWatchlistPane(
                          selectedSymbol: _symbol,
                          onSelectSymbol: _selectSymbol,
                          onBuySell: _buySell,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: PaperOrderTicket(
                            symbol: _symbol,
                            side: _side,
                            onSymbolChanged: _selectSymbol,
                            onSideChanged: (s) => setState(() => _side = s),
                          ),
                        ),
                        PaperAnalyserPane(symbol: _symbol),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              _header(context),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 300,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: context.colors.divider),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: PaperWatchlistPane(
                              selectedSymbol: _symbol,
                              onSelectSymbol: _selectSymbol,
                              onBuySell: _buySell,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 5,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: context.colors.divider),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: PaperAnalyserPane(symbol: _symbol),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 340,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: context.colors.divider),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: PaperOrderTicket(
                              symbol: _symbol,
                              side: _side,
                              onSymbolChanged: _selectSymbol,
                              onSideChanged: (s) => setState(() => _side = s),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context) {
    return BlocBuilder<PaperOmsCubit, PaperOmsState>(
      builder: (context, state) {
        final w = state.wallet;
        return Material(
          color: context.colors.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text('Paper desk', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 16),
                if (w != null)
                  Expanded(
                    child: Text(
                      'Virtual cash ₹${w.available} (reserved ₹${w.reserved}) · not live money',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
