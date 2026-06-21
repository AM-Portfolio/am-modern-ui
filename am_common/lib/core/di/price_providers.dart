import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:am_library/core/network/websocket/am_stomp_client.dart';
import 'package:am_common/core/services/price_service.dart';
import 'package:am_common/core/di/network_providers.dart';
import 'package:am_common/core/models/price_update_model.dart';

final priceServiceProvider = FutureProvider<PriceService>((ref) async {
  await ref.watch(appConfigProvider.future);
  final stompClient = GetIt.instance.isRegistered<AmStompClient>()
      ? GetIt.instance<AmStompClient>()
      : null;
  final service = PriceService(stompClient: stompClient);

  // Keep one PriceService for the app session — avoids mass UNSUBSCRIBE on tab changes.
  ref.keepAlive();
  service.connect();

  ref.onDispose(() {
    service.detach();
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
