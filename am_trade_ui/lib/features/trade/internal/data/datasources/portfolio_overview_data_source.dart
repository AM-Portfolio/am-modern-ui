import 'package:am_common/am_common.dart';

import '../dtos/portfolio_summary_response_dto.dart';

/// Abstract contract for fetching live portfolio summary data from am-portfolio.
///
/// This data source is the bridge between the Trade dashboard and the
/// Portfolio service. It calls a single endpoint and returns a lightweight
/// DTO containing only the Unrealized P&L fields needed by the card UI.
abstract class PortfolioOverviewDataSource {
  /// Fetch the live summary for a single portfolio by its UUID.
  ///
  /// Returns null if the portfolio is not found in am-portfolio or if the
  /// request fails (callers should handle null gracefully).
  Future<PortfolioSummaryResponseDto?> getPortfolioSummary(String portfolioId);
}

/// Concrete implementation that calls the am-portfolio REST API.
///
/// Endpoint: GET {portfolioBaseUrl}/v1/portfolios/summary?portfolioId={id}
class PortfolioOverviewDataSourceImpl implements PortfolioOverviewDataSource {
  const PortfolioOverviewDataSourceImpl({
    required ApiClient apiClient,
    required PortfolioApiConfig portfolioConfig,
  })  : _apiClient = apiClient,
        _portfolioConfig = portfolioConfig;

  final ApiClient _apiClient;
  final PortfolioApiConfig _portfolioConfig;

  /// Helper to safely build URI avoiding double slashes
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
      // Portfolio API: GET /v1/portfolios/summary?portfolioId={id}
      // This endpoint already exists in PortfolioController.java and returns
      // PortfolioSummaryV1 which has totalValue, totalGainLoss etc.
      //
      // We use T = PortfolioSummaryResponseDto? (nullable) so the parser can
      // safely return null when the API returns an empty body. Any network
      // errors (including timeouts) are caught in the catch block below and
      // returned as null so the trade card can degrade gracefully.
      final summaryResource = _portfolioConfig.summaryResource;
      final fullUri =
          '${_buildUri(_portfolioConfig.baseUrl, summaryResource)}?portfolioId=$portfolioId';

      final response = await _apiClient.get<PortfolioSummaryResponseDto?>(
        fullUri,
        timeout: const Duration(seconds: 5),
        parser: (data) {
          if (data == null) return null;
          // Defensively handle the response — the portfolio summary can return
          // nested structures. We pick the fields we need from the top level.
          final json = data as Map<String, dynamic>;
          return PortfolioSummaryResponseDto.fromJson(json);
        },
      );

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
      // We intentionally catch and return null here. A failed portfolio
      // summary fetch must NOT crash the Trade dashboard. The card will
      // show realized data only and gracefully degrade.
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
}
