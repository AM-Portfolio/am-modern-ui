import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'market_status.dart';
import 'market_streaming_gate.dart';

final marketStreamingGateProvider = Provider<MarketStreamingGate>((ref) {
  if (!GetIt.instance.isRegistered<MarketStreamingGate>()) {
    throw StateError('MarketStreamingGate is not registered');
  }
  return GetIt.instance<MarketStreamingGate>();
});

final marketIsOpenProvider = StreamProvider<bool>((ref) {
  final gate = ref.watch(marketStreamingGateProvider);
  return gate.isOpenStream;
});

final marketStatusProvider = Provider<MarketStatus?>((ref) {
  ref.watch(marketIsOpenProvider);
  return ref.watch(marketStreamingGateProvider).status;
});
