import 'package:am_common/am_common.dart';
import 'package:am_portfolio_ui/core/constants/basket_endpoints.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/basket_catalog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

class BasketThemeHit {
  const BasketThemeHit({
    required this.id,
    required this.label,
    required this.query,
    this.featured = true,
  });

  final String id;
  final String label;
  final String query;
  final bool featured;
}

/// Curated Discover themes from portfolio basket catalog (Gold → GOLDBEES).
class BasketCatalogSearchAdapter {
  BasketCatalogSearchAdapter({
    Future<List<BasketThemeHit>> Function()? catalogLoader,
  }) : _catalogLoader = catalogLoader;

  final Future<List<BasketThemeHit>> Function()? _catalogLoader;

  List<BasketThemeHit>? _cache;
  bool _loggedFailure = false;
  Future<List<BasketThemeHit>>? _inFlight;

  /// Featured themes for empty Baskets suggestions (cached; may be empty).
  List<BasketThemeHit> get featuredCached {
    final all = _cache;
    if (all == null || all.isEmpty) return const [];
    final featured = all.where((t) => t.featured).toList();
    return featured.isNotEmpty ? featured : all;
  }

  /// Warm cache; safe to call repeatedly.
  Future<List<BasketThemeHit>> ensureLoaded() {
    if (_cache != null) return Future.value(_cache!);
    return _inFlight ??= _load().whenComplete(() => _inFlight = null);
  }

  Future<List<BasketThemeHit>> search(String query, {int limit = 8}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final themes = await ensureLoaded();
    final q = trimmed.toLowerCase();
    final hits = themes.where((t) {
      return t.label.toLowerCase().contains(q) ||
          t.query.toLowerCase().contains(q) ||
          t.id.toLowerCase().contains(q);
    }).toList();
    if (hits.length <= limit) return hits;
    return hits.take(limit).toList();
  }

  /// Test helper: inject themes without network.
  @visibleForTesting
  void seedCache(List<BasketThemeHit> themes) {
    _cache = List<BasketThemeHit>.from(themes);
  }

  Future<List<BasketThemeHit>> _load() async {
    try {
      final loader = _catalogLoader;
      final themes =
          loader != null ? await loader() : await _fetchFromNetwork();
      _cache = themes;
      return themes;
    } catch (e, st) {
      if (!_loggedFailure) {
        _loggedFailure = true;
        debugPrint('BasketCatalogSearchAdapter: catalog load failed: $e\n$st');
      }
      _cache ??= const [];
      return _cache!;
    }
  }

  Future<List<BasketThemeHit>> _fetchFromNetwork() async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    try {
      final token = await GetIt.I<SecureStorageService>().getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // GetIt may be unavailable in tests.
    }

    final response = await dio.get(
      BasketEndpoints.catalog,
      options: Options(headers: headers),
    );
    if (response.statusCode != 200) {
      throw StateError('catalog status ${response.statusCode}');
    }
    final data = response.data;
    Map<String, dynamic> json;
    if (data is Map<String, dynamic>) {
      json = data;
    } else if (data is Map) {
      json = Map<String, dynamic>.from(data);
    } else {
      throw StateError('Unexpected catalog payload');
    }
    final catalog = BasketCatalog.fromJson(json);
    return catalog.themes
        .map(
          (t) => BasketThemeHit(
            id: t.id,
            label: t.label,
            query: t.query,
            featured: t.featured,
          ),
        )
        .toList();
  }
}
