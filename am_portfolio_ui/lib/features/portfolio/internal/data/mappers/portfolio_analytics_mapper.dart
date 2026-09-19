import '../dtos/portfolio_analytics_request_dto.dart';
import '../dtos/portfolio_analytics_response_dto.dart';
import '../../domain/entities/portfolio_analytics_request.dart';
import '../../domain/entities/portfolio_analytics.dart';
import 'package:am_design_system/am_design_system.dart' show TimeFrame;

/// Mapper for portfolio analytics data conversion between DTOs and entities
class PortfolioAnalyticsMapper {
  // Request mapping methods

  /// Convert analytics request entity to DTO
  static PortfolioAnalyticsRequestDto requestToDto(
    PortfolioAnalyticsRequest request,
  ) => PortfolioAnalyticsRequestDto(
    coreIdentifiers: CoreIdentifiersDto(
      portfolioId: request.coreIdentifiers.portfolioId,
    ),
    featureToggles: FeatureTogglesDto(
      includeHeatmap: request.featureToggles.includeHeatmap,
      includeMovers: request.featureToggles.includeMovers,
      includeSectorAllocation: request.featureToggles.includeSectorAllocation,
      includeMarketCapAllocation:
          request.featureToggles.includeMarketCapAllocation,
    ),
    featureConfiguration: FeatureConfigurationDto(
      moversLimit: request.featureConfiguration.moversLimit,
    ),
    pagination: PaginationDto(
      page: request.pagination.page,
      size: request.pagination.size,
      sortBy: request.pagination.sortBy,
      sortDirection: request.pagination.sortDirection,
      returnAllData: request.pagination.returnAllData,
    ),
    fromDate: request.fromDate,
    toDate: request.toDate,
    timeFrame: request.timeFrame,
  );

  /// Convert analytics request DTO to entity
  static PortfolioAnalyticsRequest requestFromDto(
    PortfolioAnalyticsRequestDto dto,
  ) => PortfolioAnalyticsRequest(
    coreIdentifiers: CoreIdentifiers(
      portfolioId: dto.coreIdentifiers.portfolioId,
    ),
    featureToggles: FeatureToggles(
      includeHeatmap: dto.featureToggles.includeHeatmap,
      includeMovers: dto.featureToggles.includeMovers,
      includeSectorAllocation: dto.featureToggles.includeSectorAllocation,
      includeMarketCapAllocation: dto.featureToggles.includeMarketCapAllocation,
    ),
    featureConfiguration: FeatureConfiguration(
      moversLimit: dto.featureConfiguration.moversLimit,
    ),
    pagination: Pagination(
      page: dto.pagination.page,
      size: dto.pagination.size,
      sortBy: dto.pagination.sortBy,
      sortDirection: dto.pagination.sortDirection,
      returnAllData: dto.pagination.returnAllData,
    ),
    fromDate: dto.fromDate,
    toDate: dto.toDate,
    timeFrame: dto.timeFrame,
  );

  // Response mapping methods

  /// Convert JSON to analytics response DTO
  static PortfolioAnalyticsResponseDto responseFromJson(
    Map<String, dynamic> json,
  ) => PortfolioAnalyticsResponseDto.fromJson(json);

  /// Convert analytics response DTO to entity
  static PortfolioAnalytics responseFromDto(
    PortfolioAnalyticsResponseDto dto,
  ) => PortfolioAnalytics(
    portfolioId: dto.portfolioId ?? 'Unknown Portfolio',
    timestamp: dto.timestamp != null
        ? DateTime.parse(dto.timestamp!)
        : DateTime.now(),
    analytics: dto.analytics != null
        ? _analyticsFromDto(dto.analytics!)
        : _createEmptyAnalytics(),
  );

  /// Convert analytics DTO to entity
  static Analytics _analyticsFromDto(AnalyticsDto dto) => Analytics(
    heatmap: dto.heatmap != null ? _heatmapFromDto(dto.heatmap!) : null,
    movers: dto.movers != null ? _moversFromDto(dto.movers!) : null,
    sectorAllocation: dto.sectorAllocation != null
        ? _sectorAllocationFromDto(dto.sectorAllocation!)
        : null,
    marketCapAllocation: dto.marketCapAllocation != null
        ? _marketCapAllocationFromDto(dto.marketCapAllocation!)
        : null,
  );

  /// Convert heatmap DTO to entity
  static Heatmap _heatmapFromDto(HeatmapDto dto) =>
      Heatmap(sectors: dto.sectors?.map(_sectorFromDto).toList() ?? []);

  static String _normalizeSectorName(String? name) {
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty ||
        trimmed == '-' ||
        trimmed.toLowerCase() == 'unknown') {
      return 'Unknown Sector';
    }
    return trimmed;
  }

  /// Convert sector DTO to entity
  static Sector _sectorFromDto(SectorDto dto) => Sector(
    sectorName: _normalizeSectorName(dto.sectorName),
    performanceRank: dto.performanceRank ?? 0,
    performance: dto.performance ?? 0.0,
    changePercent: dto.changePercent ?? 0.0,
    weightage: dto.weightage ?? 0.0,
    color: dto.color ?? '#CCCCCC',
    stockCount: dto.stockCount ?? 0,
    totalValue: dto.totalValue ?? 0.0,
    totalReturnAmount: dto.totalReturnAmount ?? 0.0,
    stocks: dto.stocks?.map(_stockFromDto).toList() ?? [],
  );

  /// Convert stock DTO to entity (derive day move from previousClose when flat).
  static Stock _stockFromDto(StockDto dto) {
    var changeAmount = dto.changeAmount ?? 0.0;
    var changePercent = dto.changePercent ?? 0.0;
    final last = dto.lastPrice ?? 0.0;
    final prev = dto.previousClose;
    if (changePercent.abs() < 0.005 &&
        changeAmount.abs() < 0.005 &&
        prev != null &&
        prev > 0 &&
        last > 0) {
      changeAmount = last - prev;
      changePercent = (changeAmount / prev) * 100;
    }
    return Stock(
      symbol: dto.symbol ?? 'UNKNOWN',
      companyName: dto.companyName ?? 'Unknown Company',
      lastPrice: last,
      changeAmount: changeAmount,
      changePercent: changePercent,
      sector: _normalizeSectorName(dto.sector),
      quantity: dto.quantity ?? 0.0,
      avgPrice: dto.avgPrice ?? 0.0,
      marketValue: dto.marketValue ?? 0.0,
      totalReturn: dto.totalReturn ?? 0.0,
      weight: dto.weight,
      previousClose: dto.previousClose,
    );
  }

  /// Convert movers DTO to entity
  static Movers _moversFromDto(MoversDto dto) {
    final topGainers = (dto.topGainers ?? const <StockDto>[])
        .map(_stockFromDto)
        .where((s) => s.changePercent > 0.005)
        .toList();

    final topLosers = (dto.topLosers ?? const <StockDto>[])
        .map(_stockFromDto)
        .where((s) => s.changePercent < -0.005)
        .toList();

    return Movers(
      topGainers: List<Stock>.from(topGainers),
      topLosers: List<Stock>.from(topLosers),
    );
  }

  /// Convert sector allocation DTO to entity
  static SectorAllocation _sectorAllocationFromDto(SectorAllocationDto dto) =>
      SectorAllocation(
        sectorWeights:
            dto.sectorWeights?.map(_sectorWeightFromDto).toList() ?? [],
        industryWeights:
            dto.industryWeights?.map(_industryWeightFromDto).toList() ?? [],
      );

  /// Convert sector weight DTO to entity
  static SectorWeight _sectorWeightFromDto(SectorWeightDto dto) => SectorWeight(
    sectorName: _normalizeSectorName(dto.sectorName),
    weightPercentage: dto.weightPercentage ?? 0.0,
    marketCap: dto.marketCap ?? 0.0,
    topStocks: dto.topStocks ?? [],
  );

  /// Convert industry weight DTO to entity
  static IndustryWeight _industryWeightFromDto(IndustryWeightDto dto) =>
      IndustryWeight(
        industryName: dto.industryName ?? 'Unknown Industry',
        parentSector: _normalizeSectorName(dto.parentSector),
        weightPercentage: dto.weightPercentage ?? 0.0,
        marketCap: dto.marketCap ?? 0.0,
        topStocks: dto.topStocks ?? [],
      );

  /// Convert market cap allocation DTO to entity
  static MarketCapAllocation _marketCapAllocationFromDto(
    MarketCapAllocationDto dto,
  ) => MarketCapAllocation(
    segments: dto.segments?.map(_marketCapSegmentFromDto).toList() ?? [],
  );

  /// Convert market cap segment DTO to entity
  static MarketCapSegment _marketCapSegmentFromDto(MarketCapSegmentDto dto) =>
      MarketCapSegment(
        segmentName: dto.segmentName ?? 'Unknown Segment',
        weightPercentage: dto.weightPercentage ?? 0.0,
        segmentValue: dto.segmentValue ?? 0.0,
        numberOfStocks: dto.numberOfStocks ?? 0,
        topStocks: dto.topStocks ?? [],
      );

  // Helper method to create default analytics request

  /// Create a default analytics request for a portfolio
  static PortfolioAnalyticsRequest createDefaultRequest(
    String portfolioId, {
    TimeFrame? timeFrame,
    FeatureToggles? featureToggles,
  }) {
    String? fromDateStr;
    String? toDateStr;
    String? backendTimeFrame;

    if (timeFrame != null) {
      final now = DateTime.now();

      // Backend TimeFrame @JsonValue codes: 1D / 1W / 1M / 1Y
      // oneDay must omit timeFrame+dates so BE takes the live holdings path.
      // Same-day hist (1D + from=to=today) returns empty heatmap/allocation on prod today.
      switch (timeFrame) {
        case TimeFrame.oneDay:
          break;
        case TimeFrame.oneWeek:
          fromDateStr = _ymd(now.subtract(const Duration(days: 7)));
          toDateStr = _ymd(now);
          backendTimeFrame = '1W';
          break;
        case TimeFrame.oneMonth:
          fromDateStr = _ymd(now.subtract(const Duration(days: 30)));
          toDateStr = _ymd(now);
          backendTimeFrame = '1M';
          break;
        case TimeFrame.threeMonths:
          fromDateStr = _ymd(now.subtract(const Duration(days: 90)));
          toDateStr = _ymd(now);
          backendTimeFrame = '1M';
          break;
        case TimeFrame.sixMonths:
          fromDateStr = _ymd(now.subtract(const Duration(days: 180)));
          toDateStr = _ymd(now);
          backendTimeFrame = '1M';
          break;
        case TimeFrame.oneYear:
          fromDateStr = _ymd(now.subtract(const Duration(days: 365)));
          toDateStr = _ymd(now);
          backendTimeFrame = '1Y';
          break;
        case TimeFrame.ytd:
          fromDateStr = _ymd(DateTime(now.year, 1, 1));
          toDateStr = _ymd(now);
          backendTimeFrame = '1Y';
          break;
        case TimeFrame.threeYears:
          fromDateStr = _ymd(now.subtract(const Duration(days: 1095)));
          toDateStr = _ymd(now);
          backendTimeFrame = '1Y';
          break;
        case TimeFrame.fiveYears:
          fromDateStr = _ymd(now.subtract(const Duration(days: 1825)));
          toDateStr = _ymd(now);
          backendTimeFrame = '1Y';
          break;
        case TimeFrame.all:
          fromDateStr = _ymd(now.subtract(const Duration(days: 3650)));
          toDateStr = _ymd(now);
          backendTimeFrame = '1Y';
          break;
      }
    }

    return PortfolioAnalyticsRequest(
      coreIdentifiers: CoreIdentifiers(portfolioId: portfolioId),
      featureToggles: featureToggles ??
          const FeatureToggles(
            includeHeatmap: true,
            includeMovers: true,
            includeSectorAllocation: true,
            includeMarketCapAllocation: true,
          ),
      featureConfiguration: const FeatureConfiguration(moversLimit: 10),
      pagination: const Pagination(
        page: 1,
        size: 500,
        sortBy: 'performance',
        sortDirection: 'DESC',
        returnAllData: true,
      ),
      fromDate: fromDateStr,
      toDate: toDateStr,
      timeFrame: backendTimeFrame,
    );
  }

  /// Create empty analytics when DTO analytics is null
  static Analytics _createEmptyAnalytics() => const Analytics();

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
