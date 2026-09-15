import 'package:am_common/core/config/app_config.dart';
import 'package:am_library/am_library.dart';

import 'oms_models.dart';

class PaperOmsDataSource {
  PaperOmsDataSource({
    required ApiClient apiClient,
    required OmsApiConfig config,
  })  : _apiClient = apiClient,
        _config = config;

  final ApiClient _apiClient;
  final OmsApiConfig _config;

  String _uri(String resource, [String extra = '']) {
    final base = _config.baseUrl.endsWith('/')
        ? _config.baseUrl.substring(0, _config.baseUrl.length - 1)
        : _config.baseUrl;
    final path = resource.startsWith('/') ? resource : '/$resource';
    return '$base$path$extra';
  }

  Future<List<OmsWallet>> listWallets({String kind = 'PAPER'}) {
    return _apiClient.get<List<OmsWallet>>(
      _uri(_config.walletsResource),
      queryParams: {'kind': kind},
      parser: OmsWallet.listFromEnvelope,
    );
  }

  Future<OmsWallet> createPaperWallet() {
    return _apiClient.post<OmsWallet>(
      _uri(_config.walletsResource),
      body: {'kind': 'PAPER', 'currency': 'INR', 'seedAmount': '1000000'},
      parser: OmsWallet.fromEnvelope,
    );
  }

  Future<OmsWallet> getWallet(String walletId) {
    return _apiClient.get<OmsWallet>(
      _uri(_config.walletsResource, '/$walletId'),
      parser: OmsWallet.fromEnvelope,
    );
  }

  Future<List<OmsPosition>> listPositions(String walletId) {
    return _apiClient.get<List<OmsPosition>>(
      _uri(_config.walletsResource, '/$walletId/positions'),
      parser: OmsPosition.listFromEnvelope,
    );
  }

  Future<OmsOrder> createOrder({
    required String walletId,
    required String symbol,
    required String side,
    required String orderType,
    required String quantity,
    required String idempotencyKey,
    String? limitPrice,
    String? triggerPrice,
    String? targetPrice,
    String? stopLoss,
    String? trailJump,
    String? entryType,
    String productMode = 'Investing',
    bool amo = false,
  }) {
    final body = <String, dynamic>{
      'walletId': walletId,
      'venue': 'PAPER',
      'instrumentType': 'EQUITY',
      'symbol': symbol.trim().toUpperCase(),
      'side': side,
      'orderType': orderType,
      'quantity': quantity,
      'productMode': productMode,
      'amo': amo,
    };
    if (limitPrice != null && limitPrice.isNotEmpty) body['limitPrice'] = limitPrice;
    if (triggerPrice != null && triggerPrice.isNotEmpty) {
      body['triggerPrice'] = triggerPrice;
    }
    if (targetPrice != null && targetPrice.isNotEmpty) body['targetPrice'] = targetPrice;
    if (stopLoss != null && stopLoss.isNotEmpty) body['stopLoss'] = stopLoss;
    if (trailJump != null && trailJump.isNotEmpty) body['trailJump'] = trailJump;
    if (entryType != null && entryType.isNotEmpty) body['entryType'] = entryType;

    return _apiClient.post<OmsOrder>(
      _uri(_config.ordersResource),
      headers: {'Idempotency-Key': idempotencyKey},
      body: body,
      parser: OmsOrder.fromEnvelope,
    );
  }

  Future<List<OmsOrder>> listOrders({
    required String walletId,
    String? status,
    DateTime? from,
    DateTime? to,
  }) {
    return _apiClient.get<List<OmsOrder>>(
      _uri(_config.ordersResource),
      queryParams: {
        'walletId': walletId,
        if (status != null) 'status': status,
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      },
      parser: OmsOrder.listFromEnvelope,
    );
  }

  Future<OmsOrder> cancelOrder(String orderId) {
    return _apiClient.post<OmsOrder>(
      _uri(_config.ordersResource, '/$orderId/cancel'),
      parser: OmsOrder.fromEnvelope,
    );
  }

  /// Cancels all ACCEPTED orders for wallet. Falls back to per-order cancel if
  /// cancel-all endpoint is not deployed yet.
  Future<int> cancelAllOrders({required String walletId}) async {
    try {
      final raw = await _apiClient.post<Map<String, dynamic>>(
        _uri(_config.ordersResource, '/cancel-all'),
        queryParams: {'walletId': walletId},
        body: const <String, dynamic>{},
        parser: (r) {
          final data = _envelope(r);
          if (data is Map) return Map<String, dynamic>.from(data);
          return <String, dynamic>{};
        },
      );
      final n = raw['cancelled'];
      if (n is int) return n;
      if (n is num) return n.toInt();
      return int.tryParse('$n') ?? 0;
    } catch (_) {
      final orders = await listOrders(walletId: walletId, status: 'ACCEPTED');
      var n = 0;
      for (final o in orders) {
        try {
          await cancelOrder(o.orderId);
          n++;
        } catch (_) {}
      }
      return n;
    }
  }

  Future<String> getOrderTypeFavorite() async {
    try {
      final raw = await _apiClient.get<Map<String, dynamic>>(
        _uri(_config.prefsResource),
        parser: (r) {
          final data = _envelope(r);
          if (data is Map) return Map<String, dynamic>.from(data);
          return <String, dynamic>{};
        },
      );
      final fav = (raw['orderTypeFavorite'] as String?)?.trim().toUpperCase();
      if (fav != null && fav.isNotEmpty) return fav;
    } catch (_) {}
    return 'MARKET';
  }

  Future<String> putOrderTypeFavorite(String orderTypeFavorite) async {
    final fav = orderTypeFavorite.trim().toUpperCase();
    try {
      final raw = await _apiClient.put<Map<String, dynamic>>(
        _uri(_config.prefsResource),
        body: {'orderTypeFavorite': fav},
        parser: (r) {
          final data = _envelope(r);
          if (data is Map) return Map<String, dynamic>.from(data);
          return <String, dynamic>{};
        },
      );
      final out = (raw['orderTypeFavorite'] as String?)?.trim().toUpperCase();
      if (out != null && out.isNotEmpty) return out;
    } catch (_) {}
    return fav;
  }
}

dynamic _envelope(dynamic raw) {
  if (raw is Map && raw['data'] != null) return raw['data'];
  return raw;
}
