import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/models/basket_opportunity.dart';
import '../domain/models/basket_item.dart';
import '../domain/models/basket_enums.dart';

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
      id: id,
      etfName: "Nifty Alpha 50",
      matchScore: 85.0,
      missingStockCount: 2,
      items: [
        const BasketItem(
          symbol: "HDFCBANK",
          name: "HDFC Bank Ltd",
          weight: 12.5,
          status: BasketItemStatus.held,
        ),
        const BasketItem(
          symbol: "RELIANCE",
          name: "Reliance Industries",
          weight: 10.2,
          status: BasketItemStatus.held,
        ),
        const BasketItem(
          symbol: "ICICIBANK",
          name: "ICICI Bank Ltd",
          weight: 8.4,
          status: BasketItemStatus.held,
        ),
        const BasketItem(
          symbol: "INFY",
          name: "Infosys Ltd",
          weight: 6.8,
          status: BasketItemStatus.substitute,
          reason: "IT Sector Proxy",
          userHoldingSymbol: "TCS",
        ),
        const BasketItem(
          symbol: "LT",
          name: "Larsen & Toubro",
          weight: 4.5,
          status: BasketItemStatus.missing,
        ),
        const BasketItem(
          symbol: "ITC",
          name: "ITC Ltd",
          weight: 3.8,
          status: BasketItemStatus.held,
        ),
        const BasketItem(
          symbol: "SBIN",
          name: "State Bank of India",
          weight: 3.2,
          status: BasketItemStatus.substitute,
          reason: "PSU Bank Match",
          userHoldingSymbol: "PNB",
        ),
        const BasketItem(
          symbol: "BHARTIARTL",
          name: "Bharti Airtel",
          weight: 2.9,
          status: BasketItemStatus.missing,
        ),
      ],
    );
  }
}
