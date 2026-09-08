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
  });

  factory OmsOrder.fromJson(Map<String, dynamic> json) {
    final snap = json['walletSnapshot'];
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

  bool get isFilled => status == 'FILLED';
  bool get isRejected => status == 'REJECTED';
  bool get isWorking => status == 'ACCEPTED';

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
    case 'OPTIONS_NOT_ENABLED':
      return 'Options are not enabled yet.';
    case 'LIVE_NOT_ENABLED':
      return 'Live broker orders are not enabled.';
    case 'VALIDATION':
      return 'Check price / quantity fields.';
    default:
      return code == null || code.isEmpty ? 'Order rejected.' : code;
  }
}

String? omsErrorCode(Object error) {
  try {
    final data = (error as dynamic).data;
    if (data is Map) {
      return (data['error_code'] ?? data['errorCode'])?.toString();
    }
  } catch (_) {}
  return null;
}
