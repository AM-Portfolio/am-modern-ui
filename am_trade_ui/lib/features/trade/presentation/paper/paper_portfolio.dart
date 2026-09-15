import '../models/trade_portfolio_view_model.dart';
import '../../internal/data/dtos/oms_dto.dart';

List<TradePortfolioViewModel> mergePaperWallet(
  List<TradePortfolioViewModel> portfolios,
  OmsWallet? wallet,
) {
  if (wallet == null) return portfolios;
  if (portfolios.any((p) => p.id == wallet.portfolioUuid)) {
    return [
      for (final p in portfolios)
        if (p.id == wallet.portfolioUuid)
          p.copyWith(
            isPaper: true,
            totalValue: double.tryParse(wallet.available) ?? p.totalValue,
          )
        else
          p,
    ];
  }
  return [
    ...portfolios,
    TradePortfolioViewModel(
      id: wallet.portfolioUuid,
      name: 'Paper',
      description: 'Practice with virtual cash — not a live broker order.',
      totalValue: double.tryParse(wallet.available) ?? 0,
      isPaper: true,
    ),
  ];
}
