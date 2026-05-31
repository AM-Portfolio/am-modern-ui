import 'package:am_design_system/am_design_system.dart';
import '../dtos/portfolio_summary_dto.dart';
import '../../domain/entities/portfolio_summary.dart';
import 'package:am_common/am_common.dart';

/// Mapper to convert between API models and domain entities for portfolio summary.
/// Aligned with the Java backend PortfolioSummaryV1 + BasePortfolioSummay models.
class PortfolioSummaryMapper {
  /// Convert API response DTO to domain entity
  static PortfolioSummary fromApiModel(
    PortfolioSummaryDto apiModel,
  ) {
    try {
      // Build sector allocation from sectorialHoldings map
      final sectorAllocations = <SectorAllocation>[];
      apiModel.sectorialHoldings.forEach((sectorName, holdings) {
        // Step A - Name sanitization
        String sanitizedName = sectorName;
        if (sanitizedName.isEmpty || sanitizedName == '-' || sanitizedName == 'null') {
          sanitizedName = 'Uncategorized';
        }

        // Calculate total value for this sector
        double sectorValue = 0.0;
        for (final h in holdings) {
          sectorValue += h.currentValue;
        }
        double sectorWeight = apiModel.currentValue > 0
            ? (sectorValue / apiModel.currentValue) * 100
            : 0.0;
        sectorAllocations.add(
          SectorAllocation(
            sector: sanitizedName,
            value: sectorValue,
            percentage: sectorWeight,
            holdings: holdings.length,
          ),
        );
      });

      // Step B - Merge duplicates
      final mergedSectors = <String, SectorAllocation>{};
      for (final alloc in sectorAllocations) {
        if (mergedSectors.containsKey(alloc.sector)) {
          final existing = mergedSectors[alloc.sector]!;
          mergedSectors[alloc.sector] = SectorAllocation(
            sector: alloc.sector,
            value: existing.value + alloc.value,
            percentage: existing.percentage + alloc.percentage,
            holdings: existing.holdings + alloc.holdings,
          );
        } else {
          mergedSectors[alloc.sector] = alloc;
        }
      }

      // Step C - Roll up tiny sectors
      final finalSectors = <SectorAllocation>[];
      double othersValue = 0.0, othersPercentage = 0.0;
      int othersHoldings = 0;
      bool hasOthers = false;

      for (final sector in mergedSectors.values) {
        if (sector.percentage < 2.0) {
          othersValue += sector.value;
          othersPercentage += sector.percentage;
          othersHoldings += sector.holdings;
          hasOthers = true;
        } else {
          finalSectors.add(sector);
        }
      }

      if (hasOthers) {
        finalSectors.add(SectorAllocation(
          sector: 'Others',
          value: othersValue,
          percentage: othersPercentage,
          holdings: othersHoldings,
        ));
      }

      // Sort sectors by value descending
      finalSectors.sort((a, b) => b.value.compareTo(a.value));

      // Build top performers from all holdings (sorted by gainLossPercentage desc)
      final allHoldings = <SectorialEquityHoldingDto>[];
      apiModel.sectorialHoldings.forEach((_, holdings) {
        allHoldings.addAll(holdings);
      });

      // Deduplicate by ISIN (holdings appear in both marketCap and sectorial)
      final seen = <String>{};
      final uniqueHoldings = <SectorialEquityHoldingDto>[];
      for (final h in allHoldings) {
        if (h.isin.isNotEmpty && seen.add(h.isin)) {
          uniqueHoldings.add(h);
        }
      }

      // Top performers: highest positive gainLossPercentage
      final sortedByGain = List<SectorialEquityHoldingDto>.from(uniqueHoldings)
        ..sort((a, b) => b.gainLossPercentage.compareTo(a.gainLossPercentage));
      final topPerformers = sortedByGain
          .where((h) => h.gainLossPercentage > 0)
          .take(5)
          .map(
            (h) => TopPerformer(
              symbol: h.symbol,
              companyName: h.name.isNotEmpty ? h.name : h.symbol,
              gainLoss: h.gainLoss,
              gainLossPercentage: h.gainLossPercentage,
              currentValue: h.currentValue,
            ),
          )
          .toList();

      // Worst performers: lowest (most negative) gainLossPercentage
      final worstPerformers = sortedByGain.reversed
          .where((h) => h.gainLossPercentage < 0)
          .take(5)
          .map(
            (h) => TopPerformer(
              symbol: h.symbol,
              companyName: h.name.isNotEmpty ? h.name : h.symbol,
              gainLoss: h.gainLoss,
              gainLossPercentage: h.gainLossPercentage,
              currentValue: h.currentValue,
            ),
          )
          .toList();

      return PortfolioSummary(
        totalValue: apiModel.currentValue,
        totalInvested: apiModel.investmentValue,
        investmentValue: apiModel.investmentValue,
        totalGainLoss: apiModel.totalGainLoss,
        totalGainLossPercentage: apiModel.totalGainLossPercentage,
        todayChange: apiModel.todayGainLoss,
        todayChangePercentage: apiModel.todayGainLossPercentage,
        todayGainLossPercentage: apiModel.todayGainLossPercentage,
        totalHoldings: uniqueHoldings.length,
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
        currentValue: domainModel.totalValue,
        investmentValue: domainModel.investmentValue,
        totalGainLoss: domainModel.totalGainLoss,
        totalGainLossPercentage: domainModel.totalGainLossPercentage,
        todayGainLoss: domainModel.todayChange,
        todayGainLossPercentage: domainModel.todayGainLossPercentage,
        totalAssets: domainModel.totalAssets,
        todayGainersCount: domainModel.todayGainersCount,
        todayLosersCount: domainModel.todayLosersCount,
        gainersCount: domainModel.gainersCount,
        losersCount: domainModel.losersCount,
        marketCapHoldings: const {},
        sectorialHoldings: const {},
        brokerPortfolios: const {},
      );

  /// Create empty portfolio summary for error states
  static PortfolioSummary createEmpty() =>
      PortfolioSummary.empty();

  /// Create mock portfolio summary with sample data
  static PortfolioSummary createMock() =>
      PortfolioSummary(
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
      apiModel.currentValue >= 0 &&
      apiModel.investmentValue >= 0;
}
