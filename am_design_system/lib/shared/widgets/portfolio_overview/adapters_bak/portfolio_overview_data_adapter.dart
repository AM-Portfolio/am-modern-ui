import 'package:am_portfolio_package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_summary.dart';
import 'package:am_portfolio_package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_analytics.dart';
import 'package:am_portfolio_package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_holding.dart';
import '../contracts/portfolio_overview_data_contract.dart';
import '../models/portfolio_overview_data.dart';

/// Adapter to transform API data into overview data model
class PortfolioOverviewDataAdapter implements PortfolioOverviewDataContract {
  PortfolioOverviewDataAdapter({
    required this.getSummary,
    required this.getAnalytics,
    required this.getHoldings,
  });

  final Future<PortfolioSummary> Function(String) getSummary;
  final Future<PortfolioAnalytics> Function(String) getAnalytics;
  final Future<PortfolioHoldings> Function(String) getHoldings;

  @override
  Future<PortfolioOverviewData> getOverviewData(String portfolioId) async {
    final results = await Future.wait([
      getSummary(portfolioId),
      getAnalytics(portfolioId),
      getHoldings(portfolioId),
    ]);

    final summary = results[0] as PortfolioSummary;
    final analytics = results[1] as PortfolioAnalytics;
    final holdings = results[2] as PortfolioHoldings;

    return PortfolioOverviewData(
      summary: _transformSummary(summary),
      topGainers: _extractTopMovers(holdings.holdings, isGainers: true),
      topLosers: _extractTopMovers(holdings.holdings, isGainers: false),
      sectorAllocation: _transformSectorAllocation(analytics),
      marketCapAllocation: _transformMarketCapAllocation(analytics),
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<void> refreshOverviewData(String portfolioId) async {
    // Refresh is handled by invalidating providers
  }

  @override
  Stream<PortfolioOverviewData>? watchOverviewData(String portfolioId) {
    // Stream implementation can be added if needed
    return null;
  }

  OverviewSummaryData _transformSummary(PortfolioSummary summary) {
    return OverviewSummaryData(
      totalValue: summary.totalValue,
      todayChange: summary.todayChange,
      todayChangePercent: summary.todayChangePercentage,
      totalGainLoss: summary.totalGainLoss,
      totalGainLossPercent: summary.totalGainLossPercentage,
      totalHoldings: summary.totalHoldings,
      investedAmount: summary.totalInvested,
      availableCash: 0.0,
    );
  }

  List<OverviewMoversData> _extractTopMovers(
    List<PortfolioHolding> holdings, {
    required bool isGainers,
  }) {
    final sorted = List<PortfolioHolding>.from(holdings);
    sorted.sort((a, b) {
      final aChange = a.todayChangePercentage;
      final bChange = b.todayChangePercentage;
      return isGainers ? bChange.compareTo(aChange) : aChange.compareTo(bChange);
    });

    return sorted.take(5).map((holding) {
      return OverviewMoversData(
        symbol: holding.symbol,
        name: holding.companyName,
        currentPrice: holding.currentPrice,
        changeAmount: holding.todayChange,
        changePercent: holding.todayChangePercentage,
        sector: holding.sector,
      );
    }).toList();
  }

  List<AllocationItem> _transformSectorAllocation(PortfolioAnalytics analytics) {
    // Use sector allocation from analytics if available
    final sectorAlloc = analytics.analytics.sectorAllocation;
    if (sectorAlloc == null || sectorAlloc.sectorWeights.isEmpty) return [];

    return sectorAlloc.sectorWeights.map((sector) {
      return AllocationItem(
        label: sector.sectorName,
        value: sector.marketCap,
        percentage: sector.weightPercentage,
        count: sector.topStocks.length,
      );
    }).toList();
  }

  List<AllocationItem> _transformMarketCapAllocation(
    PortfolioAnalytics analytics,
  ) {
    final marketCap = analytics.analytics.marketCapAllocation;
    if (marketCap == null || marketCap.segments.isEmpty) return [];

    return marketCap.segments.map((segment) {
      return AllocationItem(
        label: segment.segmentName,
        value: segment.segmentValue,
        percentage: segment.weightPercentage,
        count: segment.numberOfStocks,
      );
    }).toList();
  }
}
