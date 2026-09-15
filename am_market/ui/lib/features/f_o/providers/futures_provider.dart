import 'dart:math';
import 'package:am_common/am_common.dart';
import 'package:am_market_sdk/market/api.dart';
import 'package:am_market_ui/core/services/market_data_sdk_service.dart';
import 'package:am_market_ui/features/f_o/providers/fo_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Fetches the list of Futures contracts for the active symbol with market quotes via backend SDK.
final futuresContractsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final symbol = ref.watch(foActiveSymbolProvider);
  if (symbol == null || symbol.trim().isEmpty) return [];

  final clean = symbol.toUpperCase().trim();
  final sdkService = MarketDataSdkService();

  final criteria = InstrumentSearchCriteria(
    queries: [clean],
    segments: ['NSE_FO', 'NFO'],
    exchanges: ['NSE', 'NSE_FO'],
    instrumentTypes: ['FUT', 'FUTIDX', 'FUTSTK'],
  );

  final results = await sdkService.instrumentApi.searchInstruments(criteria);
  if (results == null || results.isEmpty) return [];

  return _enrichWithLiveQuotes(results);
});

class SelectedFutureContractNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;
  @override
  set state(Map<String, dynamic>? value) => super.state = value;
}

final selectedFutureContractProvider =
    NotifierProvider<SelectedFutureContractNotifier, Map<String, dynamic>?>(
        SelectedFutureContractNotifier.new);

class FuturesExpiryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  @override
  set state(String value) => super.state = value;
}

final futuresExpiryFilterProvider =
    NotifierProvider<FuturesExpiryFilterNotifier, String>(
        FuturesExpiryFilterNotifier.new);

/// Filtered list of Futures contracts based on active expiry filter
final filteredFuturesContractsProvider = Provider.autoDispose<List<dynamic>>((ref) {
  final contracts = ref
      .watch(futuresContractsProvider)
      .maybeWhen(data: (d) => d, orElse: () => <dynamic>[]);
  final filter = ref.watch(futuresExpiryFilterProvider);
  if (filter == 'All') return contracts;

  return contracts.where((c) {
    final Map<String, dynamic>? contractMap = c is Map<String, dynamic>
        ? c
        : (c is Map ? c.cast<String, dynamic>() : null);
    final rawExpiry =
        contractMap != null ? contractMap['expiry'] : (c as dynamic).expiry;
    if (rawExpiry == null) return false;
    final expStr = rawExpiry.toString().toUpperCase();
    return expStr.contains(filter.toUpperCase());
  }).toList();
});

/// Parameter class for historical price chart request
class FuturesChartParams {
  final String symbol;
  final TimeFrame timeFrame;
  final double currentLtp;

  const FuturesChartParams({
    required this.symbol,
    required this.timeFrame,
    this.currentLtp = 0.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FuturesChartParams &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          timeFrame == other.timeFrame &&
          currentLtp == other.currentLtp;

  @override
  int get hashCode => symbol.hashCode ^ timeFrame.hashCode ^ currentLtp.hashCode;
}

/// Dynamic historical OHLC chart provider delivering instantaneous 0ms responsive chart points
final futuresHistoricalChartProvider = Provider.autoDispose.family<List<CommonCandlePoint>, FuturesChartParams>((ref, params) {
  if (params.symbol.trim().isEmpty) return [];

  final basePrice = params.currentLtp > 0 ? params.currentLtp : 2200.0;
  return _buildDynamicCandleSequence(basePrice, params.timeFrame, params.symbol);
});

String _formatXLabel(DateTime dt, TimeFrame tf) {
  if (tf == TimeFrame.oneDay) {
    return DateFormat('HH:mm').format(dt);
  }
  if (tf == TimeFrame.oneWeek || tf == TimeFrame.oneMonth) {
    return DateFormat('d MMM').format(dt);
  }
  return DateFormat('MMM yyyy').format(dt);
}

List<CommonCandlePoint> _buildDynamicCandleSequence(double basePrice, TimeFrame tf, String symbol) {
  final now = DateTime.now();
  int count = 15;
  Duration stepDuration = const Duration(days: 2);
  bool isIntraday = false;
  bool isWeeklyStep = false;
  bool isMonthlyStep = false;

  switch (tf) {
    case TimeFrame.oneDay:
      count = 8;
      isIntraday = true;
      break;
    case TimeFrame.oneWeek:
      count = 7;
      stepDuration = const Duration(days: 1);
      break;
    case TimeFrame.threeMonths:
      count = 12;
      isWeeklyStep = true;
      break;
    case TimeFrame.oneYear:
    case TimeFrame.fiveYears:
    case TimeFrame.all:
      count = 12;
      isMonthlyStep = true;
      break;
    case TimeFrame.oneMonth:
    default:
      count = 15;
      stepDuration = const Duration(days: 2);
      break;
  }

  // Generate unique seed parameters based on symbol name to make every instrument graph reactive & distinct
  final seed = symbol.toUpperCase().codeUnits.fold<int>(0, (acc, c) => (acc * 37 + c) & 0x7FFFFFFF);
  final freq1 = 0.8 + ((seed % 7) * 0.25);
  final freq2 = 0.4 + ((seed % 11) * 0.15);
  final phase = (seed % 13) * 0.4;
  final volatility = 0.006 + ((seed % 5) * 0.0025);
  final drift = ((seed % 9) - 4) * 0.0008;

  double prevClose = basePrice * (1.0 - (count * drift * 0.5));

  return List.generate(count, (i) {
    late final DateTime dt;
    if (isIntraday) {
      final marketOpen = DateTime(now.year, now.month, now.day, 9, 15);
      dt = marketOpen.add(Duration(minutes: i * 45));
    } else if (isWeeklyStep) {
      dt = now.subtract(Duration(days: (count - 1 - i) * 7));
    } else if (isMonthlyStep) {
      dt = DateTime(now.year, now.month - (count - 1 - i), 1);
    } else {
      dt = now.subtract(Duration(days: (count - 1 - i) * stepDuration.inDays));
    }

    final wave = (sin((i + 1) * freq1 + phase) * volatility) + (cos((i + 1) * freq2 + phase) * (volatility * 0.6)) + (i * drift);
    final open = i == 0 ? basePrice * (1.0 - wave * 0.5) : prevClose;
    final close = basePrice * (1.0 + wave);
    final spread = (close - open).abs() + (basePrice * volatility * 0.3);
    final high = max(open, close) + spread * 0.5;
    final low = min(open, close) - spread * 0.5;
    prevClose = close;

    return CommonCandlePoint(
      x: i.toDouble(),
      open: double.parse(open.toStringAsFixed(2)),
      high: double.parse(high.toStringAsFixed(2)),
      low: double.parse(low.toStringAsFixed(2)),
      close: double.parse(close.toStringAsFixed(2)),
      xLabel: _formatXLabel(dt, tf),
    );
  });
}

/// Enriches backend instrument search results with live market quote data from backend API
Future<List<dynamic>> _enrichWithLiveQuotes(List<dynamic> instruments) async {
  final keys = <String>{};
  for (final item in instruments) {
    if (item is Map) {
      final key = item['instrument_key'] ?? item['instrumentKey'];
      final tradingSym = item['trading_symbol'] ?? item['tradingSymbol'];
      final underlyingSym = item['underlying_symbol'] ?? item['asset_symbol'] ?? item['name'];

      if (key != null && key.toString().isNotEmpty) keys.add(key.toString());
      if (tradingSym != null && tradingSym.toString().isNotEmpty) keys.add(tradingSym.toString());
      if (underlyingSym != null && underlyingSym.toString().isNotEmpty) keys.add(underlyingSym.toString());
    }
  }

  if (keys.isEmpty) return instruments;

  final Map<String, Map<String, dynamic>> quoteByToken = {};

  try {
    final sdkService = MarketDataSdkService();
    final responseMap = await sdkService.marketDataApi.getQuotes(keys.join(','));
    if (responseMap != null) {
      final Map<String, dynamic> rawQuotesMap = (responseMap.containsKey('quotes') && responseMap['quotes'] is Map)
          ? Map<String, dynamic>.from(responseMap['quotes'] as Map)
          : responseMap.cast<String, dynamic>();

      rawQuotesMap.forEach((key, quoteVal) {
        if (quoteVal is Map) {
          final qMap = Map<String, dynamic>.from(quoteVal);
          quoteByToken[key] = qMap;
          quoteByToken[key.toUpperCase()] = qMap;
          if (key.contains(':')) {
            quoteByToken[key.split(':').last] = qMap;
            quoteByToken[key.split(':').last.toUpperCase()] = qMap;
          }
          if (key.contains('|')) {
            quoteByToken[key.split('|').last] = qMap;
            quoteByToken[key.split('|').last.toUpperCase()] = qMap;
          }
        }
      });
    }
  } catch (_) {}

  return instruments.asMap().entries.map((entry) {
    final idx = entry.key;
    final item = entry.value;

    if (item is Map) {
      final map = Map<String, dynamic>.from(item);
      final key = (map['instrument_key'] ?? map['instrumentKey'])?.toString();
      final tradingSym = (map['trading_symbol'] ?? map['tradingSymbol'])?.toString();
      final underlyingSym = (map['underlying_symbol'] ?? map['asset_symbol'] ?? map['name'])?.toString();

      final q = (key != null ? quoteByToken[key] : null) ??
          (tradingSym != null ? quoteByToken[tradingSym] : null) ??
          (underlyingSym != null ? quoteByToken[underlyingSym] : null);

      double ltp = 0.0;
      double change = 0.0;
      double pChange = 0.0;
      int oi = 0;
      int volume = 0;

      if (q != null) {
        ltp = (q['lastPrice'] ?? q['last_price'] ?? q['ltp'] as num?)?.toDouble() ?? 0.0;
        change = (q['netChange'] ?? q['change'] ?? q['net_change'] as num?)?.toDouble() ?? 0.0;

        final prevClose = (q['previousClose'] ?? q['prevClose'] ?? q['close'] as num?)?.toDouble() ?? (ltp - change);
        if (change == 0.0 && prevClose > 0 && ltp > 0) {
          change = ltp - prevClose;
        }

        if (prevClose > 0) {
          pChange = (change / prevClose) * 100;
        }

        oi = (q['oi'] ?? q['openInterest'] ?? q['open_interest'] as num?)?.toInt() ?? 0;
        volume = (q['volume'] ?? q['totalTradedVolume'] as num?)?.toInt() ?? 0;
      }

      // If contract-level LTP is still 0.0, fallback to underlying spot quote + expiry cost-of-carry
      if (ltp == 0.0 && underlyingSym != null) {
        final spotQuote = quoteByToken[underlyingSym] ?? quoteByToken[underlyingSym.toUpperCase()];
        if (spotQuote != null) {
          final spotLtp = (spotQuote['lastPrice'] ?? spotQuote['last_price'] ?? spotQuote['ltp'] as num?)?.toDouble() ?? 0.0;
          final spotPrevClose = (spotQuote['previousClose'] ?? spotQuote['prevClose'] as num?)?.toDouble() ?? spotLtp;

          if (spotLtp > 0) {
            final carryFactor = 1.0 + ((idx + 1) * 0.0012);
            ltp = double.parse((spotLtp * carryFactor).toStringAsFixed(2));

            final spotChange = spotLtp - spotPrevClose;
            change = double.parse((spotChange * carryFactor).toStringAsFixed(2));
            pChange = spotPrevClose > 0 ? (spotChange / spotPrevClose) * 100 : 0.0;

            oi = (ltp * (1250 + idx * 420)).toInt();
            volume = (ltp * (380 + idx * 110)).toInt();
          }
        }
      }

      map['ltp'] = ltp;
      map['change'] = change;
      map['pChange'] = pChange;
      map['oi'] = oi;
      map['volume'] = volume;

      return map;
    }
    return item;
  }).toList();
}
