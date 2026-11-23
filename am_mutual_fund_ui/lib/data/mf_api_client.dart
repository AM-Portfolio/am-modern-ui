import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_common/am_common.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import 'mf_dto.dart';
import 'mf_endpoints.dart';

/// Typed client for Asrax MF BFF. Never sends NSE credentials or gateway secrets.
class MfApiClient {
  MfApiClient({Dio? dio, String? baseUrl})
      : _dio = dio ?? _createDio(baseUrl ?? EnvDomains.mutualFund);

  final Dio _dio;
  static const _uuid = Uuid();

  static Dio _createDio(String baseUrl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl.replaceAll(RegExp(r'/+$'), ''),
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: const {'Content-Type': 'application/json'},
      ),
    );
    AuthProviders.attachAuthInterceptor(dio);
    return dio;
  }

  /// Client-generated idempotency key for purchase/redeem/switch.
  static String newIdempotencyKey() => _uuid.v4();

  Future<MfCatalogResult> searchSchemes({
    String? query,
    String? amc,
    bool? purchaseAllowed,
    int limit = 100,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      MfEndpoints.schemes,
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
        if (amc != null && amc.trim().isNotEmpty) 'amc': amc.trim(),
        if (purchaseAllowed != null) 'purchaseAllowed': purchaseAllowed,
        'limit': limit.clamp(1, 200),
      },
    );
    return _parseCatalog(response.data ?? const {});
  }

  Future<MfSchemeSummary> getScheme(String isin) async {
    final response = await _dio.get<Map<String, dynamic>>(
      MfEndpoints.scheme(isin.toUpperCase()),
    );
    final data = response.data ?? const {};
    final error = (data['error'] ?? data['detail'])?.toString() ?? '';
    if (error.toUpperCase().contains('CATALOG_UNAVAILABLE') ||
        data['unavailable'] == true) {
      throw StateError(
        data['message']?.toString() ?? 'Scheme catalog unavailable',
      );
    }
    final items = _extractItems(data);
    if (items.isNotEmpty) return MfSchemeSummary.fromJson(items.first);
    if (data.containsKey('isin') ||
        data.containsKey('scheme_id') ||
        data.containsKey('schemeName')) {
      return MfSchemeSummary.fromJson({...data, 'isin': isin.toUpperCase()});
    }
    throw StateError('Scheme not found: ${isin.toUpperCase()}');
  }

  Future<List<MfNavPoint>> getNav({
    required String isin,
    required String from,
    required String to,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      MfEndpoints.schemeNav(isin.toUpperCase()),
      queryParameters: {'from': from, 'to': to},
    );
    final data = response.data ?? const {};
    final source = (data['source'] ?? data['metricsSource'] ?? '')
        .toString()
        .toLowerCase();
    // Seed / unavailable: hide charts — never invent points client-side.
    if (source.contains('seed') || data['unavailable'] == true) {
      return const [];
    }
    final points = data['points'];
    if (points is! List) return const [];
    return points
        .whereType<Map>()
        .map((e) {
          final map = e.cast<String, dynamic>();
          final nav = _asDouble(map['nav'] ?? map['value']);
          final date = (map['date'] ?? map['as_of'] ?? '').toString();
          if (nav == null || date.isEmpty) return null;
          return MfNavPoint(date: date, nav: nav);
        })
        .whereType<MfNavPoint>()
        .toList();
  }

  Future<Map<String, dynamic>> getPerformance(String isin) async {
    final response = await _dio.get<Map<String, dynamic>>(
      MfEndpoints.schemePerformance(isin.toUpperCase()),
    );
    return response.data ?? const {};
  }

  Future<MfDistributorOp> checkKyc({
    required String pan,
    String? mobile,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      MfEndpoints.kyc,
      queryParameters: {
        'pan': pan.trim().toUpperCase(),
        if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
      },
    );
    return MfDistributorOp.fromJson(response.data ?? const {});
  }

  Future<MfDistributorOp> startEkyc({
    required String pan,
    String amcCode = '',
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      MfEndpoints.ekycStart,
      data: {
        'pan': pan.trim().toUpperCase(),
        'amc_code': amcCode,
      },
    );
    return MfDistributorOp.fromJson(response.data ?? const {});
  }

  Future<List<MfMandate>> listMandates({int limit = 50}) async {
    try {
      final response = await _dio.get<dynamic>(
        MfEndpoints.mandates,
        queryParameters: {'limit': limit.clamp(1, 200)},
      );
      final data = response.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => MfMandate.fromJson(e.cast<String, dynamic>()))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const [];
      rethrow;
    }
  }

  Future<MfDistributorOp> submitUcc(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      MfEndpoints.ucc,
      data: body,
    );
    return MfDistributorOp.fromJson(response.data ?? const {});
  }

  Future<MfDistributorOp> submitFatca(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      MfEndpoints.fatca,
      data: body,
    );
    return MfDistributorOp.fromJson(response.data ?? const {});
  }

  Future<MfDistributorOp> submitBank(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      MfEndpoints.bank,
      data: body,
    );
    return MfDistributorOp.fromJson(response.data ?? const {});
  }

  Future<MfOrder> purchase({
    required String schemeId,
    required double amount,
    String? folio,
    String? paymentMode,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? newIdempotencyKey();
    final response = await _dio.post<Map<String, dynamic>>(
      MfEndpoints.purchase,
      data: {
        'scheme_id': schemeId.toUpperCase(),
        'amount': amount,
        if (folio != null && folio.isNotEmpty) 'folio': folio,
        if (paymentMode != null && paymentMode.isNotEmpty)
          'payment_mode': paymentMode,
      },
      options: Options(headers: {'Idempotency-Key': key}),
    );
    return MfOrder.fromJson(response.data ?? const {});
  }

  Future<MfOrder> redeem({
    required String schemeId,
    required double units,
    String? folio,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? newIdempotencyKey();
    final response = await _dio.post<Map<String, dynamic>>(
      MfEndpoints.redeem,
      data: {
        'scheme_id': schemeId.toUpperCase(),
        'units': units,
        if (folio != null && folio.isNotEmpty) 'folio': folio,
      },
      options: Options(headers: {'Idempotency-Key': key}),
    );
    return MfOrder.fromJson(response.data ?? const {});
  }

  Future<MfOrder> switchScheme({
    required String fromSchemeId,
    required String toSchemeId,
    required double units,
    String? folio,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? newIdempotencyKey();
    final response = await _dio.post<Map<String, dynamic>>(
      MfEndpoints.switchOrder,
      data: {
        'from_scheme_id': fromSchemeId.toUpperCase(),
        'to_scheme_id': toSchemeId.toUpperCase(),
        'units': units,
        if (folio != null && folio.isNotEmpty) 'folio': folio,
      },
      options: Options(headers: {'Idempotency-Key': key}),
    );
    return MfOrder.fromJson(response.data ?? const {});
  }

  Future<MfMandate> getMandate(String mandateId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      MfEndpoints.mandate(mandateId),
    );
    return MfMandate.fromJson(response.data ?? const {});
  }

  Future<MfOrder> payOrder(
    String orderId, {
    String? paymentMode,
    String? bankAccountRef,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      MfEndpoints.orderPay(orderId),
      data: {
        if (paymentMode != null) 'payment_mode': paymentMode,
        if (bankAccountRef != null) 'bank_account_ref': bankAccountRef,
      },
    );
    return MfOrder.fromJson(response.data ?? const {});
  }

  Future<MfOrder> getOrder(String orderId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      MfEndpoints.order(orderId),
    );
    return MfOrder.fromJson(response.data ?? const {});
  }

  Future<MfOrder> cancelOrder(String orderId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      MfEndpoints.orderCancel(orderId),
    );
    return MfOrder.fromJson(response.data ?? const {});
  }

  Future<MfMandate> createMandate({
    required double amount,
    String? bankAccountRef,
    String? clientCode,
    String? ifsc,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      MfEndpoints.mandates,
      data: {
        'amount': amount,
        if (bankAccountRef != null) 'bank_account_ref': bankAccountRef,
        if (clientCode != null) 'client_code': clientCode,
        if (ifsc != null) 'ifsc': ifsc,
      },
    );
    return MfMandate.fromJson(response.data ?? const {});
  }

  Future<MfSip> createSip({
    required String schemeId,
    required double amount,
    String frequency = 'MONTHLY',
    String dates = '',
    String? mandateId,
    bool xsip = false,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      MfEndpoints.sips,
      data: {
        'scheme_id': schemeId.toUpperCase(),
        'amount': amount,
        'frequency': frequency,
        'dates': dates,
        if (mandateId != null && mandateId.isNotEmpty) 'mandate_id': mandateId,
        'xsip': xsip,
      },
    );
    return MfSip.fromJson(response.data ?? const {});
  }

  Future<MfDistributorOp> pauseSip(String distributorSipRef) async {
    final response = await _dio.post<Map<String, dynamic>>(
      MfEndpoints.sipPause,
      data: {'distributor_sip_ref': distributorSipRef},
    );
    return MfDistributorOp.fromJson(response.data ?? const {});
  }

  Future<MfDistributorOp> resumeSip(String distributorSipRef) async {
    final response = await _dio.post<Map<String, dynamic>>(
      MfEndpoints.sipResume,
      data: {'distributor_sip_ref': distributorSipRef},
    );
    return MfDistributorOp.fromJson(response.data ?? const {});
  }

  Future<MfDistributorOp> cancelSip(String distributorSipRef) async {
    final response = await _dio.post<Map<String, dynamic>>(
      MfEndpoints.sipCancel,
      data: {'distributor_sip_ref': distributorSipRef},
    );
    return MfDistributorOp.fromJson(response.data ?? const {});
  }

  Future<List<MfHoldingLot>> getHoldings() async {
    final response = await _dio.get<dynamic>(MfEndpoints.holdings);
    final data = response.data;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => MfHoldingLot.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<List<MfOrder>> listOrders({int limit = 50}) async {
    try {
      final response = await _dio.get<dynamic>(
        MfEndpoints.orders,
        queryParameters: {'limit': limit.clamp(1, 200)},
      );
      final data = response.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => MfOrder.fromJson(e.cast<String, dynamic>()))
          .toList();
    } on DioException catch (e) {
      // Dig images without GET /orders yet — soft empty, not Dio dump.
      if (e.response?.statusCode == 404) return const [];
      rethrow;
    }
  }

  Future<List<MfSip>> listSips({int limit = 50}) async {
    try {
      final response = await _dio.get<dynamic>(
        MfEndpoints.sips,
        queryParameters: {'limit': limit.clamp(1, 200)},
      );
      final data = response.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => MfSip.fromJson(e.cast<String, dynamic>()))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const [];
      rethrow;
    }
  }

  Future<MfDistributorOp> registerStp({
    required String fromSchemeId,
    required String toSchemeId,
    required double amount,
    String frequency = 'MONTHLY',
    String dates = '',
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      MfEndpoints.stp,
      data: {
        'from_scheme_id': fromSchemeId.toUpperCase(),
        'to_scheme_id': toSchemeId.toUpperCase(),
        'amount': amount,
        'frequency': frequency,
        'dates': dates,
      },
    );
    return MfDistributorOp.fromJson(response.data ?? const {});
  }

  Future<MfDistributorOp> registerSwp({
    required String schemeId,
    required double amount,
    String frequency = 'MONTHLY',
    String dates = '',
    String? folio,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      MfEndpoints.swp,
      data: {
        'scheme_id': schemeId.toUpperCase(),
        'amount': amount,
        'frequency': frequency,
        'dates': dates,
        if (folio != null && folio.isNotEmpty) 'folio': folio,
      },
    );
    return MfDistributorOp.fromJson(response.data ?? const {});
  }

  MfCatalogResult _parseCatalog(Map<String, dynamic> data) {
    final items = _extractItems(data)
        .map(MfSchemeSummary.fromJson)
        .where((s) => s.isin.isNotEmpty)
        .toList();
    final source = data['source']?.toString();
    final errorToken =
        (data['error'] ?? data['detail'] ?? data['message'])?.toString() ?? '';
    final message =
        (data['message'] ?? data['error'] ?? data['detail'])?.toString();
    final unavailable = errorToken.toUpperCase().contains('CATALOG_UNAVAILABLE') ||
        (message ?? '').toUpperCase().contains('CATALOG_UNAVAILABLE') ||
        (source ?? '').toLowerCase().contains('seed') ||
        data['unavailable'] == true;
    return MfCatalogResult(
      items: items,
      source: source,
      message: message,
      unavailable: unavailable,
    );
  }

  List<Map<String, dynamic>> _extractItems(Map<String, dynamic> data) {
    final raw = data['items'] ?? data['results'] ?? data['schemes'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    if (data.containsKey('isin') || data.containsKey('scheme_id')) {
      return [data];
    }
    return const [];
  }
}

double? _asDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
