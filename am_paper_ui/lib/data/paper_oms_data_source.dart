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
  }) {
    final body = <String, dynamic>{
      'walletId': walletId,
      'venue': 'PAPER',
      'instrumentType': 'EQUITY',
      'symbol': symbol.trim().toUpperCase(),
      'side': side,
      'orderType': orderType,
      'quantity': quantity,
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

  Future<List<OmsOrder>> listOrders({required String walletId, String? status}) {
    return _apiClient.get<List<OmsOrder>>(
      _uri(_config.ordersResource),
      queryParams: {
        'walletId': walletId,
        if (status != null) 'status': status,
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
}
