import '../dtos/portfolio_holdings_dto.dart';
import '../dtos/broker_holding_dto.dart';
import '../../domain/entities/portfolio_holding.dart';

/// Mapper to convert between API models and domain entities
/// This provides isolation between external API structure and internal business logic
class PortfolioHoldingsMapper {
  /// Convert API response to domain entity
  static PortfolioHoldings fromApiModel(
    PortfolioHoldingsDto apiModel,
    String userId,
  ) {
    final holdings = apiModel.equityHoldings.map(_mapEquityHolding).toList();

    return PortfolioHoldings(
      userId: userId,
      holdings: holdings,
      lastUpdated: DateTime.now(),
    );
  }

  /// Convert domain entity to API model (for updates/requests)
  static PortfolioHoldingsDto toApiModel(PortfolioHoldings domainModel) {
    final apiHoldings = domainModel.holdings
        .map(_mapToApiEquityHolding)
        .toList();

    return PortfolioHoldingsDto(equityHoldings: apiHoldings);
  }

  /// Map individual equity holding from API to domain
  static PortfolioHolding _mapEquityHolding(EquityHoldingDto apiHolding) {
    // Map broker holdings
    final brokerHoldings = apiHolding.brokerPortfolios
        .map(
          (apiBroker) => BrokerHolding(
            brokerId: apiBroker.brokerType,
            brokerName: _formatBrokerName(apiBroker.brokerType),
            quantity: apiBroker.quantity,
            avgPrice: apiHolding.quantity > 0
                ? apiHolding.investmentCost / apiHolding.quantity
                : 0.0,
            investedAmount: apiHolding.quantity > 0
                ? (apiBroker.quantity / apiHolding.quantity) *
                      apiHolding.investmentCost
                : 0.0,
            lastUpdated: DateTime.now(),
          ),
        )
        .toList();

    return PortfolioHolding(
      id: apiHolding.isin,
      symbol: apiHolding.symbol,
      companyName: _extractCompanyName(apiHolding.symbol),
      sector: apiHolding.sector,
      industry: apiHolding.industry,
      quantity: apiHolding.quantity,
      avgPrice: apiHolding.quantity > 0
          ? apiHolding.investmentCost / apiHolding.quantity
          : 0.0,
      currentPrice: apiHolding.currentPrice,
      investedAmount: apiHolding.investmentCost,
      currentValue: apiHolding.currentValue,
      todayChange: apiHolding.todayGainLoss,
      todayChangePercentage: apiHolding.todayGainLossPercentage,
      totalGainLoss: apiHolding.gainLoss,
      totalGainLossPercentage: apiHolding.gainLossPercentage,
      portfolioWeight: apiHolding.weightInPortfolio,
      brokerHoldings: brokerHoldings,
    );
  }

  /// Map domain entity back to API model
  static EquityHoldingDto _mapToApiEquityHolding(
    PortfolioHolding domainHolding,
  ) {
    final apiBrokers = domainHolding.brokerHoldings
        .map(
          (broker) => BrokerHoldingDto(
            brokerType: broker.brokerName,
            quantity: broker.quantity,
          ),
        )
        .toList();

    return EquityHoldingDto(
      isin: domainHolding.id,
      symbol: domainHolding.symbol,
      sector: domainHolding.sector,
      industry: domainHolding.industry,
      marketCap:
          'Unknown', // Default value since not available in simplified model
      quantity: domainHolding.quantity,
      investmentCost: domainHolding.investedAmount,
      currentValue: domainHolding.currentValue,
      weightInPortfolio: domainHolding.portfolioWeight,
      gainLoss: domainHolding.totalGainLoss,
      gainLossPercentage: domainHolding.totalGainLossPercentage,
      todayGainLoss: domainHolding.todayChange,
      todayGainLossPercentage: domainHolding.todayChangePercentage,
      currentPrice: domainHolding.currentPrice,
      percentageChange: domainHolding.todayChangePercentage,
      brokerPortfolios: apiBrokers,
    );
  }

  /// Helper to extract company name from symbol or other sources
  static String _extractCompanyName(String symbol) {
    // This could be enhanced with a mapping service or API call
    // For now, return symbol as placeholder
    return symbol;
  }

  /// Helper to format broker names consistently
  static String _formatBrokerName(String brokerType) {
    // Standardize broker names for UI display
    switch (brokerType.toLowerCase()) {
      case 'zerodha':
      case 'ZERODHA':
        return 'Zerodha';
      case 'upstox':
      case 'UPSTOX':
        return 'Upstox';
      case 'groww':
      case 'GROWW':
        return 'Groww';
      case 'angelone':
      case 'ANGELONE':
      case 'angel one':
        return 'Angel One';
      default:
        return brokerType;
    }
  }

  /// Create empty portfolio for error states
  static PortfolioHoldings createEmpty(String userId) =>
      PortfolioHoldings.empty(userId);

  /// Validation helper
  static bool isValidApiResponse(PortfolioHoldingsDto? apiModel) =>
      apiModel != null && apiModel.equityHoldings.isNotEmpty;
}
