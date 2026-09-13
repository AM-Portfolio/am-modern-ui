dynamic _envelope(dynamic raw) {
  if (raw is Map && raw['data'] != null) return raw['data'];
  return raw;
}

class OmsWallet {
  const OmsWallet({
    required this.walletId,
    required this.kind,
    required this.currency,
    required this.available,
    required this.reserved,
    required this.portfolioId,
    required this.portfolioUuid,
  });

  factory OmsWallet.fromJson(Map<String, dynamic> json) => OmsWallet(
        walletId: json['walletId'] as String,
        kind: json['kind'] as String? ?? 'PAPER',
        currency: json['currency'] as String? ?? 'INR',
        available: '${json['available'] ?? '0'}',
        reserved: '${json['reserved'] ?? '0'}',
        portfolioId: json['portfolioId'] as String? ?? '',
        portfolioUuid: json['portfolioUuid'] as String? ?? '',
      );

  factory OmsWallet.fromEnvelope(dynamic raw) =>
      OmsWallet.fromJson(Map<String, dynamic>.from(_envelope(raw) as Map));

  final String walletId;
  final String kind;
  final String currency;
  final String available;
  final String reserved;
  final String portfolioId;
  final String portfolioUuid;

  bool get isPaper => kind == 'PAPER';

  static List<OmsWallet> listFromEnvelope(dynamic raw) {
    final data = _envelope(raw);
    final items = data is Map ? data['items'] : data;
    if (items is! List) return const [];
    return items
        .map((e) => OmsWallet.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

class OmsOrder {
  const OmsOrder({
    required this.orderId,
    required this.walletId,
    required this.symbol,
    required this.side,
    required this.orderType,
    required this.quantity,
    required this.status,
    this.fillPrice,
    this.filledQuantity,
    this.rejectReason,
    this.limitPrice,
    this.triggerPrice,
    this.targetPrice,
    this.stopLoss,
    this.trailJump,
    this.available,
    this.reserved,
    this.createdAt,
  });

  factory OmsOrder.fromJson(Map<String, dynamic> json) {
    final snap = json['walletSnapshot'];
    DateTime? created;
    final rawCreated = json['createdAt'] ?? json['created_at'];
    if (rawCreated != null) {
      created = DateTime.tryParse(rawCreated.toString());
    }
    return OmsOrder(
      orderId: json['orderId'] as String,
      walletId: json['walletId'] as String,
      symbol: json['symbol'] as String? ?? '',
      side: json['side'] as String? ?? '',
      orderType: json['orderType'] as String? ?? 'MARKET',
      quantity: '${json['quantity'] ?? ''}',
      status: json['status'] as String? ?? '',
      fillPrice: json['fillPrice']?.toString(),
      filledQuantity: json['filledQuantity']?.toString(),
      rejectReason: json['rejectReason'] as String?,
      limitPrice: json['limitPrice']?.toString(),
      triggerPrice: json['triggerPrice']?.toString(),
      targetPrice: json['targetPrice']?.toString(),
      stopLoss: json['stopLoss']?.toString(),
      trailJump: json['trailJump']?.toString(),
      available: snap is Map ? '${snap['available'] ?? ''}' : null,
      reserved: snap is Map ? '${snap['reserved'] ?? ''}' : null,
      createdAt: created,
    );
  }

  factory OmsOrder.fromEnvelope(dynamic raw) =>
      OmsOrder.fromJson(Map<String, dynamic>.from(_envelope(raw) as Map));

  final String orderId;
  final String walletId;
  final String symbol;
  final String side;
  final String orderType;
  final String quantity;
  final String status;
  final String? fillPrice;
  final String? filledQuantity;
  final String? rejectReason;
  final String? limitPrice;
  final String? triggerPrice;
  final String? targetPrice;
  final String? stopLoss;
  final String? trailJump;
  final String? available;
  final String? reserved;
  final DateTime? createdAt;

  bool get isFilled => status == 'FILLED';
  bool get isRejected => status == 'REJECTED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isWorking => status == 'ACCEPTED';

  /// UI label: ACCEPTED → OPEN (matches order.png).
  String get displayStatus {
    if (isWorking) return 'OPEN';
    return status;
  }

  bool get isCreatedToday {
    if (createdAt == null) return false;
    final d = createdAt!.toLocal();
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  double get quantityAsDouble => double.tryParse(quantity) ?? 0;
  double get filledQuantityAsDouble {
    if (filledQuantity == null || filledQuantity!.isEmpty) {
      return isFilled ? quantityAsDouble : 0;
    }
    return double.tryParse(filledQuantity!) ?? 0;
  }

  double get fillPriceAsDouble => double.tryParse(fillPrice ?? '') ?? 0;
  double get limitPriceAsDouble => double.tryParse(limitPrice ?? '') ?? 0;
  double get triggerPriceAsDouble => double.tryParse(triggerPrice ?? '') ?? 0;

  /// Price for table: fill if filled, else limit/trigger.
  double get displayPrice {
    if (isFilled && fillPriceAsDouble > 0) return fillPriceAsDouble;
    if (limitPriceAsDouble > 0) return limitPriceAsDouble;
    if (triggerPriceAsDouble > 0) return triggerPriceAsDouble;
    return 0;
  }

  String get qtyDisplayLabel {
    final q = quantityAsDouble;
    final qStr = q == q.roundToDouble() ? q.toStringAsFixed(0) : q.toStringAsFixed(2);
    if (isWorking || isRejected || isCancelled) {
      final f = filledQuantityAsDouble;
      final fStr = f == f.roundToDouble() ? f.toStringAsFixed(0) : f.toStringAsFixed(2);
      return '$fStr / $qStr';
    }
    final f = filledQuantityAsDouble > 0 ? filledQuantityAsDouble : q;
    return f == f.roundToDouble() ? f.toStringAsFixed(0) : f.toStringAsFixed(2);
  }

  static List<OmsOrder> listFromEnvelope(dynamic raw) {
    final data = _envelope(raw);
    final items = data is Map ? data['items'] : data;
    if (items is! List) return const [];
    return items
        .map((e) => OmsOrder.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

class OmsPosition {
  const OmsPosition({
    required this.walletId,
    required this.symbol,
    required this.qty,
  });

  factory OmsPosition.fromJson(Map<String, dynamic> json) => OmsPosition(
        walletId: json['walletId'] as String? ?? '',
        symbol: json['symbol'] as String? ?? '',
        qty: '${json['qty'] ?? '0'}',
      );

  final String walletId;
  final String symbol;
  final String qty;

  static List<OmsPosition> listFromEnvelope(dynamic raw) {
    final data = _envelope(raw);
    final items = data is Map ? data['items'] : data;
    if (items is! List) return const [];
    return items
        .map((e) => OmsPosition.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

String omsRejectMessage(String? code) {
  switch (code) {
    case 'INSUFFICIENT_CASH':
      return 'Not enough virtual cash for this order.';
    case 'INSUFFICIENT_QTY':
      return 'Not enough paper quantity to sell.';
    case 'LTP_UNAVAILABLE':
      return 'Live price unavailable — order was not filled.';
    case 'MARKET_CLOSED':
      return 'Market closed — order was not filled.';
    case 'MARKET_PREOPEN':
      return 'Market pre-open — market orders not accepted yet.';
    case 'AMO_NOT_SUPPORTED':
      return 'After-market orders are not supported yet.';
    case 'PRODUCT_NOT_SUPPORTED':
      return 'This product mode is not supported for paper.';
    case 'OPTIONS_NOT_ENABLED':
      return 'Options are not enabled yet.';
    case 'LIVE_NOT_ENABLED':
      return 'Live broker orders are not enabled.';
    case 'VALIDATION':
      return 'Check price / quantity fields.';
    case 'JOURNAL_UNAVAILABLE':
      return 'Trade journal unavailable — try again shortly.';
    case 'SERVICE_UNAVAILABLE':
    case '503':
      return 'Paper trading service temporarily unavailable (503). Retry in a moment.';
    case '502':
      return 'Paper trading gateway error (502). Retry in a moment.';
    default:
      return code == null || code.isEmpty ? 'Order rejected.' : code;
  }
}

String? omsErrorCode(Object error) {
  try {
    final dynamic err = error;
    final status = err.statusCode ?? err.status;
    if (status == 503) return '503';
    if (status == 502) return '502';
    final data = err.data;
    if (data is Map) {
      final code = (data['error_code'] ?? data['errorCode'])?.toString();
      if (code != null && code.isNotEmpty) return code;
      final detail = data['detail'];
      if (detail is Map) {
        final nested = (detail['error_code'] ?? detail['errorCode'])?.toString();
        if (nested != null && nested.isNotEmpty) return nested;
      }
    }
    final msg = err.toString();
    if (msg.contains('503')) return '503';
    if (msg.contains('502')) return '502';
  } catch (_) {}
  return null;
}
