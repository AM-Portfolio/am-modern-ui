import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/f_o/presentation/pages/futures_view.dart';
import 'package:am_market_ui/features/f_o/presentation/pages/margin_calculator_view.dart';
import 'package:am_market_ui/features/f_o/presentation/pages/option_chain_view.dart';
import 'package:am_market_ui/features/f_o/presentation/widgets/fo_empty_landing_view.dart';
import 'package:am_market_ui/features/f_o/presentation/widgets/fo_header_card.dart';
import 'package:am_market_ui/features/f_o/providers/fo_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FoPage extends ConsumerStatefulWidget {
  const FoPage({super.key});

  @override
  ConsumerState<FoPage> createState() => _FoPageState();
}

class _FoPageState extends ConsumerState<FoPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSymbolSelected(String symbol) {
    ref.read(recentlyViewedFoSymbolsProvider.notifier).add(symbol);
    ref.read(foActiveSymbolProvider.notifier).state = symbol;
  }

  @override
  Widget build(BuildContext context) {
    final activeSymbol = ref.watch(foActiveSymbolProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: activeSymbol == null
          ? FoEmptyLandingView(
              controller: _searchController,
              onSelected: _onSymbolSelected,
            )
          : _buildDetailView(activeSymbol, colors),
    );
  }

  Widget _buildDetailView(String symbol, AppColorsTheme colors) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FoHeaderCard(
            symbol: symbol,
            onBack: () {
              ref.read(foActiveSymbolProvider.notifier).state = null;
              _searchController.clear();
            },
          ),
          TabBar(
            indicatorColor: ModuleColors.market,
            labelColor: colors.textPrimary,
            unselectedLabelColor: colors.textSecondary,
            tabs: const [
              Tab(text: 'Option Chain'),
              Tab(text: 'Futures Contracts'),
              Tab(text: 'Margin Calculator'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                OptionChainView(),
                FuturesView(),
                MarginCalculatorView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


