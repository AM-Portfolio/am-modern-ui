import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/overlay_chart_models.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final marketApiClientProvider = FutureProvider<ApiClient>((ref) async {
  final config = await ref.watch(appConfigProvider.future);
  final baseUrl = config.api.marketData?.baseUrl ??
      config.api.analysis?.baseUrl ??
      config.api.baseUrl;
  if (baseUrl.isEmpty) {
    throw Exception('Market/Analysis API base URL is not configured');
  }
  return ApiClient(baseUrl: baseUrl);
});

final dashboardOverlayProvider = NotifierProvider.family<
    DashboardOverlayNotifier, OverlayChartState, String>(
  DashboardOverlayNotifier.new,
);

class DashboardOverlayNotifier extends Notifier<OverlayChartState> {
  DashboardOverlayNotifier(this.userId);

  final String userId;
  int _generation = 0;
  bool _selectionTouched = false;

  @override
  OverlayChartState build() {
    ref.listen<TimeFrame>(appTimeFrameProvider, (previous, next) {
      if (previous?.code != next.code) {
        reload();
      }
    });
    Future.microtask(reload);
    return OverlayChartState.initial(ref.read(appTimeFrameProvider).code);
  }

  Future<void> reload() async {
    final timeFrame = ref.read(appTimeFrameProvider).code;
    final selected = List<String>.from(state.selectedIds);
    _generation += 1;
    final gen = _generation;
    state = OverlayChartState.initial(timeFrame).copyWith(
      selectedIds: selected,
      pendingIds: {...selected},
    );
    await _loadPortfolios(gen, timeFrame);
    if (gen != _generation) return;
    await _loadIndices(
      gen,
      timeFrame,
      state.selectedIds.where(OverlayChartIds.needsIndexFetch).toList(),
    );
  }

  Future<void> retry(String id) {
    if (OverlayChartIds.needsIndexFetch(id)) {
      return _loadIndices(_generation, state.timeFrame, [id]);
    }
    return _loadPortfolios(_generation, state.timeFrame);
  }

  Future<void> addSeries(String id) async {
    if (state.selectedIds.contains(id) || state.atCap) return;
    _selectionTouched = true;
    final selected = [...state.selectedIds, id];
    state = state.copyWith(
      selectedIds: selected,
      pendingIds: OverlayChartIds.needsIndexFetch(id)
          ? {...state.pendingIds, id}
          : state.pendingIds,
      failedIds: {...state.failedIds}..remove(id),
    );
    if (OverlayChartIds.needsIndexFetch(id)) {
      await _loadIndices(_generation, state.timeFrame, [id]);
    } else {
      await _loadPortfolios(_generation, state.timeFrame);
    }
  }

  void removeSeries(String id) {
    if (!state.selectedIds.contains(id)) return;
    _selectionTouched = true;
    final selected = [...state.selectedIds]..remove(id);
    final series = Map<String, OverlaySeries>.from(state.series);
    if (OverlayChartIds.needsIndexFetch(id)) {
      series.remove(id);
    }
    final pending = Set<String>.from(state.pendingIds)..remove(id);
    final failed = Map<String, String>.from(state.failedIds)..remove(id);
    state = state.copyWith(
      selectedIds: selected,
      series: series,
      pendingIds: pending,
      failedIds: failed,
    );
  }

  Future<void> _loadPortfolios(int gen, String timeFrame) async {
    for (final id in state.selectedIds.where((id) => !OverlayChartIds.isIndex(id))) {
      _markPending(id);
    }
    try {
      final repo = await ref.read(dashboardRepositoryProvider.future);
      final client = await ref.read(portfolioApiClientProvider.future);
      final history = await repo.getPortfolioHistory(client, timeFrame: timeFrame);
      if (gen != _generation) return;

      final availableIds = history.portfolios.map((p) => p.id).toList();

      final portfolioSeries = <String, OverlaySeries>{};
      final overallRaw = history.aggregate
          .where((p) => p.value.isFinite && p.value > 0)
          .toList();
      final overallPct = toPercentPoints(overallRaw);
      if (overallPct.length >= 2) {
        portfolioSeries[OverlayChartIds.overall] = OverlaySeries(
          id: OverlayChartIds.overall,
          label: OverlayChartIds.overall,
          points: overallPct,
          rawPoints: overallRaw,
        );
      }
      for (final ref in history.portfolios) {
        final raw = history.byPortfolioId[ref.id] ?? const <OverlayPoint>[];
        final rawFinite = raw
            .where((p) => p.value.isFinite && p.value > 0)
            .toList();
        final percent = toPercentPoints(rawFinite);
        if (percent.length >= 2) {
          portfolioSeries[ref.id] = OverlaySeries(
            id: ref.id,
            label: ref.label,
            points: percent,
            rawPoints: rawFinite,
          );
        }
      }

      if (gen != _generation) return;

      // Fresh read — user may have added indices while portfolio history loaded.
      final indicesFromState = Map<String, OverlaySeries>.from(state.series)
        ..removeWhere((id, _) => !OverlayChartIds.isIndex(id));
      final nextSeries = {...indicesFromState, ...portfolioSeries};

      final selected = mergeOverlaySelection(
        previous: List<String>.from(state.selectedIds),
        availablePortfolioIds: availableIds,
        selectionTouched: _selectionTouched,
      );

      final pending = Set<String>.from(state.pendingIds)
        ..removeWhere((id) => !OverlayChartIds.needsIndexFetch(id));
      final failed = Map<String, String>.from(state.failedIds)
        ..removeWhere((id, _) => !OverlayChartIds.needsIndexFetch(id));

      final aggregate = history.aggregate;
      state = state.copyWith(
        selectedIds: selected,
        availablePortfolios: history.portfolios,
        series: nextSeries,
        pendingIds: pending,
        failedIds: failed,
        firstWealth: aggregate.isEmpty ? null : aggregate.first.value,
        lastWealth: aggregate.isEmpty ? null : aggregate.last.value,
        clearWealth: aggregate.isEmpty,
      );

      final extraIndices = selected
          .where(OverlayChartIds.isIndex)
          .where((id) => (state.series[id]?.points.length ?? 0) < 2)
          .toList();
      if (extraIndices.isNotEmpty) {
        await _loadIndices(gen, timeFrame, extraIndices);
      }
    } catch (e) {
      if (gen != _generation) return;
      AppLogger.error('Overlay portfolio series failed', error: e);
      final pending = Set<String>.from(state.pendingIds)
        ..removeWhere((id) => !OverlayChartIds.isIndex(id));
      final failed = Map<String, String>.from(state.failedIds);
      for (final id
          in state.selectedIds.where((id) => !OverlayChartIds.isIndex(id))) {
        failed[id] = 'Could not load portfolio';
      }
      state = state.copyWith(pendingIds: pending, failedIds: failed);
    }
  }

  Future<void> _loadIndices(
    int gen,
    String timeFrame,
    List<String> symbols,
  ) async {
    if (symbols.isEmpty) return;
    for (final symbol in symbols) {
      _markPending(symbol);
    }
    try {
      final repo = await ref.read(dashboardRepositoryProvider.future);
      final client = await ref.read(marketApiClientProvider.future);
      final bySymbol = await repo.getIndexHistory(
        client,
        symbols: symbols,
        range: timeFrame,
      );
      if (gen != _generation) return;
      final nextSeries = Map<String, OverlaySeries>.from(state.series);
      final failed = Map<String, String>.from(state.failedIds);
      final pending = Set<String>.from(state.pendingIds);
      final selectedIds = List<String>.from(state.selectedIds);
      for (final symbol in symbols) {
        pending.remove(symbol);
        final raw = bySymbol[symbol] ?? const <OverlayPoint>[];
        final rawFinite = raw
            .where((p) => p.value.isFinite && p.value > 0)
            .toList();
        final percent = toPercentPoints(rawFinite);
        if (percent.length >= 2) {
          nextSeries[symbol] = OverlaySeries(
            id: symbol,
            label: symbol,
            points: percent,
            rawPoints: rawFinite,
          );
          failed.remove(symbol);
          if (!selectedIds.contains(symbol)) {
            selectedIds.add(symbol);
          }
        } else {
          nextSeries.remove(symbol);
          failed[symbol] = 'No data for $symbol';
        }
      }
      state = state.copyWith(
        selectedIds: selectedIds,
        series: nextSeries,
        pendingIds: pending,
        failedIds: failed,
      );
    } catch (e) {
      if (gen != _generation) return;
      AppLogger.error('Overlay index series failed', error: e);
      final pending = Set<String>.from(state.pendingIds);
      final failed = Map<String, String>.from(state.failedIds);
      for (final symbol in symbols) {
        pending.remove(symbol);
        failed[symbol] = 'Could not load $symbol';
      }
      state = state.copyWith(pendingIds: pending, failedIds: failed);
    }
  }

  void _markPending(String id) {
    state = state.copyWith(
      pendingIds: {...state.pendingIds, id},
      failedIds: {...state.failedIds}..remove(id),
    );
  }
}
