import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/f_o/providers/fo_provider.dart';
import 'package:am_market_ui/core/services/market_data_sdk_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FoEmptyLandingView extends ConsumerWidget {
  const FoEmptyLandingView({
    required this.controller,
    required this.onSelected,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final accentColor = ModuleColors.market;
    final sdkService = MarketDataSdkService();

    final recent = ref.watch(recentlyViewedFoSymbolsProvider);
    final recommendationsAsync = ref.watch(dynamicFoRecommendationsProvider);
    final rawSymbols = recommendationsAsync.maybeWhen(
      data: (d) => d,
      orElse: () => const <String>[],
    );
    final recSymbols = rawSymbols.isNotEmpty
        ? rawSymbols.take(4).toList()
        : const ['NIFTY', 'BANKNIFTY', 'FINNIFTY', 'MIDCPNIFTY'];
    final animatedHints = recSymbols.map((s) => 'Search "$s"...').toList();

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.candlestick_chart_rounded,
                    size: 64,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'FUTURES & OPTIONS',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Search indices or stocks to view Option Chains, Futures, and live market data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),
                SmartSearchAnchor(
                  controller: controller,
                  animatedHints: animatedHints,
                  recentSearches: recent,
                  onRemoveRecent: (sym) {
                    ref.read(recentlyViewedFoSymbolsProvider.notifier).remove(sym);
                  },
                  onClearRecent: () {
                    ref.read(recentlyViewedFoSymbolsProvider.notifier).clear();
                  },
                  accentColor: accentColor,
                  searchHandler: (q) => sdkService.securityApi.search(
                    q,
                    smartRecommendations: true,
                    category: 'ALL',
                    limit: 8,
                  ),
                  onSelected: onSelected,
                ),
                if (recSymbols.isNotEmpty) ...[
                  const SizedBox(height: 48),
                  _buildDynamicChips(context, colors, accentColor, recSymbols),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicChips(BuildContext context, AppColorsTheme colors, Color accentColor, List<String> symbols) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            'Recommended Markets',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: symbols.map((sym) {
            return InkWell(
              onTap: () => onSelected(sym),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.5),
                  border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.show_chart, size: 16, color: accentColor),
                    const SizedBox(width: 8),
                    Text(
                      sym,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
