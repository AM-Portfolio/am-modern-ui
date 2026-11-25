import 'package:am_chart_ui/am_chart_ui.dart';
import 'package:flutter/foundation.dart';

import '../../config/paper_chart_trade_ui_config.dart';
import '../../data/oms_models.dart';

/// Holds chart trade lines and syncs place / cancel / drag with OMS.
class PaperChartTradeLinesController extends ChangeNotifier {
  PaperChartTradeLinesController({
    required PaperChartTradeUiConfig config,
    required this.placeOrder,
    required this.cancelOrder,
  })  : _config = config,
        executionPreference = config.dualExecutionPreference;

  PaperChartTradeUiConfig _config;
  final Future<OmsOrder?> Function({
    required String symbol,
    required String side,
    required String orderType,
    required String quantity,
    String? limitPrice,
    String? triggerPrice,
    String? targetPrice,
    String? stopLoss,
    String? trailJump,
    String? entryType,
  }) placeOrder;
  final Future<void> Function(String orderId) cancelOrder;

  final List<ChartTradeLine> _lines = [];
  ChartTradeLineSide? pendingSide;
  String? pendingSymbol;
  String? pendingOrderType;
  String? pendingQty;
  String? pendingTarget;
  String? pendingStop;
  String? pendingTrail;

  /// Queued second side when [allowDualPending] — placed after the active side.
  ChartTradeLineSide? queuedSide;
  String? queuedOrderType;
  String? queuedQty;
  String? queuedTarget;
  String? queuedStop;
  String? queuedTrail;

  DualExecutionPreference executionPreference;

  int _seq = 0;
  String? _draggingId;

  List<ChartTradeLine> get lines => List.unmodifiable(_lines);
  PaperChartTradeUiConfig get config => _config;

  void updateConfig(PaperChartTradeUiConfig config) {
    final changed = !identical(_config, config) && _config != config;
    _config = config;
    if (config.allowDualPending) {
      executionPreference = config.dualExecutionPreference;
    }
    if (changed) notifyListeners();
  }

  void setExecutionPreference(DualExecutionPreference pref) {
    if (executionPreference == pref) return;
    executionPreference = pref;
    _reorderPendingForPreference();
    notifyListeners();
  }

  void _reorderPendingForPreference() {
    if (queuedSide == null || pendingSide == null) return;
    final preferBuy = executionPreference == DualExecutionPreference.buyFirst;
    final activeIsPreferred = preferBuy
        ? pendingSide == ChartTradeLineSide.buy
        : pendingSide == ChartTradeLineSide.sell;
    if (activeIsPreferred) return;
    _swapPendingAndQueued();
  }

  void _swapPendingAndQueued() {
    final s = pendingSide;
    final ot = pendingOrderType;
    final q = pendingQty;
    final t = pendingTarget;
    final st = pendingStop;
    final tr = pendingTrail;
    pendingSide = queuedSide;
    pendingOrderType = queuedOrderType;
    pendingQty = queuedQty;
    pendingTarget = queuedTarget;
    pendingStop = queuedStop;
    pendingTrail = queuedTrail;
    queuedSide = s;
    queuedOrderType = ot;
    queuedQty = q;
    queuedTarget = t;
    queuedStop = st;
    queuedTrail = tr;
  }

  void armPending({
    required String symbol,
    required ChartTradeLineSide side,
    String? orderType,
    String? quantity,
    String? targetPrice,
    String? stopLoss,
    String? trailJump,
  }) {
    if (!_config.tradeLinesEnabled || !_config.placeFromWatchlistBuySell) {
      return;
    }
    final sym = symbol.trim().toUpperCase();
    final type =
        (orderType ?? _config.resolveDefaultOrderType()).toUpperCase();
    final qty = quantity ?? _config.resolveDefaultQuantity();

    if (_config.allowDualPending &&
        pendingSide != null &&
        pendingSymbol == sym &&
        pendingSide != side) {
      // Second side: queue it. Preference already follows whichever was armed first.
      queuedSide = side;
      queuedOrderType = type;
      queuedQty = qty;
      queuedTarget = targetPrice;
      queuedStop = stopLoss;
      queuedTrail = trailJump;
      _reorderPendingForPreference();
      notifyListeners();
      return;
    }

    final same = pendingSymbol == sym &&
        pendingSide == side &&
        pendingOrderType == type &&
        pendingQty == qty &&
        pendingTarget == targetPrice &&
        pendingStop == stopLoss &&
        pendingTrail == trailJump &&
        queuedSide == null;
    if (same) return;

    if (!_config.allowDualPending || pendingSymbol != sym) {
      queuedSide = null;
      queuedOrderType = null;
      queuedQty = null;
      queuedTarget = null;
      queuedStop = null;
      queuedTrail = null;
    }

    pendingSymbol = sym;
    pendingSide = side;
    pendingOrderType = type;
    pendingQty = qty;
    pendingTarget = targetPrice;
    pendingStop = stopLoss;
    pendingTrail = trailJump;
    // First click wins: Sell first → sell executes/places first (red), not config default.
    if (_config.allowDualPending) {
      executionPreference = side == ChartTradeLineSide.sell
          ? DualExecutionPreference.sellFirst
          : DualExecutionPreference.buyFirst;
    }
    notifyListeners();
  }

  void clearPending() {
    if (pendingSide == null &&
        pendingSymbol == null &&
        queuedSide == null) {
      return;
    }
    pendingSide = null;
    pendingSymbol = null;
    pendingOrderType = null;
    pendingQty = null;
    pendingTarget = null;
    pendingStop = null;
    pendingTrail = null;
    queuedSide = null;
    queuedOrderType = null;
    queuedQty = null;
    queuedTarget = null;
    queuedStop = null;
    queuedTrail = null;
    notifyListeners();
  }

  void _promoteQueued() {
    if (queuedSide == null) return;
    pendingSide = queuedSide;
    pendingOrderType = queuedOrderType;
    pendingQty = queuedQty;
    pendingTarget = queuedTarget;
    pendingStop = queuedStop;
    pendingTrail = queuedTrail;
    queuedSide = null;
    queuedOrderType = null;
    queuedQty = null;
    queuedTarget = null;
    queuedStop = null;
    queuedTrail = null;
  }

  Future<void> placeAtPrice(
    ChartTradeLineSide side,
    double price, {
    double? anchorXNorm,
  }) async {
    final symbol = pendingSymbol;
    final orderType = (pendingOrderType ?? _config.resolveDefaultOrderType())
        .toUpperCase();
    final qty = pendingQty ?? _config.resolveDefaultQuantity();
    if (symbol == null || symbol.isEmpty) return;

    final target = pendingTarget;
    final stop = pendingStop;
    final trail = pendingTrail;
    final hadQueued = queuedSide != null;

    // Clear only the active arm; keep queued for dual place.
    pendingSide = null;
    pendingOrderType = null;
    pendingQty = null;
    pendingTarget = null;
    pendingStop = null;
    pendingTrail = null;
    if (!hadQueued) {
      pendingSymbol = null;
    }
    notifyListeners();

    if (orderType == 'MARKET' && !_config.marketKeepsLine) {
      await placeOrder(
        symbol: symbol,
        side: side == ChartTradeLineSide.buy ? 'BUY' : 'SELL',
        orderType: 'MARKET',
        quantity: qty,
      );
      if (hadQueued) {
        _promoteQueued();
        notifyListeners();
      }
      return;
    }

    final limit = price.toStringAsFixed(2);
    final isStop = orderType == 'STOP';
    final order = await placeOrder(
      symbol: symbol,
      side: side == ChartTradeLineSide.buy ? 'BUY' : 'SELL',
      orderType: orderType,
      quantity: qty,
      limitPrice: isStop ? null : limit,
      triggerPrice: isStop ? limit : null,
      targetPrice: orderType == 'SUPER' ? target : null,
      stopLoss: orderType == 'SUPER' ? stop : null,
      trailJump: orderType == 'TRAIL' ? trail : null,
      entryType: orderType == 'SUPER' ? 'LIMIT' : null,
    );

    if (order == null || !order.isWorking) {
      if (hadQueued) {
        // Drop the queue if the preferred side failed.
        clearPending();
      }
      return;
    }

    final line = ChartTradeLine(
      id: 'tl${_seq++}',
      side: side,
      price: price,
      orderType: orderType,
      symbol: symbol,
      orderId: order.orderId,
      quantity: qty,
      anchorXNorm: anchorXNorm,
    );
    _lines.add(line.copyWith(label: line.detailLabel));
    if (hadQueued) {
      _promoteQueued();
    } else {
      pendingSymbol = null;
    }
    notifyListeners();
  }

  void onDragPrice(String id, double newPrice) {
    final idx = _lines.indexWhere((l) => l.id == id);
    if (idx < 0) return;
    _draggingId = id;
    final next = _lines[idx].copyWith(price: newPrice);
    _lines[idx] = next.copyWith(label: next.detailLabel);
    notifyListeners();
  }

  Future<void> commitDrag(String id) async {
    if (_draggingId != id) return;
    _draggingId = null;
    if (!_config.replaceOnDrag) return;
    await _replaceLineOrder(id);
  }

  /// Edit type/qty on an existing line — cancel + re-place at same price.
  Future<void> updateLineOrder(
    String id, {
    required String orderType,
    required String quantity,
  }) async {
    final idx = _lines.indexWhere((l) => l.id == id);
    if (idx < 0) return;
    final line = _lines[idx];
    var type = orderType.trim().toUpperCase();
    if (type.isEmpty) type = line.orderType;
    final qty = quantity.trim().isEmpty
        ? (line.quantity ?? _config.resolveDefaultQuantity())
        : quantity.trim();

    if (type == 'MARKET' && !_config.marketKeepsLine) {
      final oldId = line.orderId;
      _lines.removeAt(idx);
      notifyListeners();
      if (oldId != null && oldId.isNotEmpty) await cancelOrder(oldId);
      await placeOrder(
        symbol: line.symbol,
        side: line.side == ChartTradeLineSide.buy ? 'BUY' : 'SELL',
        orderType: 'MARKET',
        quantity: qty,
      );
      return;
    }

    _lines[idx] = line.copyWith(orderType: type, quantity: qty);
    notifyListeners();
    await _replaceLineOrder(id);
  }

  Future<void> _replaceLineOrder(String id) async {
    final idx = _lines.indexWhere((l) => l.id == id);
    if (idx < 0) return;
    final line = _lines[idx];
    final oldId = line.orderId;
    if (oldId != null && oldId.isNotEmpty) {
      await cancelOrder(oldId);
    }
    final limit = line.price.toStringAsFixed(2);
    final isStop = line.orderType == 'STOP';
    final order = await placeOrder(
      symbol: line.symbol,
      side: line.side == ChartTradeLineSide.buy ? 'BUY' : 'SELL',
      orderType: line.orderType,
      quantity: line.quantity ?? _config.resolveDefaultQuantity(),
      limitPrice: isStop ? null : limit,
      triggerPrice: isStop ? limit : null,
    );
    if (order == null || !order.isWorking) {
      _lines.removeAt(idx);
      notifyListeners();
      return;
    }
    final next = line.copyWith(orderId: order.orderId);
    _lines[idx] = next.copyWith(label: next.detailLabel);
    notifyListeners();
  }

  void syncFromOrders(List<OmsOrder> orders, String symbol) {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return;
    final working = orders
        .where((o) =>
            o.symbol.toUpperCase() == sym &&
            o.isWorking &&
            (o.orderType == 'LIMIT' ||
                o.orderType == 'STOP' ||
                o.orderType == 'TRAIL' ||
                o.orderType == 'SUPER'))
        .toList();

    var changed = false;
    final before = _lines.length;
    _lines.removeWhere((line) {
      if (line.symbol.toUpperCase() != sym) return false;
      if (line.orderId == null) return false;
      return !working.any((o) => o.orderId == line.orderId);
    });
    if (_lines.length != before) changed = true;

    for (final o in working) {
      if (_lines.any((l) => l.orderId == o.orderId)) continue;
      final price = _orderPrice(o);
      if (price <= 0) continue;
      final side = o.side == 'SELL'
          ? ChartTradeLineSide.sell
          : ChartTradeLineSide.buy;
      final draft = ChartTradeLine(
        id: 'tl${_seq++}',
        side: side,
        price: price,
        orderType: o.orderType,
        symbol: o.symbol.toUpperCase(),
        orderId: o.orderId,
        quantity: o.quantity,
      );
      _lines.add(draft.copyWith(label: draft.detailLabel));
      changed = true;
    }
    if (changed) notifyListeners();
  }

  double _orderPrice(OmsOrder o) {
    final trigger = double.tryParse(o.triggerPrice ?? '') ?? 0;
    if (trigger > 0) return trigger;
    return o.limitPriceAsDouble;
  }

  Future<void> removeLine(String id) async {
    final idx = _lines.indexWhere((l) => l.id == id);
    if (idx < 0) return;
    final line = _lines.removeAt(idx);
    notifyListeners();
    if (_config.cancelOrderOnLineDelete &&
        line.orderId != null &&
        line.orderId!.isNotEmpty) {
      await cancelOrder(line.orderId!);
    }
  }
}
