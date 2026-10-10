import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/f_o/presentation/pages/futures_view.dart';
import 'package:am_market_ui/features/f_o/presentation/pages/margin_calculator_view.dart';
import 'package:am_market_ui/features/f_o/presentation/pages/option_chain_view.dart';
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
  static const _defaultSymbol = 'NIFTY';
  bool _defaultScheduled = false;

  void _onSymbolSelected(String symbol) {
    ref.read(recentlyViewedFoSymbolsProvider.notifier).add(symbol);
    ref.read(foActiveSymbolProvider.notifier).state = symbol;
  }

  void _ensureDefaultSymbol() {
    if (_defaultScheduled) return;
    if (ref.read(foActiveSymbolProvider) != null) return;
    _defaultScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _defaultScheduled = false;
      if (!mounted) return;
      if (ref.read(foActiveSymbolProvider) != null) return;
      final recent = ref.read(recentlyViewedFoSymbolsProvider);
      final symbol = recent.isNotEmpty ? recent.first : _defaultSymbol;
      _onSymbolSelected(symbol);
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeSymbol = ref.watch(foActiveSymbolProvider);
    final colors = context.colors;
    final marketCyan = ModuleColors.market;
    final scaffoldBg = colors.scaffoldBackground;

    if (activeSymbol == null) {
      _ensureDefaultSymbol();
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scaffoldBg,
              Color.alphaBlend(marketCyan.withValues(alpha: 0.05), scaffoldBg),
              colors.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: activeSymbol == null
              ? const Center(child: CircularProgressIndicator())
              : _buildDetailView(activeSymbol, colors),
        ),
      ),
    );
  }

  Widget _buildDetailView(String symbol, AppColorsTheme colors) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < AmBreakpoints.mobile;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FoHeaderCard(symbol: symbol),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: ModuleColors.market,
            indicatorWeight: isMobile ? 2 : 2.5,
            dividerHeight: isMobile ? 0.5 : 1,
            labelColor: colors.textPrimary,
            unselectedLabelColor: colors.textSecondary,
            labelPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 16,
            ),
            labelStyle: TextStyle(
              fontSize: isMobile ? 12.5 : 14,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: isMobile ? 12.5 : 14,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
            tabs: [
              Tab(height: isMobile ? 36 : 46, text: 'Option Chain'),
              Tab(height: isMobile ? 36 : 46, text: 'Futures Contracts'),
              Tab(height: isMobile ? 36 : 46, text: 'Margin Calculator'),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isMobile ? bottomInset : 0),
              child: const TabBarView(
                children: [
                  OptionChainView(),
                  FuturesView(),
                  MarginCalculatorView(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
