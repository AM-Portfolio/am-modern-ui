import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/paper_market_client.dart';
import '../../../data/quote_models.dart';
import '../../paper_oms_cubit.dart';

class OrderTicketController extends ChangeNotifier {
  static const _favoritePrefKey = 'paper_order_type_favorite';

  final _client = PaperMarketClient();
  final qty = TextEditingController(text: '1');
  final limit = TextEditingController();
  final target = TextEditingController();
  final stop = TextEditingController();
  final trail = TextEditingController(text: '5');
  final trigger = TextEditingController();

  String side = 'BUY';
  String orderType = 'MARKET';
  String entryType = 'LIMIT';
  String productMode = 'Investing';
  String exchange = 'NSE';
  bool useLimit = true;
  bool useTarget = true;
  bool useStop = true;
  bool showTrigger = false;
  bool bookProfitsOpen = true;
  bool quoteLoading = false;
  bool localSubmitting = false;
  QuoteDetail? quote;
  String displayName = '';

  ValueChanged<String>? onSideChanged;
  VoidCallback? onOrderPlaced;

  String _lastSyncedSymbol = '';
  bool _disposed = false;
  bool _favoriteLoaded = false;

  String get ctaLabel {
    final isBuy = side == 'BUY';
    if (orderType == 'MARKET') {
      return isBuy ? 'Buy at market' : 'Sell at market';
    }
    return isBuy ? 'Place buy' : 'Place sell';
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void init({required bool compact, required String side, required String symbol}) {
    _lastSyncedSymbol = symbol.trim().toUpperCase();
    this.side = side.toUpperCase() == 'SELL' ? 'SELL' : 'BUY';
    displayName = symbol;
    bookProfitsOpen = !compact;
    orderType = 'MARKET';
    if (compact) {
      useLimit = false;
      entryType = 'MARKET';
    }
    if (symbol.trim().isNotEmpty) {
      loadQuote(symbol);
    }
  }

  Future<void> loadFavorite(BuildContext context) async {
    if (_favoriteLoaded || _disposed) return;
    _favoriteLoaded = true;
    var fav = 'MARKET';
    try {
      final local = await SharedPreferences.getInstance();
      fav = (local.getString(_favoritePrefKey) ?? fav).toUpperCase();
    } catch (_) {}
    if (!context.mounted || _disposed) return;
    try {
      final remote = context.read<PaperOmsCubit>().state.orderTypeFavorite.trim().toUpperCase();
      if (remote.isNotEmpty) fav = remote;
    } catch (_) {}
    if (_disposed) return;
    orderType = fav;
    if (orderType == 'SUPER') {
      useLimit = true;
      entryType = 'LIMIT';
    } else if (orderType == 'MARKET') {
      useLimit = false;
      entryType = 'MARKET';
    }
    notifyListeners();
  }

  void syncFromWidget({required String symbol, required String side}) {
    final sym = symbol.trim().toUpperCase();
    if (sym.isNotEmpty && sym != _lastSyncedSymbol) {
      _lastSyncedSymbol = sym;
      loadQuote(symbol);
    }
    final next = side.toUpperCase() == 'SELL' ? 'SELL' : 'BUY';
    if (next != this.side) {
      this.side = next;
      notifyListeners();
    }
  }

  void disposeControllers() {
    qty.dispose();
    limit.dispose();
    target.dispose();
    stop.dispose();
    trail.dispose();
    trigger.dispose();
  }

  Future<void> loadQuote(String symbol) async {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return;
    quoteLoading = true;
    displayName = sym;
    notifyListeners();
    final detail = await _client.fetchQuoteDetail(
      sym,
      name: displayName,
      exchange: exchange,
      forceRefresh: false,
    );
    if (_disposed) return;
    quote = detail;
    quoteLoading = false;
    if (detail?.name != null && detail!.name!.isNotEmpty) {
      displayName = detail.name!;
    }
    final ex = (detail?.exchange ?? 'NSE').toUpperCase();
    exchange = ex == 'BSE' ? 'BSE' : 'NSE';
    seedPricesFromLtp(force: true);
    notifyListeners();
  }

  void seedPricesFromLtp({required bool force}) {
    final ltp = quote?.ltp ?? 0;
    if (ltp <= 0) return;
    final fmt = ltp.toStringAsFixed(2);
    if (force || limit.text.trim().isEmpty) limit.text = fmt;
    if (force || target.text.trim().isEmpty) {
      target.text = (ltp * 1.025).toStringAsFixed(2);
    }
    if (force || stop.text.trim().isEmpty) {
      stop.text = (ltp * 0.975).toStringAsFixed(2);
    }
  }

  void setSide(String nextSide) {
    side = nextSide;
    onSideChanged?.call(nextSide);
    notifyListeners();
  }

  void setOrderType(String type, {BuildContext? context}) {
    orderType = type;
    if (type == 'SUPER') {
      useLimit = true;
      entryType = 'LIMIT';
      seedPricesFromLtp(force: false);
    } else if (type == 'LIMIT') {
      seedPricesFromLtp(force: false);
    } else if (type == 'MARKET') {
      useLimit = false;
      entryType = 'MARKET';
    }
    notifyListeners();
    unawaited(_persistFavorite(type, context: context));
  }

  Future<void> _persistFavorite(String type, {BuildContext? context}) async {
    try {
      final local = await SharedPreferences.getInstance();
      await local.setString(_favoritePrefKey, type);
    } catch (_) {}
    if (context == null || !context.mounted) return;
    try {
      await context.read<PaperOmsCubit>().saveOrderTypeFavorite(type);
    } catch (_) {}
  }

  void bump(TextEditingController c, double delta) {
    final cur = double.tryParse(c.text.trim()) ?? 0;
    c.text = (cur + delta).clamp(0.0, 1e9).toStringAsFixed(2);
    notifyListeners();
  }

  void bumpQty(int delta) {
    final cur = int.tryParse(qty.text.trim()) ?? 1;
    qty.text = '${(cur + delta).clamp(1, 1000000)}';
    notifyListeners();
  }

  void setExchange(String ex) {
    exchange = ex;
    notifyListeners();
  }

  void setProductMode(String mode) {
    productMode = mode;
    notifyListeners();
  }

  void setUseLimit(bool v) {
    useLimit = v;
    entryType = v ? 'LIMIT' : 'MARKET';
    notifyListeners();
  }

  void setUseTarget(bool v) {
    useTarget = v;
    notifyListeners();
  }

  void setUseStop(bool v) {
    useStop = v;
    notifyListeners();
  }

  void toggleShowTrigger() {
    showTrigger = !showTrigger;
    notifyListeners();
  }

  void setShowTrigger(bool v) {
    showTrigger = v;
    notifyListeners();
  }

  void toggleBookProfitsOpen() {
    bookProfitsOpen = !bookProfitsOpen;
    notifyListeners();
  }

  Future<void> submit(BuildContext context, {required String symbol}) async {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty || qty.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a symbol and enter quantity')),
      );
      return;
    }
    if (localSubmitting) return;

    localSubmitting = true;
    notifyListeners();
    try {
      var ltp = quote?.ltp ?? 0;
      if (ltp <= 0) {
        ltp = await _client.fetchLiveLtp(sym, forceRefresh: false);
        if (!context.mounted) return;
        if (ltp > 0) {
          quote = QuoteDetail(
            symbol: sym,
            name: displayName,
            exchange: quote?.exchange ?? 'NSE',
            ltp: ltp,
            change: quote?.change ?? 0,
            changePercent: quote?.changePercent ?? 0,
            open: quote?.open,
            high: quote?.high,
            low: quote?.low,
            previousClose: quote?.previousClose,
            volume: quote?.volume,
            buyDepth: quote?.buyDepth ?? const [],
            sellDepth: quote?.sellDepth ?? const [],
          );
          notifyListeners();
        }
      }
      if (ltp <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live quote unavailable — try again')),
        );
        return;
      }

      final needsLimit = orderType == 'LIMIT' ||
          (orderType == 'SUPER' && useLimit && entryType == 'LIMIT');
      String? targetPrice;
      String? stopLoss;
      if (orderType == 'SUPER') {
        if (useTarget && target.text.trim().isNotEmpty) {
          targetPrice = target.text.trim();
        }
        if (useStop && stop.text.trim().isNotEmpty) {
          stopLoss = stop.text.trim();
        }
        if (targetPrice == null && stopLoss == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enable Target and/or Stop Loss for SUPER'),
            ),
          );
          return;
        }
      }

      final order = await context.read<PaperOmsCubit>().placeOrder(
            symbol: sym,
            side: side,
            orderType: orderType,
            quantity: qty.text.trim(),
            limitPrice: needsLimit ? limit.text.trim() : null,
            targetPrice: targetPrice,
            stopLoss: stopLoss,
            trailJump: orderType == 'TRAIL' ? trail.text.trim() : null,
            entryType: orderType == 'SUPER' ? (useLimit ? 'LIMIT' : 'MARKET') : null,
            triggerPrice: showTrigger && trigger.text.trim().isNotEmpty
                ? trigger.text.trim()
                : null,
          );
      if (order != null && !order.isRejected) {
        onOrderPlaced?.call();
      }
    } finally {
      localSubmitting = false;
      notifyListeners();
    }
  }
}
