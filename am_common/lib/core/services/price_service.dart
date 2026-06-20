import 'dart:async';
import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:am_common/core/models/equity_price_mapper.dart';
import 'package:am_common/core/models/price_update_model.dart';
import 'package:am_common/am_common.dart';
import 'package:am_library/core/network/websocket/am_stomp_client.dart';

/// Real-time prices via am-gateway STOMP only:
/// - `/app/market/subscribe` → gateway proxies am-market upstream connect
/// - `/topic/stock/{symbol}` → live price relay from Kafka
class PriceService {
  PriceService({AmStompClient? stompClient})
      : _stompClient = stompClient ??
            (GetIt.instance.isRegistered<AmStompClient>()
                ? GetIt.instance<AmStompClient>()
                : null);

  final AmStompClient? _stompClient;

  StreamSubscription<StompFrame>? _messageSub;
  StreamSubscription<StompStatus>? _statusSub;

  final Set<String> _subscribedSymbols = {};
  final Set<String> _upstreamSymbols = {};
  final Set<String> _pendingGatewaySymbols = {};
  Timer? _gatewayConnectDebounce;
  DateTime? _lastTopicResubscribe;

  static const Duration _gatewayConnectDebounceDelay = Duration(milliseconds: 500);
  static const Duration _topicResubscribeCooldown = Duration(seconds: 3);

  final Map<String, QuoteChange> _priceCache = {};

  final BehaviorSubject<Map<String, QuoteChange>> _pricesSubject =
      BehaviorSubject<Map<String, QuoteChange>>.seeded({});

  final PublishSubject<MarketDataUpdate> _updatesSubject =
      PublishSubject<MarketDataUpdate>();

  Stream<Map<String, QuoteChange>> get priceStream => _pricesSubject.stream;

  Stream<MarketDataUpdate> get updateStream => _updatesSubject.stream;

  Stream<bool> get isConnectedStream {
    final client = _stompClient;
    if (client == null) return Stream.value(false);
    return client.status.map((s) => s == StompStatus.connected);
  }

  Set<String> get subscribedSymbols => Set.unmodifiable(_subscribedSymbols);

  QuoteChange? getQuote(String symbol) => _priceCache[symbol];

  double? getPrice(String symbol) => _priceCache[symbol]?.lastPrice;

  Map<String, QuoteChange> getQuotes(List<String> symbols) {
    final result = <String, QuoteChange>{};
    for (final symbol in symbols) {
      final quote = _priceCache[symbol];
      if (quote != null) {
        result[symbol] = quote;
      }
    }
    return result;
  }

  /// Attach STOMP listeners. Connection is owned by [StompConnectionCubit] / AppShell.
  void connect() {
    final client = _stompClient;
    if (client == null) {
      AppLogger.warning('PriceService: AmStompClient not registered.');
      return;
    }

    if (_messageSub != null) return;

    _messageSub = client.messages.listen(_onStompFrame);
    _statusSub = client.status.listen((status) {
      if (status == StompStatus.connected) {
        _resubscribeStompTopics();
      }
    });
  }

  /// Register upstream + STOMP topics for [symbols]. Batches gateway connect calls.
  /// Never removes existing subscriptions — use [unsubscribe] explicitly.
  Future<void> subscribe(
    List<String> symbols, {
    String provider = 'UPSTOX',
    bool isIndexSymbol = false,
    bool mockMode = false,
  }) async {
    if (symbols.isEmpty) return;

    final newSymbols = <String>[];
    for (final symbol in symbols) {
      if (_subscribedSymbols.add(symbol)) {
        newSymbols.add(symbol);
      }
    }
    if (newSymbols.isEmpty) return;

    _queueGatewayConnect(
      newSymbols,
      provider: provider,
      isIndexSymbol: isIndexSymbol,
      mockMode: mockMode,
    );
    _stompSubscribe(newSymbols);
  }

  Future<void> unsubscribe(List<String> symbols) async {
    final client = _stompClient;
    for (final symbol in symbols) {
      if (_subscribedSymbols.remove(symbol)) {
        client?.unsubscribe(stockTopicDestination(symbol));
      }
      _upstreamSymbols.remove(symbol);
      _pendingGatewaySymbols.remove(symbol);
    }
  }

  void _queueGatewayConnect(
    List<String> symbols, {
    required String provider,
    required bool isIndexSymbol,
    required bool mockMode,
  }) {
    for (final symbol in symbols) {
      if (!_upstreamSymbols.contains(symbol)) {
        _pendingGatewaySymbols.add(symbol);
      }
    }
    if (_pendingGatewaySymbols.isEmpty) return;

    _gatewayConnectDebounce?.cancel();
    _gatewayConnectDebounce = Timer(_gatewayConnectDebounceDelay, () {
      _flushGatewayConnect(
        provider: provider,
        isIndexSymbol: isIndexSymbol,
        mockMode: mockMode,
      );
    });
  }

  void _flushGatewayConnect({
    required String provider,
    required bool isIndexSymbol,
    required bool mockMode,
  }) {
    final batch = _pendingGatewaySymbols.toList();
    _pendingGatewaySymbols.clear();
    if (batch.isEmpty) return;

    _gatewayConnect(
      batch,
      provider: provider,
      isIndexSymbol: isIndexSymbol,
      mockMode: mockMode,
    );
    _upstreamSymbols.addAll(batch);
  }

  void _gatewayConnect(
    List<String> symbols, {
    required String provider,
    required bool isIndexSymbol,
    required bool mockMode,
  }) {
    final client = _stompClient;
    if (client == null) {
      AppLogger.warning('PriceService: Cannot send market subscribe — no AmStompClient.');
      return;
    }

    final body = jsonEncode({
      'instrumentKeys': symbols,
      'provider': mockMode ? 'MOCK' : provider,
      'timeFrame': '1D',
      'stream': true,
      'expandIndices': false,
      'isIndexSymbol': isIndexSymbol,
      if (mockMode) 'mockMode': true,
    });

    AppLogger.info(
      'PriceService: STOMP /app/market/subscribe batch=${symbols.length} '
      '(isIndexSymbol: $isIndexSymbol, provider: ${mockMode ? 'MOCK' : provider})',
    );

    client.send(
      destination: '/app/market/subscribe',
      headers: {'content-type': 'application/json'},
      body: body,
    );
  }

  void _stompSubscribe(List<String> symbols) {
    final client = _stompClient;
    if (client == null) {
      AppLogger.warning('PriceService: Cannot STOMP subscribe — no AmStompClient.');
      return;
    }

    for (final symbol in symbols) {
      client.subscribe(stockTopicDestination(symbol));
    }
  }

  void _resubscribeStompTopics() {
    final client = _stompClient;
    if (client == null || _subscribedSymbols.isEmpty) return;

    final now = DateTime.now();
    if (_lastTopicResubscribe != null &&
        now.difference(_lastTopicResubscribe!) < _topicResubscribeCooldown) {
      return;
    }
    _lastTopicResubscribe = now;

    AppLogger.info(
      'PriceService: Resubscribing ${_subscribedSymbols.length} stock topics after STOMP reconnect',
    );

    for (final symbol in _subscribedSymbols) {
      client.subscribe(stockTopicDestination(symbol));
    }
  }

  void _onStompFrame(StompFrame frame) {
    final body = frame.body;
    if (body == null || body.isEmpty) return;

    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final symbol = json['symbol'] as String?;
      if (symbol == null || symbol.isEmpty) return;

      _applyQuote(symbol, quoteChangeFromEquityPriceJson(json));
    } catch (e) {
      AppLogger.error('PriceService: Error parsing STOMP frame', error: e);
    }
  }

  void _applyQuote(String symbol, QuoteChange quote) {
    _priceCache[symbol] = quote;
    _updatesSubject.add(MarketDataUpdate(quotes: {symbol: quote}));
    _pricesSubject.add(Map.from(_priceCache));
  }

  /// Stop listening; keeps STOMP topic subscriptions on the shared client.
  void detach() {
    _gatewayConnectDebounce?.cancel();
    _gatewayConnectDebounce = null;

    _messageSub?.cancel();
    _messageSub = null;
    _statusSub?.cancel();
    _statusSub = null;
  }

  /// Full teardown (logout / app shutdown): detach + unsubscribe all topics.
  void disconnect() {
    detach();
    _pendingGatewaySymbols.clear();
    _upstreamSymbols.clear();

    final client = _stompClient;
    for (final symbol in _subscribedSymbols.toList()) {
      client?.unsubscribe(stockTopicDestination(symbol));
    }
    _subscribedSymbols.clear();

    if (!_pricesSubject.isClosed) {
      _pricesSubject.close();
    }
    if (!_updatesSubject.isClosed) {
      _updatesSubject.close();
    }
  }
}
