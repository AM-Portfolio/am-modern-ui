import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cache_service.dart';

/// Global provider for CacheService instance
/// Use this to access cache throughout the app
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

/// State notifier for cache operations
/// Useful for tracking cache state and updates
class CacheState {
  final bool isInitialized;
  final int itemCount;

  const CacheState({
    this.isInitialized = false,
    this.itemCount = 0,
  });

  CacheState copyWith({
    bool? isInitialized,
    int? itemCount,
  }) {
    return CacheState(
      isInitialized: isInitialized ?? this.isInitialized,
      itemCount: itemCount ?? this.itemCount,
    );
  }
}

class CacheNotifier extends Notifier<CacheState> {
  late CacheService _cacheService;

  @override
  CacheState build() {
    _cacheService = ref.watch(cacheServiceProvider);
    return const CacheState();
  }

  Future<void> initialize() async {
    await _cacheService.init();
    state = state.copyWith(
      isInitialized: true,
      itemCount: _cacheService.keys.length,
    );
  }

  Future<void> updateCount() async {
    state = state.copyWith(itemCount: _cacheService.keys.length);
  }

  Future<void> clearAll() async {
    await _cacheService.clearAll();
    state = state.copyWith(itemCount: 0);
  }
}

final cacheNotifierProvider =
    NotifierProvider<CacheNotifier, CacheState>(CacheNotifier.new);
