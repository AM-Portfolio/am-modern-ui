import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mock_providers.dart';
import 'provider_contracts.dart';

/// Override these in the host app to plug real market / OMS-backed providers.
final chartHistoricalProvider = Provider<HistoricalDataProvider>(
  (ref) => MockHistoricalDataProvider(),
);

final chartMarketProvider = Provider<MarketDataProvider>(
  (ref) => MockMarketDataProvider(),
);

final chartFundamentalsProvider = Provider<FundamentalDataProvider>(
  (ref) => MockFundamentalDataProvider(),
);

final chartNewsProvider = Provider<NewsProvider>(
  (ref) => MockNewsProvider(),
);
