import 'package:am_design_system/am_design_system.dart';
import '../dtos/portfolio_summary_dto.dart';
import '../../domain/entities/portfolio_summary.dart';
import 'package:am_common/am_common.dart';

/// Mapper to convert between API models and domain entities for portfolio summary
/// This provides isolation between external API structure and internal business logic
class PortfolioSummaryMapper {
  /// Convert API response to domain entity
  static PortfolioSummary fromApiModel(
    PortfolioSummaryDto apiModel,
    String userId,
  ) {
    try {
      // Map sector allocations
      final sectorAllocations = apiModel.sectorAllocation.entries
          .map(
            (entry) => SectorAllocation(
              sector: entry.key,
              value: 0.0, // Would need actual value from API
              percentage: entry.value,
              holdings: 0, // Would need actual count from API
            ),
          )
          .toList();

      // Map top performers
      final topPerformers = apiModel.topPerformers
          .map(
            (api) => TopPerformer(
              symbol: api.symbol,
              companyName: api.symbol, // Using symbol as company name
              gainLoss: api.gainAmount,
              gainLossPercentage: api.gainPercentage,
              currentValue: 0.0, // Default value, would need from API
            ),
          )
          .toList();

      // Map worst performers (using top losers)
      final worstPerformers = apiModel.topLosers
          .map(
            (api) => TopPerformer(
              symbol: api.symbol,
              companyName: api.symbol, // Using symbol as company name
              gainLoss: -api.lossAmount, // Negative for losses
              gainLossPercentage: -api.lossPercentage, // Negative for losses
              currentValue: 0.0, // Default value, would need from API
            ),
          )
          .toList();

      return PortfolioSummary(
        userId: userId,
        totalValue: apiModel.totalValue,
        totalInvested: apiModel.investmentValue,
        investmentValue: apiModel.investmentValue,
        totalGainLoss: apiModel.totalGain,
        totalGainLossPercentage: apiModel.totalGainPercentage,
        todayChange: apiModel.todaysGain,
        todayChangePercentage: apiModel.todaysGainPercentage,
        todayGainLossPercentage: apiModel.todayGainLossPercentage,
        totalHoldings: _calculateTotalHoldings(apiModel.marketCapHoldings),
        totalAssets: apiModel.totalAssets,
        todayGainersCount: apiModel.todayGainersCount,
        todayLosersCount: apiModel.todayLosersCount,
        gainersCount: apiModel.gainersCount,
        losersCount: apiModel.losersCount,
        lastUpdated: DateTime.now(),
        sectorAllocation: sectorAllocations,
        topPerformers: topPerformers,
        worstPerformers: worstPerformers,
      );
    } catch (e) {
      CommonLogger.error(
        'Failed to map portfolio summary from API',
        tag: 'PortfolioSummaryMapper',
        error: e,
      );
      rethrow;
    }
  }

  /// Convert domain entity to API model (for updates/requests)
  static PortfolioSummaryDto toApiModel(PortfolioSummary domainModel) =>
      PortfolioSummaryDto(
        totalValue: domainModel.totalValue,
        investmentValue: domainModel.investmentValue,
        todaysGain: domainModel.todayChange,
        totalGain: domainModel.totalGainLoss,
        totalGainPercentage: domainModel.totalGainLossPercentage,
        todaysGainPercentage: domainModel.todayChangePercentage,
        todayGainLossPercentage: domainModel.todayGainLossPercentage,
        totalAssets: domainModel.totalAssets,
        todayGainersCount: domainModel.todayGainersCount,
        todayLosersCount: domainModel.todayLosersCount,
        gainersCount: domainModel.gainersCount,
        losersCount: domainModel.losersCount,
        marketCapHoldings:
            const {}, // Empty since not available in simplified model
        sectorAllocation: _mapSectorAllocation(domainModel.sectorAllocation),
        topPerformers: _mapTopPerformers(domainModel.topPerformers),
        topLosers: _mapWorstPerformers(domainModel.worstPerformers),
      );

  /// Calculate total holdings across all market caps
  static int _calculateTotalHoldings(
    Map<String, List<MarketCapHoldingDto>> marketCapHoldings,
  ) => marketCapHoldings.values.fold(
    0,
    (sum, holdings) => sum + holdings.length,
  );

  /// Map sector allocation from domain to API
  static Map<String, double> _mapSectorAllocation(
    List<SectorAllocation> sectorAllocation,
  ) {
    final result = <String, double>{};
    for (final sector in sectorAllocation) {
      result[sector.sector] = sector.percentage;
    }
    return result;
  }

  /// Map top performers from domain to API
  static List<ApiTopPerformer> _mapTopPerformers(
    List<TopPerformer> topPerformers,
  ) => topPerformers
      .map(
        (performer) => ApiTopPerformer(
          symbol: performer.symbol,
          gainPercentage: performer.gainLossPercentage,
          gainAmount: performer.gainLoss,
        ),
      )
      .toList();

  /// Map worst performers from domain to API
  static List<ApiTopLoser> _mapWorstPerformers(
    List<TopPerformer> worstPerformers,
  ) => worstPerformers
      .map(
        (performer) => ApiTopLoser(
          symbol: performer.symbol,
          lossPercentage:
              -performer.gainLossPercentage, // Convert to positive loss
          lossAmount: -performer.gainLoss, // Convert to positive loss
        ),
      )
      .toList();

  /// Create empty portfolio summary for error states
  static PortfolioSummary createEmpty(String userId) =>
      PortfolioSummary.empty(userId);

  /// Create mock portfolio summary with sample data
  static PortfolioSummary createMock({String userId = 'mock-user'}) =>
      PortfolioSummary(
        userId: userId,
        totalValue: 125000.0,
        totalInvested: 100000.0,
        investmentValue: 100000.0,
        totalGainLoss: 25000.0,
        totalGainLossPercentage: 25.0,
        todayChange: 1500.0,
        todayChangePercentage: 1.2,
        todayGainLossPercentage: 1.2,
        totalHoldings: 10,
        totalAssets: 15,
        todayGainersCount: 8,
        todayLosersCount: 2,
        gainersCount: 7,
        losersCount: 3,
        lastUpdated: DateTime.now(),
      );

  /// Validation helper
  static bool isValidApiResponse(PortfolioSummaryDto? apiModel) =>
      apiModel != null &&
      apiModel.totalValue >= 0 &&
      apiModel.investmentValue >= 0;
}

