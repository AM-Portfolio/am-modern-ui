import 'package:am_common/am_common.dart';

import '../dtos/portfolio_summary_response_dto.dart';

/// Day P&L overlay from am-portfolio holdings (symbol → day move / value).
class PortfolioHoldingDayOverlay {
  const PortfolioHoldingDayOverlay({
    this.todayChange,
    this.todayChangePercentage,
    this.currentValue,
    this.currentPrice,
  });

  final double? todayChange;
  final double? todayChangePercentage;
  final double? currentValue;
  final double? currentPrice;
}

/// Abstract contract for fetching live portfolio summary data from am-portfolio.
abstract class PortfolioOverviewDataSource {
  /// Live summary for a single portfolio UUID. Null on miss/error.
  Future<PortfolioSummaryResponseDto?> getPortfolioSummary(String portfolioId);

  /// Per-symbol day P&L / value from Portfolio holdings — used when Trade
  /// enrich leaves todayProfitLoss null (missing previousClose on dig quotes).
  Future<Map<String, PortfolioHoldingDayOverlay>> getHoldingDayOverlays(
    String portfolioId,
  );
}

/// Concrete implementation that calls the am-portfolio REST API.
class PortfolioOverviewDataSourceImpl implements PortfolioOverviewDataSource {
  const PortfolioOverviewDataSourceImpl({
    required ApiClient apiClient,
    required PortfolioApiConfig portfolioConfig,
  })  : _apiClient = apiClient,
        _portfolioConfig = portfolioConfig;

  final ApiClient _apiClient;
  final PortfolioApiConfig _portfolioConfig;

  String _buildUri(String baseUrl, String resource) {
    final cleanBase =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanResource = resource.startsWith('/') ? resource : '/$resource';
    return '$cleanBase$cleanResource';
  }

  @override
  Future<PortfolioSummaryResponseDto?> getPortfolioSummary(
      String portfolioId) async {
    AppLogger.methodEntry(
      'getPortfolioSummary',
      tag: 'PortfolioOverviewDataSource',
      params: {'portfolioId': portfolioId},
    );

    try {
      final summaryResource = _portfolioConfig.summaryResource;
      final fullUri =
          '${_buildUri(_portfolioConfig.baseUrl, summaryResource)}?portfolioId=$portfolioId';

      var response = await _apiClient.get<PortfolioSummaryResponseDto?>(
        fullUri,
        timeout: const Duration(seconds: 5),
        parser: (data) {
          if (data == null) return null;
          final json = data as Map<String, dynamic>;
          return PortfolioSummaryResponseDto.fromJson(json);
        },
      );

      // Dig Trade often persists metrics.totalValue=0 for mail demat books.
      // Portfolio holdings already have live value + 1D — heal the card from that.
      final needsHeal = response == null ||
          response.totalValue == null ||
          response.totalValue! <= 0;
      if (needsHeal) {
        final healed = await _summaryFromHoldings(portfolioId);
        if (healed != null) {
          response = healed;
        }
      }

      AppLogger.info(
        'Portfolio summary fetched: totalValue=${response?.totalValue}, '
        'totalGainLoss=${response?.totalGainLoss}',
        tag: 'PortfolioOverviewDataSource',
      );
      AppLogger.methodExit(
        'getPortfolioSummary',
        tag: 'PortfolioOverviewDataSource',
        result: response != null ? 'success' : 'null_response',
      );

      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch portfolio summary for portfolioId=$portfolioId '
        '— trade card will show realized data only',
        tag: 'PortfolioOverviewDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      return null;
    }
  }

  @override
  Future<Map<String, PortfolioHoldingDayOverlay>> getHoldingDayOverlays(
    String portfolioId,
  ) async {
    if (portfolioId.isEmpty) return const {};
    try {
      final rows = await _fetchEquityHoldings(portfolioId);
      final out = <String, PortfolioHoldingDayOverlay>{};
      for (final row in rows) {
        final symbol = (row['symbol'] as String?)?.trim();
        if (symbol == null || symbol.isEmpty) continue;
        final key = symbol.toUpperCase();
        out[key] = PortfolioHoldingDayOverlay(
          todayChange: _asDouble(row['todayGainLoss'] ?? row['todayChange']),
          todayChangePercentage: _asDouble(
            row['todayGainLossPercentage'] ?? row['todayChangePercentage'],
          ),
          currentValue: _asDouble(row['currentValue']),
          currentPrice: _asDouble(row['currentPrice']),
        );
      }
      return out;
    } catch (e) {
      AppLogger.error(
        'Portfolio holdings day overlay failed for $portfolioId: $e',
        tag: 'PortfolioOverviewDataSource',
        error: e,
      );
      return const {};
    }
  }

  Future<PortfolioSummaryResponseDto?> _summaryFromHoldings(
    String portfolioId,
  ) async {
    final rows = await _fetchEquityHoldings(portfolioId);
    if (rows.isEmpty) return null;

    var totalValue = 0.0;
    var todayChange = 0.0;
    var gainers = 0;
    var hasToday = false;
    for (final row in rows) {
      final value = _asDouble(row['currentValue']) ?? 0;
      totalValue += value;
      final day = _asDouble(row['todayGainLoss'] ?? row['todayChange']);
      if (day != null) {
        hasToday = true;
        todayChange += day;
        if (day > 0) gainers++;
      }
    }
    if (totalValue <= 0) return null;

    return PortfolioSummaryResponseDto(
      totalValue: totalValue,
      totalGainLoss: hasToday ? todayChange : null,
      todayChange: hasToday ? todayChange : null,
      totalAssets: rows.length,
      gainersCount: gainers,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchEquityHoldings(
    String portfolioId,
  ) async {
    final holdingsResource = _portfolioConfig.holdingsResource;
    final fullUri =
        '${_buildUri(_portfolioConfig.baseUrl, holdingsResource)}?portfolioId=$portfolioId';
    final parsed = await _apiClient.get<List<Map<String, dynamic>>>(
      fullUri,
      timeout: const Duration(seconds: 4),
      parser: (data) {
        if (data == null) return <Map<String, dynamic>>[];
        final json = data as Map<String, dynamic>;
        final list = json['equityHoldings'] as List? ??
            json['holdings'] as List? ??
            const [];
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      },
    );
    return parsed;
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
