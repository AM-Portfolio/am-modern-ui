import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../../../data/paper_market_client.dart';
import '../../../data/quote_models.dart';
import '../../paper_oms_cubit.dart';

class OrderTicketController extends ChangeNotifier {
  final _client = PaperMarketClient();
  final qty = TextEditingController(text: '1');
  final limit = TextEditingController();
  final target = TextEditingController();
  final stop = TextEditingController();
  final trail = TextEditingController(text: '5');
  final trigger = TextEditingController();

  String side = 'BUY';
  String orderType = 'SUPER';
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
    if (compact) {
      orderType = 'MARKET';
      useLimit = false;
      entryType = 'MARKET';
    }
    if (symbol.trim().isNotEmpty) {
      loadQuote(symbol);
    }
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
      notifyListeners(); // prop sync — do not call onSideChanged
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
    // #region agent log
    http
        .post(
          Uri.parse(
            'http://127.0.0.1:7626/ingest/0d1c8c7b-9f69-4195-beee-fbf3af51620e',
          ),
          headers: {
            'Content-Type': 'application/json',
            'X-Debug-Session-Id': 'c7037f',
          },
          body: jsonEncode({
            'sessionId': 'c7037f',
            'runId': 'post-fix',
            'hypothesisId': 'A',
            'location': 'paper_order_ticket.dart:_loadQuote',
            'message': 'ticket loadQuote with forceRefresh=false (cache)',
            'data': {'symbol': sym},
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }),
        )
        .catchError((_) => http.Response('', 599));
    // #endregion
    quoteLoading = true;
    displayName = sym;
    notifyListeners();
    final detail = await _client.fetchQuoteDetail(
      sym,
      name: displayName,
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

  void setOrderType(String type) {
    orderType = type;
    if (type == 'SUPER') {
      useLimit = true;
      entryType = 'LIMIT';
      seedPricesFromLtp(force: false);
    } else if (type == 'LIMIT') {
      seedPricesFromLtp(force: false);
    }
    notifyListeners();
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
