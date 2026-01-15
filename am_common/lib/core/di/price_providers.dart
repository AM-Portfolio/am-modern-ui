import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/core/services/price_service.dart';
import 'package:am_common/core/di/network_providers.dart';
import 'package:am_common/core/models/price_update_model.dart';

final priceServiceProvider = FutureProvider<PriceService>((ref) async {
  final config = await ref.watch(appConfigProvider.future);
  final service = PriceService(config);
  
  // Start connection immediately upon creation
  service.connect();
  
  // Ensure we clean up when the provider is disposed (if ever)
  ref.onDispose(() {
    service.disconnect();
  });
  
  return service;
});

final priceStreamProvider = StreamProvider<Map<String, QuoteChange>>((ref) async* {
  final service = await ref.watch(priceServiceProvider.future);
  yield* service.priceStream;
});

final priceUpdatesStreamProvider = StreamProvider<MarketDataUpdate>((ref) async* {
  final service = await ref.watch(priceServiceProvider.future);
  yield* service.updateStream;
});

final priceConnectionStatusProvider = StreamProvider<bool>((ref) async* {
  final service = await ref.watch(priceServiceProvider.future);
  yield* service.isConnectedStream;
});
