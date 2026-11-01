import 'package:am_market_ui/core/services/market_data_sdk_service.dart';
import 'package:am_market_ui/features/ipo/data/ipo_api_client.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:am_market_ui/features/ipo/ipo_sorting.dart';
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
  const statuses = ['open', 'upcoming', 'closed', 'listed'];
  final results = await Future.wait(
    statuses.map((status) => _fetchAllPages(client, status)),
  );

  final Map<String, AsraxIpoSummaryDto> dedup = {};
  for (final list in results) {
    for (final item in list) {
      if (item.id.trim().isEmpty) continue;
      final existing = dedup[item.id];
      if (existing == null || _shouldPrefer(item, existing)) {
        dedup[item.id] = item;
      }
    }
  }
  return dedup.values.toList();
});

const _listPageSize = 100;
const _maxPagesPerStatus = 50;

Future<List<AsraxIpoSummaryDto>> _fetchAllPages(
  IpoApiClient client,
  String status,
) async {
  final items = <AsraxIpoSummaryDto>[];
  final fingerprints = <String>{};

  for (var page = 1; page <= _maxPagesPerStatus; page++) {
    final rawPage = await client.getIpos(
      status,
      pageNumber: page,
      records: _listPageSize,
      cacheOnly: true,
    );
    final validPage =
        rawPage.where((item) => item.id.trim().isNotEmpty).toList();

    if (rawPage.isNotEmpty && validPage.isEmpty) {
      throw StateError(
          'IPO $status page $page contained no valid provider ids');
    }

    final fingerprint =
        (validPage.map((item) => item.id).toList()..sort()).join('|');
    if (fingerprint.isNotEmpty && !fingerprints.add(fingerprint)) {
      throw StateError('IPO $status pagination repeated page $page');
    }

    items.addAll(validPage);
    if (rawPage.length < _listPageSize) return items;
  }

  throw StateError('IPO $status pagination exceeded $_maxPagesPerStatus pages');
}

bool _shouldPrefer(AsraxIpoSummaryDto candidate, AsraxIpoSummaryDto current) {
  final candidateStatus = _statusPriority(candidate.status);
  final currentStatus = _statusPriority(current.status);
  if (candidateStatus != currentStatus) return candidateStatus > currentStatus;
  return _fieldCompleteness(candidate) > _fieldCompleteness(current);
}

int _statusPriority(String? status) {
  switch (status?.trim().toLowerCase()) {
    case 'listed':
      return 4;
    case 'closed':
      return 3;
    case 'open':
      return 2;
    case 'upcoming':
      return 1;
    default:
      return 0;
  }
}

int _fieldCompleteness(AsraxIpoSummaryDto item) {
  final values = <Object?>[
    item.companyName,
    item.symbol,
    item.status,
    item.issueType,
    item.industry,
    item.biddingStartDate,
    item.biddingEndDate,
    item.totalSubscription,
    item.issueSizeCr,
    item.minimumPrice,
    item.maximumPrice,
  ];
  return values
      .where((value) => value != null && value.toString().trim().isNotEmpty)
      .length;
}

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

/// Pure filter predicate — kept testable outside Riverpod.
bool ipoMatchesFilter(
  AsraxIpoSummaryDto ipo,
  IpoFilterState filter, {
  DateTime? now,
}) {
  final todayStr = ipoTodayIndiaDateKey(now: now);

  final status = (ipo.status ?? '').toLowerCase();
  switch (filter.statusFilter) {
    case IpoStatusFilter.all:
      break;
    case IpoStatusFilter.open:
      if (status != 'open') return false;
      break;
    case IpoStatusFilter.closingToday:
      // Must be open AND bidding end date is today (not all open IPOs).
      final end = ipoIndiaDateKey(ipo.biddingEndDate);
      if (status != 'open' || end != todayStr) return false;
      break;
    case IpoStatusFilter.upcoming:
      if (status != 'upcoming') return false;
      break;
    case IpoStatusFilter.closed:
      if (status != 'closed' && status != 'listed') return false;
      break;
  }

  final issueType = (ipo.issueType ?? '').toLowerCase();
  final isSme = issueType.contains('sme');
  final isMainboard = !isSme;

  if (filter.filterMainboard && !filter.filterSme) {
    if (!isMainboard) return false;
  } else if (filter.filterSme && !filter.filterMainboard) {
    if (!isSme) return false;
  }

  if (filter.selectedIndustry != null && filter.selectedIndustry != 'All') {
    if (ipo.industry == null ||
        ipo.industry!.trim() != filter.selectedIndustry) {
      return false;
    }
  }

  if (filter.searchQuery.trim().isNotEmpty) {
    final query = filter.searchQuery.trim().toLowerCase();
    final name = (ipo.companyName ?? '').toLowerCase();
    final sym = (ipo.symbol ?? '').toLowerCase();
    final ind = (ipo.industry ?? '').toLowerCase();
    if (!name.contains(query) && !sym.contains(query) && !ind.contains(query)) {
      return false;
    }
  }

  return true;
}

final filteredIposProvider =
    Provider<AsyncValue<List<AsraxIpoSummaryDto>>>((ref) {
  final iposAsync = ref.watch(allIposProvider);
  final filter = ref.watch(ipoFilterStateProvider);

  return iposAsync.whenData((ipos) {
    final matching =
        ipos.where((ipo) => ipoMatchesFilter(ipo, filter)).toList();
    return filter.statusFilter == IpoStatusFilter.all
        ? sortIposForAll(matching)
        : matching;
  });
});
