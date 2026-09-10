import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/models/indices_region.dart';
import 'package:am_market_common/models/market_data.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_market_ui/features/market/widgets/drawer_index_card.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';
import 'package:am_market_ui/features/market/widgets/market_region_toggle.dart';

/// Full-page All Indices grid matching prod sheet look (Indian|Global + cards)
/// with global timeframe on the right of the region toggle.
class AllIndicesPage extends ConsumerStatefulWidget {
  const AllIndicesPage({super.key});

  @override
  ConsumerState<AllIndicesPage> createState() => _AllIndicesPageState();
}

class _AllIndicesPageState extends ConsumerState<AllIndicesPage> {
  String? _selectedSymbol;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final mp = provider_pkg.Provider.of<MarketProvider>(context, listen: false);
      if (mp.allIndicesData.isEmpty) {
        mp.loadIndices();
      }
      final tf = ref.read(appTimeFrameProvider).code;
      if (mp.selectedIndicesTimeframe != tf) {
        mp.setIndicesTimeframe(tf);
      }
    });
  }

  List<StockIndicesMarketData> _active(
    MarketProvider provider,
  ) {
    return provider.indicesRegion == IndicesRegion.global
        ? provider.globalIndicesData
        : provider.allIndicesData;
  }

  double _displayPChange(
    StockIndicesMarketData data,
    String timeframe,
    Map<String, double> basePrices,
  ) {
    if (timeframe != '1D') {
      final base = basePrices[data.indexSymbol];
      if (base != null && base > 0) {
        return ((data.lastPrice - base) / base) * 100;
      }
      return 0.0;
    }
    return data.pChange;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TimeFrame>(appTimeFrameProvider, (previous, next) {
      final mp =
          provider_pkg.Provider.of<MarketProvider>(context, listen: false);
      if (mp.selectedIndicesTimeframe != next.code) {
        mp.setIndicesTimeframe(next.code);
      }
    });

    final timeframe = ref.watch(appTimeFrameProvider).code;

    return provider_pkg.Consumer<MarketProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.allIndicesData.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              color: ModuleColors.market,
            ),
          );
        }

        final basePrices = provider.timeframeBasePrices;
        final active = List<StockIndicesMarketData>.from(_active(provider))
          ..sort(
            (a, b) => _displayPChange(b, timeframe, basePrices)
                .compareTo(_displayPChange(a, timeframe, basePrices)),
          );

        return ColoredBox(
          color: MarketColors.drawerBg(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  'All Indices',
                  style: TextStyle(
                    fontSize: 16,
                    color: MarketColors.textPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: MarketRegionToggle(
                        value: provider.indicesRegion,
                        onChanged: provider.setIndicesRegion,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const GlobalTimeFrameBar(
                      variant: GlobalTimeFrameVariant.dropdown,
                      dropdownWidth: 72,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: active.isEmpty
                      ? Center(
                          child: Text(
                            provider.indicesRegion == IndicesRegion.global
                                ? 'No global indices available'
                                : 'No indices available',
                            style: TextStyle(
                              fontSize: 13,
                              color: MarketColors.textMuted(context),
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.35,
                          ),
                          itemCount: active.length,
                          itemBuilder: (context, index) {
                            final data = active[index];
                            final selected = data.indexSymbol ==
                                (_selectedSymbol ??
                                    provider.selectedIndex ??
                                    '');
                            return DrawerIndexCard(
                              data: data,
                              isSelected: selected,
                              timeframe: timeframe,
                              basePrice: basePrices[data.indexSymbol],
                              onTap: () {
                                setState(
                                  () => _selectedSymbol = data.indexSymbol,
                                );
                                if (!provider
                                    .isGlobalSymbol(data.indexSymbol)) {
                                  provider.selectIndex(data.indexSymbol);
                                }
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
