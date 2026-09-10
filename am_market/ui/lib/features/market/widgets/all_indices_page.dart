import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';
import 'package:am_market_ui/features/market/widgets/ranked_index_helpers.dart';
import 'package:am_market_ui/features/market/widgets/ranked_indices_list_body.dart';

/// Full-page All Indices: ranked list (Indian | Global | All) + TF dropdown.
class AllIndicesPage extends ConsumerStatefulWidget {
  const AllIndicesPage({super.key});

  @override
  ConsumerState<AllIndicesPage> createState() => _AllIndicesPageState();
}

class _AllIndicesPageState extends ConsumerState<AllIndicesPage> {
  IndicesListFilter _filter = IndicesListFilter.indian;
  String? _selectedSymbol;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final mp =
          provider_pkg.Provider.of<MarketProvider>(context, listen: false);
      if (mp.allIndicesData.isEmpty) {
        mp.loadIndices();
      }
      if (mp.globalIndicesData.isEmpty) {
        mp.loadGlobalIndicesData();
      }
      final tf = ref.read(appTimeFrameProvider).code;
      if (mp.selectedIndicesTimeframe != tf) {
        mp.setIndicesTimeframe(tf);
      }
    });
  }

  String _istClock() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    return '${DateFormat('HH:mm').format(now)} IST';
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
            child: CircularProgressIndicator(color: ModuleColors.market),
          );
        }

        return ColoredBox(
          color: MarketColors.drawerBg(context),
          child: RankedIndicesListBody(
            filter: _filter,
            onFilterChanged: (f) {
              setState(() => _filter = f);
              if (f == IndicesListFilter.global ||
                  f == IndicesListFilter.all) {
                if (provider.globalIndicesData.isEmpty) {
                  provider.loadGlobalIndicesData();
                }
              }
            },
            timeframe: timeframe,
            indian: provider.allIndicesData,
            global: provider.globalIndicesData,
            basePrices: provider.timeframeBasePrices,
            availableIndices: provider.availableIndices,
            selectedSymbol: _selectedSymbol ?? provider.selectedIndex,
            clockLabel: _istClock(),
            onIndexSelected: (data) {
              setState(() => _selectedSymbol = data.indexSymbol);
              if (!provider.isGlobalSymbol(data.indexSymbol)) {
                provider.selectIndex(data.indexSymbol);
              }
            },
          ),
        );
      },
    );
  }
}
