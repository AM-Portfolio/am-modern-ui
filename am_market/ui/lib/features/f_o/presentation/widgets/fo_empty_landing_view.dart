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
    final surfaceColor = colors.cardSurface;
    final borderColor = colors.border;
    final sdkService = MarketDataSdkService();

    final recent = ref.watch(recentlyViewedFoSymbolsProvider);
    final recommendationsAsync = ref.watch(dynamicFoRecommendationsProvider);
    final rawSymbols = recommendationsAsync.maybeWhen(
      data: (d) => d,
      orElse: () => const <String>[],
    );
    final recSymbols = rawSymbols.isNotEmpty
        ? rawSymbols.take(6).toList()
        : const ['NIFTY', 'BANKNIFTY', 'FINNIFTY', 'MIDCPNIFTY'];
    final animatedHints = recSymbols.map((s) => 'Search "$s"...').toList();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: surfaceColor.withValues(alpha: 0.7),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.25),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.candlestick_chart_rounded,
                  size: 38,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'FUTURES & OPTIONS',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Search indices or stocks to view Option Chains, Futures, and live market data.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),
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
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: recSymbols
                      .map(
                        (s) => ActionChip(
                          label: Text(
                            s,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: colors.cardSurface,
                          side: BorderSide(color: colors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onPressed: () {
                            onSelected(s);
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
