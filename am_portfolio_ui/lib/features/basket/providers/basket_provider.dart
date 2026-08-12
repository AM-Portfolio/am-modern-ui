
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/models/basket_opportunity.dart';

part 'basket_provider.g.dart';

@riverpod
class BasketNotifier extends _$BasketNotifier {
  @override
  FutureOr<BasketOpportunity> build(String id) async {
    // Determine if we should load mock data or real data
    // For now, let's load some mock data after a delay to simulate fetching
    return _fetchBasketDetails(id);
  }

  Future<BasketOpportunity> _fetchBasketDetails(String id) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Mock Data matching doc/SmartBasketPreview.png
    return BasketOpportunity(
      etfIsin: id,
      etfName: "Nifty Alpha 50",
      matchScore: 85.0,
      missingCount: 2,
      composition: [
        const BasketItem(
          stockSymbol: "HDFCBANK",
          isin: "dummy",
          sector: "dummy",
          etfWeight: 12.5,
          userWeight: 12.5,
          replicaWeight: 12.5,
          status: ItemStatus.held,
        ),
         const BasketItem(
          stockSymbol: "RELIANCE",
          isin: "dummy",
          sector: "dummy",
          etfWeight: 10.2,
          userWeight: 10.2,
          replicaWeight: 10.2,
          status: ItemStatus.held,
        ),
         const BasketItem(
          stockSymbol: "ICICIBANK",
          isin: "dummy",
          sector: "dummy",
          etfWeight: 8.4,
          userWeight: 8.4,
          replicaWeight: 8.4,
          status: ItemStatus.held,
        ),
        const BasketItem(
          stockSymbol: "INFY",
          isin: "dummy",
          sector: "dummy",
          etfWeight: 6.8,
          userWeight: 0.0,
          replicaWeight: 6.8,
          status: ItemStatus.substitute,
        ),
         const BasketItem(
          stockSymbol: "LT",
          isin: "dummy",
          sector: "dummy",
          etfWeight: 4.5,
          userWeight: 0.0,
          replicaWeight: 0.0,
          status: ItemStatus.missing,
        ),
         const BasketItem(
          stockSymbol: "ITC",
          isin: "dummy",
          sector: "dummy",
          etfWeight: 3.8,
          userWeight: 3.8,
          replicaWeight: 3.8,
          status: ItemStatus.held,
        ),
        const BasketItem(
          stockSymbol: "SBIN",
          isin: "dummy",
          sector: "dummy",
          etfWeight: 3.2,
          userWeight: 0.0,
          replicaWeight: 3.2,
          status: ItemStatus.substitute,
        ),
         const BasketItem(
          stockSymbol: "BHARTIARTL",
          isin: "dummy",
          sector: "dummy",
          etfWeight: 2.9,
          userWeight: 0.0,
          replicaWeight: 0.0,
          status: ItemStatus.missing,
        ),
      ],
    );
  }
}
