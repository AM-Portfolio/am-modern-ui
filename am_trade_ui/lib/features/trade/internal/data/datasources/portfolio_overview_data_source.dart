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

      // Mail/demat books often have value but P&L stuck at 0 (no cost basis).
      // Heal value and/or P&L from Portfolio holdings (1D + overall when present).
      final needsValueHeal = response == null ||
          response.totalValue == null ||
          response.totalValue! <= 0;
      final needsPnlHeal = response == null ||
          (!_hasNonZero(response.totalGainLoss) &&
              !_hasNonZero(response.todayChange));
      if (needsValueHeal || needsPnlHeal) {
        final healed = await _summaryFromHoldings(portfolioId);
        if (healed != null) {
          response = PortfolioSummaryResponseDto(
            totalValue: needsValueHeal
                ? healed.totalValue
                : response?.totalValue ?? healed.totalValue,
            totalGainLoss: needsPnlHeal
                ? healed.totalGainLoss
                : response?.totalGainLoss ?? healed.totalGainLoss,
            totalGainLossPercentage: needsPnlHeal
                ? healed.totalGainLossPercentage
                : response?.totalGainLossPercentage ??
                    healed.totalGainLossPercentage,
            todayChange: needsPnlHeal
                ? healed.todayChange
                : response?.todayChange ?? healed.todayChange,
            todayChangePercentage: needsPnlHeal
                ? healed.todayChangePercentage
                : response?.todayChangePercentage ??
                    healed.todayChangePercentage,
            investedValue: response?.investedValue ?? healed.investedValue,
            totalAssets: response?.totalAssets ?? healed.totalAssets,
            gainersCount: response?.gainersCount ?? healed.gainersCount,
          );
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
    var overallPnl = 0.0;
    var gainers = 0;
    var hasToday = false;
    var hasOverall = false;
    for (final row in rows) {
      final value = _asDouble(row['currentValue']) ?? 0;
      totalValue += value;

      final day = _asDouble(row['todayGainLoss'] ?? row['todayChange']);
      if (day != null) {
        hasToday = true;
        todayChange += day;
        if (day > 0) gainers++;
      }

      // Prefer real overall when Portfolio marks hasGainLoss / non-zero gainLoss.
      final hasGainFlag = row['hasGainLoss'] == true;
      final overall = _asDouble(row['gainLoss'] ?? row['totalGainLoss']);
      if (overall != null && (hasGainFlag || overall != 0)) {
        hasOverall = true;
        overallPnl += overall;
      }
    }
    if (totalValue <= 0) return null;

    // Card "Live P&L": overall when known, else today's move (mail books).
    final livePnl = hasOverall ? overallPnl : (hasToday ? todayChange : null);
    final livePct = livePnl != null && totalValue > 0
        ? (livePnl / totalValue) * 100
        : null;
    final todayPct = hasToday && totalValue > 0
        ? (todayChange / totalValue) * 100
        : null;

    return PortfolioSummaryResponseDto(
      totalValue: totalValue,
      totalGainLoss: livePnl,
      totalGainLossPercentage: livePct,
      todayChange: hasToday ? todayChange : null,
      todayChangePercentage: todayPct,
      totalAssets: rows.length,
      gainersCount: gainers,
    );
  }

  static bool _hasNonZero(double? value) =>
      value != null && value != 0;

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
