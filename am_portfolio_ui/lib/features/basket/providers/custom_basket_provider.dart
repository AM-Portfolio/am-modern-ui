
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/models/custom_basket.dart';

part 'custom_basket_provider.g.dart';

@riverpod
class CustomBasketNotifier extends _$CustomBasketNotifier {
  @override
  CustomBasket build() {
    return const CustomBasket(
      name: 'My Custom Basket',
      investmentAmount: 100000,
      stocks: [],
    );
  }

  void updateInvestmentAmount(double amount) {
    state = state.copyWith(investmentAmount: amount);
  }

  void updateBasketName(String name) {
    state = state.copyWith(name: name);
  }

  void addStock(CustomBasketStock stock) {
    final updatedStocks = [...state.stocks, stock];
    state = state.copyWith(stocks: updatedStocks);
    _recalculateWeights();
  }

  void removeStock(String symbol) {
    final updatedStocks = state.stocks.where((s) => s.symbol != symbol).toList();
    state = state.copyWith(stocks: updatedStocks);
    _recalculateWeights();
  }

  void updateStockWeight(String symbol, double newWeight) {
    final updatedStocks = state.stocks.map((stock) {
      if (stock.symbol == symbol) {
        return stock.copyWith(weight: newWeight);
      }
      return stock;
    }).toList();
    state = state.copyWith(stocks: updatedStocks);
  }

  void _recalculateWeights() {
    // Auto-distribute weights equally
    if (state.stocks.isEmpty) return;
    
    final equalWeight = 100.0 / state.stocks.length;
    final updatedStocks = state.stocks.map((stock) {
      return stock.copyWith(weight: equalWeight);
    }).toList();
    
    state = state.copyWith(stocks: updatedStocks);
  }

  void clearBasket() {
    state = const CustomBasket(
      name: 'My Custom Basket',
      investmentAmount: 100000,
      stocks: [],
    );
  }
}

// Mock stock search provider
@riverpod
class StockSearchNotifier extends _$StockSearchNotifier {
  @override
  List<CustomBasketStock> build() {
    return _getMockStocks();
  }

  List<CustomBasketStock> search(String query) {
    if (query.isEmpty) return _getMockStocks();
    
    final lowercaseQuery = query.toLowerCase();
    return _getMockStocks()
        .where((stock) =>
            stock.symbol.toLowerCase().contains(lowercaseQuery) ||
            stock.name.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  List<CustomBasketStock> _getMockStocks() {
    return const [
      CustomBasketStock(symbol: 'RELIANCE', name: 'Reliance Industries', weight: 0, sector: 'Oil & Gas'),
      CustomBasketStock(symbol: 'TCS', name: 'Tata Consultancy Services', weight: 0, sector: 'IT'),
      CustomBasketStock(symbol: 'HDFCBANK', name: 'HDFC Bank', weight: 0, sector: 'Finance'),
      CustomBasketStock(symbol: 'INFY', name: 'Infosys', weight: 0, sector: 'IT'),
      CustomBasketStock(symbol: 'ICICIBANK', name: 'ICICI Bank', weight: 0, sector: 'Finance'),
      CustomBasketStock(symbol: 'HINDUNILVR', name: 'Hindustan Unilever', weight: 0, sector: 'FMCG'),
      CustomBasketStock(symbol: 'ITC', name: 'ITC Ltd', weight: 0, sector: 'FMCG'),
      CustomBasketStock(symbol: 'SBIN', name: 'State Bank of India', weight: 0, sector: 'Finance'),
      CustomBasketStock(symbol: 'BHARTIARTL', name: 'Bharti Airtel', weight: 0, sector: 'Telecom'),
      CustomBasketStock(symbol: 'KOTAKBANK', name: 'Kotak Mahindra Bank', weight: 0, sector: 'Finance'),
      CustomBasketStock(symbol: 'LT', name: 'Larsen & Toubro', weight: 0, sector: 'Construction'),
      CustomBasketStock(symbol: 'AXISBANK', name: 'Axis Bank', weight: 0, sector: 'Finance'),
    ];
  }
}
