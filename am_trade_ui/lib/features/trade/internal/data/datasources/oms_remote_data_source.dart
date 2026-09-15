import 'package:am_common/core/config/app_config.dart';
import 'package:am_library/am_library.dart';

import '../dtos/oms_dto.dart';

abstract class OmsRemoteDataSource {
  Future<List<OmsWallet>> listWallets({String kind = 'PAPER'});
  Future<OmsWallet> createPaperWallet();
  Future<OmsWallet> getWallet(String walletId);
  Future<OmsOrder> createOrder({
    required String walletId,
    required String symbol,
    required String side,
    required String quantity,
    required String idempotencyKey,
  });
  Future<List<OmsOrder>> listOrders({required String walletId});
}

class OmsRemoteDataSourceImpl implements OmsRemoteDataSource {
  OmsRemoteDataSourceImpl({
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

  @override
  Future<List<OmsWallet>> listWallets({String kind = 'PAPER'}) {
    return _apiClient.get<List<OmsWallet>>(
      _uri(_config.walletsResource),
      queryParams: {'kind': kind},
      parser: OmsWallet.listFromEnvelope,
    );
  }

  @override
  Future<OmsWallet> createPaperWallet() {
    return _apiClient.post<OmsWallet>(
      _uri(_config.walletsResource),
      body: {'kind': 'PAPER', 'currency': 'INR', 'seedAmount': '1000000'},
      parser: OmsWallet.fromEnvelope,
    );
  }

  @override
  Future<OmsWallet> getWallet(String walletId) {
    return _apiClient.get<OmsWallet>(
      _uri(_config.walletsResource, '/$walletId'),
      parser: OmsWallet.fromEnvelope,
    );
  }

  @override
  Future<OmsOrder> createOrder({
    required String walletId,
    required String symbol,
    required String side,
    required String quantity,
    required String idempotencyKey,
  }) {
    return _apiClient.post<OmsOrder>(
      _uri(_config.ordersResource),
      headers: {'Idempotency-Key': idempotencyKey},
      body: {
        'walletId': walletId,
        'venue': 'PAPER',
        'instrumentType': 'EQUITY',
        'symbol': symbol.trim().toUpperCase(),
        'side': side,
        'orderType': 'MARKET',
        'quantity': quantity,
      },
      parser: OmsOrder.fromEnvelope,
    );
  }

  @override
  Future<List<OmsOrder>> listOrders({required String walletId}) {
    return _apiClient.get<List<OmsOrder>>(
      _uri(_config.ordersResource),
      queryParams: {'walletId': walletId},
      parser: OmsOrder.listFromEnvelope,
    );
  }
}
