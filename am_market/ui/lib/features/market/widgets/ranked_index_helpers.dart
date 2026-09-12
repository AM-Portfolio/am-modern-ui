import 'package:am_market_common/models/available_indices.dart';
import 'package:am_market_common/models/market_data.dart';

/// Page-local region filter (does not alter [IndicesRegion] provider state).
enum IndicesListFilter { indian, global, all }

extension IndicesListFilterLabel on IndicesListFilter {
  String get label {
    switch (this) {
      case IndicesListFilter.indian:
        return 'Indian';
      case IndicesListFilter.global:
        return 'Global';
      case IndicesListFilter.all:
        return 'All';
    }
  }
}

double rankedDisplayPChange(
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

double rankedDisplayChange(
  StockIndicesMarketData data,
  String timeframe,
  Map<String, double> basePrices,
) {
  if (timeframe != '1D') {
    final base = basePrices[data.indexSymbol];
    if (base != null && base > 0) {
      return data.lastPrice - base;
    }
    return 0.0;
  }
  return data.change;
}

String rankedCategoryTag(
  String symbol,
  AvailableIndices? available, {
  required bool isGlobal,
}) {
  if (isGlobal) {
    final u = symbol.toUpperCase();
    if (u.contains('NIKKEI') || u.contains('JPX')) return 'Japan';
    if (u.contains('HANG') || u.contains('HSI') || u.contains('SSE')) {
      return 'Asia';
    }
    if (u.contains('FTSE') || u.contains('DAX') || u.contains('CAC')) {
      return 'Europe';
    }
    if (u.contains('S&P') ||
        u.contains('NASDAQ') ||
        u.contains('DOW') ||
        u.contains('NYSE')) {
      return 'US Global';
    }
    return 'Global';
  }
  if (available == null) return 'Index';
  final s = symbol.toUpperCase();
  bool has(List<String> list) =>
      list.any((e) => e.toUpperCase() == s || e.toUpperCase().contains(s));
  if (has(available.broadMarketIndices)) {
    if (s.contains('BANK')) return 'Banking';
    if (s == 'NIFTY 50' || s.contains('SENSEX')) return 'Benchmark';
    return 'Broad';
  }
  if (has(available.sectoralIndices)) return 'Sectoral';
  if (has(available.thematicIndices)) return 'Thematic';
  if (has(available.strategyIndices)) return 'Strategy';
  if (s.contains('BANK')) return 'Banking';
  return 'Index';
}

List<StockIndicesMarketData> rankedSortedIndices({
  required List<StockIndicesMarketData> indian,
  required List<StockIndicesMarketData> global,
  required IndicesListFilter filter,
  required String timeframe,
  required Map<String, double> basePrices,
}) {
  List<StockIndicesMarketData> raw;
  switch (filter) {
    case IndicesListFilter.indian:
      raw = List.of(indian);
      break;
    case IndicesListFilter.global:
      raw = List.of(global);
      break;
    case IndicesListFilter.all:
      raw = [...indian, ...global];
      break;
  }
  raw.sort(
    (a, b) => rankedDisplayPChange(b, timeframe, basePrices)
        .compareTo(rankedDisplayPChange(a, timeframe, basePrices)),
  );
  return raw;
}
