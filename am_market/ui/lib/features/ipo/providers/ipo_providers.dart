import 'package:am_market_ui/core/services/market_data_sdk_service.dart';
import 'package:am_market_ui/features/ipo/data/ipo_api_client.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ipoApiClientProvider = Provider<IpoApiClient>((ref) {
  final sdkService = MarketDataSdkService();
  return IpoApiClient(sdkService);
});

final ipoCountsProvider = FutureProvider<AsraxIpoCountsDto>((ref) async {
  final client = ref.watch(ipoApiClientProvider);
  return await client.getIpoCounts();
});

final ipoListProvider = FutureProvider.family<List<AsraxIpoSummaryDto>, String>(
    (ref, status) async {
  final client = ref.watch(ipoApiClientProvider);
  return await client.getIpos(status);
});

final allIposProvider = FutureProvider<List<AsraxIpoSummaryDto>>((ref) async {
  final client = ref.watch(ipoApiClientProvider);
  final results = await Future.wait([
    client.getIpos('open').catchError((_) => <AsraxIpoSummaryDto>[]),
    client.getIpos('upcoming').catchError((_) => <AsraxIpoSummaryDto>[]),
    client.getIpos('closed').catchError((_) => <AsraxIpoSummaryDto>[]),
  ]);

  final Map<String, AsraxIpoSummaryDto> dedup = {};
  for (final list in results) {
    for (final item in list) {
      dedup[item.id] = item;
    }
  }
  return dedup.values.toList();
});

final ipoDetailsProvider =
    FutureProvider.family<AsraxIpoDetailsDto, String>((ref, id) async {
  final client = ref.watch(ipoApiClientProvider);
  return await client.getIpoDetails(id);
});

enum IpoStatusFilter {
  all,
  open,
  closingToday,
  upcoming,
  closed,
}

class IpoFilterState {
  final IpoStatusFilter statusFilter;
  final bool filterMainboard;
  final bool filterSme;
  final String? selectedIndustry;
  final String searchQuery;

  const IpoFilterState({
    this.statusFilter = IpoStatusFilter.all,
    this.filterMainboard = false,
    this.filterSme = false,
    this.selectedIndustry,
    this.searchQuery = '',
  });

  IpoFilterState copyWith({
    IpoStatusFilter? statusFilter,
    bool? filterMainboard,
    bool? filterSme,
    String? selectedIndustry,
    bool clearIndustry = false,
    String? searchQuery,
  }) {
    return IpoFilterState(
      statusFilter: statusFilter ?? this.statusFilter,
      filterMainboard: filterMainboard ?? this.filterMainboard,
      filterSme: filterSme ?? this.filterSme,
      selectedIndustry:
          clearIndustry ? null : (selectedIndustry ?? this.selectedIndustry),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class IpoFilterNotifier extends Notifier<IpoFilterState> {
  @override
  IpoFilterState build() {
    return const IpoFilterState();
  }

  void setStatusFilter(IpoStatusFilter filter) {
    state = state.copyWith(statusFilter: filter);
  }

  void toggleMainboard(bool? value) {
    state = state.copyWith(filterMainboard: value ?? false);
  }

  void toggleSme(bool? value) {
    state = state.copyWith(filterSme: value ?? false);
  }

  void setIndustry(String? industry) {
    state = state.copyWith(
      selectedIndustry: industry,
      clearIndustry: industry == null || industry.isEmpty || industry == 'All',
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void reset() {
    state = const IpoFilterState();
  }
}

final ipoFilterStateProvider =
    NotifierProvider<IpoFilterNotifier, IpoFilterState>(
  IpoFilterNotifier.new,
);

final distinctIndustriesProvider = Provider<List<String>>((ref) {
  final iposAsync = ref.watch(allIposProvider);
  return iposAsync.maybeWhen(
    data: (ipos) {
      final set = <String>{};
      for (final ipo in ipos) {
        if (ipo.industry != null && ipo.industry!.trim().isNotEmpty) {
          set.add(ipo.industry!.trim());
        }
      }
      final list = set.toList()..sort();
      return ['All', ...list];
    },
    orElse: () => ['All'],
  );
});

final filteredIposProvider =
    Provider<AsyncValue<List<AsraxIpoSummaryDto>>>((ref) {
  final iposAsync = ref.watch(allIposProvider);
  final filter = ref.watch(ipoFilterStateProvider);

  return iposAsync.whenData((ipos) {
    final now = DateTime.now();
    final todayStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return ipos.where((ipo) {
      // 1. Status filter
      final status = (ipo.status ?? '').toLowerCase();
      switch (filter.statusFilter) {
        case IpoStatusFilter.all:
          break;
        case IpoStatusFilter.open:
          if (status != 'open') return false;
          break;
        case IpoStatusFilter.closingToday:
          final end = ipo.biddingEndDate ?? '';
          if (end != todayStr && status != 'open') return false;
          break;
        case IpoStatusFilter.upcoming:
          if (status != 'upcoming') return false;
          break;
        case IpoStatusFilter.closed:
          if (status != 'closed' && status != 'listed') return false;
          break;
      }

      // 2. Board filters (Mainboard vs SME)
      final issueType = (ipo.issueType ?? '').toLowerCase();
      final isSme = issueType.contains('sme');
      final isMainboard = !isSme;

      if (filter.filterMainboard && !filter.filterSme) {
        if (!isMainboard) return false;
      } else if (filter.filterSme && !filter.filterMainboard) {
        if (!isSme) return false;
      }

      // 3. Industry filter
      if (filter.selectedIndustry != null && filter.selectedIndustry != 'All') {
        if (ipo.industry == null ||
            ipo.industry!.trim() != filter.selectedIndustry) {
          return false;
        }
      }

      // 4. Search query
      if (filter.searchQuery.trim().isNotEmpty) {
        final query = filter.searchQuery.trim().toLowerCase();
        final name = (ipo.companyName ?? '').toLowerCase();
        final sym = (ipo.symbol ?? '').toLowerCase();
        final ind = (ipo.industry ?? '').toLowerCase();
        if (!name.contains(query) &&
            !sym.contains(query) &&
            !ind.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  });
});
