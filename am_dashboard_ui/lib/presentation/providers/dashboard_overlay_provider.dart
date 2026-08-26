import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/overlay_chart_models.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _maxOverlayLines = 3;

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
    final selected = List<String>.from(state.selectedIndexIds);
    if (selected.isEmpty) selected.add(OverlayChartIds.nifty50);
    _generation += 1;
    final gen = _generation;
    state = OverlayChartState.initial(timeFrame).copyWith(
      selectedIndexIds: selected,
      pendingIds: {OverlayChartIds.portfolio, ...selected},
    );
    await Future.wait([
      _loadPortfolio(gen, timeFrame),
      _loadIndices(gen, timeFrame, selected),
    ]);
  }

  Future<void> retry(String id) {
    if (id == OverlayChartIds.portfolio) {
      return _loadPortfolio(_generation, state.timeFrame);
    }
    return _loadIndices(_generation, state.timeFrame, [id]);
  }

  Future<void> addIndex(String symbol) async {
    if (state.selectedIndexIds.contains(symbol)) return;
    if (1 + state.selectedIndexIds.length >= _maxOverlayLines) return;
    final selected = [...state.selectedIndexIds, symbol];
    state = state.copyWith(
      selectedIndexIds: selected,
      pendingIds: {...state.pendingIds, symbol},
      failedIds: {...state.failedIds}..remove(symbol),
    );
    await _loadIndices(_generation, state.timeFrame, [symbol]);
  }

  void removeIndex(String symbol) {
    if (!state.selectedIndexIds.contains(symbol)) return;
    final selected = [...state.selectedIndexIds]..remove(symbol);
    final series = Map<String, OverlaySeries>.from(state.series)..remove(symbol);
    final pending = Set<String>.from(state.pendingIds)..remove(symbol);
    final failed = Map<String, String>.from(state.failedIds)..remove(symbol);
    state = state.copyWith(
      selectedIndexIds: selected,
      series: series,
      pendingIds: pending,
      failedIds: failed,
    );
  }

  Future<void> _loadPortfolio(int gen, String timeFrame) async {
    _markPending(OverlayChartIds.portfolio);
    try {
      final repo = await ref.read(dashboardRepositoryProvider.future);
      final client = await ref.read(portfolioApiClientProvider.future);
      final raw = await repo.getPortfolioHistory(client, timeFrame: timeFrame);
      if (gen != _generation) return;
      final percent = toPercentPoints(raw);
      final nextSeries = Map<String, OverlaySeries>.from(state.series);
      if (percent.length >= 2) {
        nextSeries[OverlayChartIds.portfolio] = OverlaySeries(
          id: OverlayChartIds.portfolio,
          label: 'Portfolio',
          points: percent,
        );
      } else {
        nextSeries.remove(OverlayChartIds.portfolio);
      }
      state = state.copyWith(
        series: nextSeries,
        pendingIds: {...state.pendingIds}..remove(OverlayChartIds.portfolio),
        failedIds: {...state.failedIds}..remove(OverlayChartIds.portfolio),
        firstWealth: raw.isEmpty ? null : raw.first.value,
        lastWealth: raw.isEmpty ? null : raw.last.value,
        clearWealth: raw.isEmpty,
      );
    } catch (e) {
      if (gen != _generation) return;
      AppLogger.error('Overlay portfolio series failed', error: e);
      state = state.copyWith(
        pendingIds: {...state.pendingIds}..remove(OverlayChartIds.portfolio),
        failedIds: {
          ...state.failedIds,
          OverlayChartIds.portfolio: 'Could not load portfolio',
        },
      );
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
      for (final symbol in symbols) {
        pending.remove(symbol);
        final raw = bySymbol[symbol] ?? const <OverlayPoint>[];
        final percent = toPercentPoints(raw);
        if (percent.length >= 2) {
          nextSeries[symbol] = OverlaySeries(
            id: symbol,
            label: symbol,
            points: percent,
          );
          failed.remove(symbol);
        } else {
          nextSeries.remove(symbol);
          failed[symbol] = 'No data for $symbol';
        }
      }
      state = state.copyWith(
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
