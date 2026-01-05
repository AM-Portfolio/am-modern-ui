import '../dtos/portfolio_analytics_request_dto.dart';
import '../dtos/portfolio_analytics_response_dto.dart';
import '../../domain/entities/portfolio_analytics_request.dart';
import '../../domain/entities/portfolio_analytics.dart';

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

  /// Convert sector DTO to entity
  static Sector _sectorFromDto(SectorDto dto) => Sector(
    sectorName: dto.sectorName ?? 'Unknown Sector',
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

  /// Convert stock DTO to entity
  static Stock _stockFromDto(StockDto dto) => Stock(
    symbol: dto.symbol ?? 'UNKNOWN',
    companyName: dto.companyName ?? 'Unknown Company',
    lastPrice: dto.lastPrice ?? 0.0,
    changeAmount: dto.changeAmount ?? 0.0,
    changePercent: dto.changePercent ?? 0.0,
    sector: dto.sector ?? 'Unknown',
    quantity: dto.quantity ?? 0.0,
    avgPrice: dto.avgPrice ?? 0.0,
    marketValue: dto.marketValue ?? 0.0,
    totalReturn: dto.totalReturn ?? 0.0,
    weight: dto.weight, // Include weight field from DTO
  );

  /// Convert movers DTO to entity
  static Movers _moversFromDto(MoversDto dto) => Movers(
    topGainers: dto.topGainers?.map(_stockFromDto).toList() ?? [],
    topLosers: dto.topLosers?.map(_stockFromDto).toList() ?? [],
  );

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
    sectorName: dto.sectorName ?? 'Unknown Sector',
    weightPercentage: dto.weightPercentage ?? 0.0,
    marketCap: dto.marketCap ?? 0.0,
    topStocks: dto.topStocks ?? [],
  );

  /// Convert industry weight DTO to entity
  static IndustryWeight _industryWeightFromDto(IndustryWeightDto dto) =>
      IndustryWeight(
        industryName: dto.industryName ?? 'Unknown Industry',
        parentSector: dto.parentSector ?? 'Unknown Sector',
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
  static PortfolioAnalyticsRequest createDefaultRequest(String portfolioId) =>
      PortfolioAnalyticsRequest(
        coreIdentifiers: CoreIdentifiers(portfolioId: portfolioId),
        featureToggles: const FeatureToggles(
          includeHeatmap: true,
          includeMovers: true,
          includeSectorAllocation: true,
          includeMarketCapAllocation: true,
        ),
        featureConfiguration: const FeatureConfiguration(moversLimit: 10),
        pagination: const Pagination(
          page: 1,
          size: 20,
          sortBy: 'performance',
          sortDirection: 'DESC',
          returnAllData: false,
        ),
      );

  /// Create empty analytics when DTO analytics is null
  static Analytics _createEmptyAnalytics() => const Analytics();
}
