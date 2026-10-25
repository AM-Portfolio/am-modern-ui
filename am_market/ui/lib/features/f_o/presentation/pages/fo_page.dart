import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/f_o/presentation/pages/futures_view.dart';
import 'package:am_market_ui/features/f_o/presentation/pages/margin_calculator_view.dart';
import 'package:am_market_ui/features/f_o/presentation/pages/option_chain_view.dart';
import 'package:am_market_ui/features/f_o/presentation/widgets/fo_empty_landing_view.dart';
import 'package:am_market_ui/features/f_o/presentation/widgets/fo_header_card.dart';
import 'package:am_market_ui/features/f_o/presentation/widgets/fo_expiry_picker.dart';
import 'package:am_market_ui/features/f_o/providers/fo_provider.dart';
import 'package:am_market_ui/features/f_o/providers/option_chain_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which F&O body to show when [FoPage.embed] is true (chart bottom chips).
enum FoEmbedSection {
  optionChain,
  futures,
  margin,
}

class FoPage extends ConsumerStatefulWidget {
  const FoPage({
    super.key,
    this.initialSymbol,
    this.embed = false,
    this.embedSection = FoEmbedSection.optionChain,
  });

  /// When set (e.g. chart terminal), selects this F&O underlier on open.
  final String? initialSymbol;

  /// Compact embed for chart bottom panel (no outer Scaffold, no symbol tile).
  final bool embed;

  /// Chart bottom: which of the three main F&O sections to show.
  final FoEmbedSection embedSection;

  @override
  ConsumerState<FoPage> createState() => _FoPageState();
}

class _FoPageState extends ConsumerState<FoPage> {
  @override
  void initState() {
    super.initState();
    final initial = widget.initialSymbol?.trim().toUpperCase();
    if (initial != null && initial.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(recentlyViewedFoSymbolsProvider.notifier).add(initial);
        ref.read(foSelectedExpiryProvider.notifier).state = null;
        ref.read(foActiveSymbolProvider.notifier).state = initial;
      });
    }
  }

  @override
  void didUpdateWidget(covariant FoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initialSymbol?.trim().toUpperCase();
    final prev = oldWidget.initialSymbol?.trim().toUpperCase();
    if (next != null && next.isNotEmpty && next != prev) {
      ref.read(recentlyViewedFoSymbolsProvider.notifier).add(next);
      ref.read(foSelectedExpiryProvider.notifier).state = null;
      ref.read(foActiveSymbolProvider.notifier).state = next;
    }
  }

  void _onSymbolSelected(String symbol) {
    ref.read(recentlyViewedFoSymbolsProvider.notifier).add(symbol);
    ref.read(foSelectedExpiryProvider.notifier).state = null;
    ref.read(foActiveSymbolProvider.notifier).state = symbol;
  }

  @override
  Widget build(BuildContext context) {
    final activeSymbol = ref.watch(foActiveSymbolProvider);
    final colors = context.colors;
    final marketCyan = ModuleColors.market;
    final scaffoldBg = colors.scaffoldBackground;

    final body = activeSymbol == null
        ? FoEmptyLandingView(
            onSelected: _onSymbolSelected,
          )
        : widget.embed
            ? _buildEmbedDetailView()
            : _buildTabDetailView(activeSymbol, colors);

    if (widget.embed) {
      return ColoredBox(color: Colors.transparent, child: body);
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
          child: body,
        ),
      ),
    );
  }

  /// Full Market F&O page — header + TabBar for Option Chain / Futures / Margin.
  Widget _buildTabDetailView(String symbol, AppColorsTheme colors) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < AmBreakpoints.mobile;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final chainData =
        isMobile ? ref.watch(optionChainProvider).asData?.value : null;
    final expiries = (chainData?['expiries'] as List<dynamic>?)
            ?.map((expiry) => expiry.toString())
            .toList() ??
        const <String>[];
    final selectedExpiry = ref.watch(foSelectedExpiryProvider);
    final responseExpiry = chainData?['expiry']?.toString() ?? '';
    final activeExpiry =
        selectedExpiry != null && expiries.contains(selectedExpiry)
            ? selectedExpiry
            : responseExpiry;

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FoHeaderCard(
            symbol: symbol,
          ),
          const SizedBox(height: AppSpacing.xs),
          Builder(builder: (tabContext) {
            final controller = DefaultTabController.of(tabContext);
            final tabs = TabBar(
              isScrollable: !isMobile,
              tabAlignment: isMobile ? null : TabAlignment.start,
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
                for (final title in const [
                  'Option Chain',
                  'Futures Contracts',
                  'Margin Calculator',
                ])
                  Tab(
                    height: isMobile ? 36 : 46,
                    child: isMobile
                        ? FittedBox(fit: BoxFit.scaleDown, child: Text(title))
                        : Text(title),
                  ),
              ],
            );
            if (!isMobile) return tabs;
            return Row(
              children: [
                Expanded(child: tabs),
                SizedBox(
                  width: 82,
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, child) => child!.withSubmarineReveal(
                      visible: controller.index == 0,
                      height: 36,
                      accentColor: ModuleColors.market,
                    ),
                    child: FoExpiryPicker(
                      expiries: expiries,
                      activeExpiry: activeExpiry,
                      compact: true,
                      onSelected: (expiry) => ref
                          .read(foSelectedExpiryProvider.notifier)
                          .state = expiry,
                    ),
                  ),
                ),
              ],
            );
          }),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isMobile ? bottomInset : 0),
              child: TabBarView(
                children: [
                  OptionChainView(showExpiryInToolbar: !isMobile),
                  const FuturesView(),
                  const MarginCalculatorView(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Chart bottom embed — no symbol tile; body only for the selected main tag.
  Widget _buildEmbedDetailView() {
    final child = switch (widget.embedSection) {
      FoEmbedSection.optionChain => const OptionChainView(),
      FoEmbedSection.futures => const FuturesView(),
      FoEmbedSection.margin => const MarginCalculatorView(),
    };
    return child;
  }
}
