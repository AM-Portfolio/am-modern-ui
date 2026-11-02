import 'dart:async';
import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:am_common/core/models/equity_price_mapper.dart';
import 'package:am_common/core/models/price_update_model.dart';
import 'package:am_common/core/debug/agent_debug_log.dart';
import 'package:am_common/am_common.dart';
import 'package:am_library/core/network/websocket/am_stomp_client.dart';

/// A normalized live-market interest owned by one UI surface.
class MarketStreamInstrument {
  const MarketStreamInstrument({
    required this.symbol,
    required this.isIndexSymbol,
  });

  final String symbol;
  final bool isIndexSymbol;
}

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
  final Map<String, Map<String, MarketStreamInstrument>> _scopes = {};
  final Map<String, MarketStreamInstrument> _activeInstruments = {};
  final Set<String> _upstreamSymbols = {};
  final Map<String, MarketStreamInstrument> _pendingGatewaySymbols = {};
  Timer? _gatewayConnectDebounce;
  DateTime? _lastTopicResubscribe;
  bool _streamingAllowed = true;
  final Map<String, DateTime> _lastQuoteTimes = {};
  final Map<String, DateTime> _topicSubscribeSentAt = {};

  static const Duration _gatewayConnectDebounceDelay =
      Duration(milliseconds: 50);
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

  Map<String, Set<String>> get activeScopes => {
        for (final entry in _scopes.entries)
          entry.key: Set.unmodifiable(entry.value.keys.toSet()),
      };

  bool get isStreamingAllowed => _streamingAllowed;

  /// When false, drop live topics and skip gateway connect; desired symbols kept.
  void setStreamingAllowed(bool allowed) {
    if (_streamingAllowed == allowed) return;
    _streamingAllowed = allowed;
    if (!allowed) {
      _pauseActiveSubscriptions();
      return;
    }
    if (_subscribedSymbols.isNotEmpty) {
      unawaited(_replayActiveScopes());
    }
  }

  void _pauseActiveSubscriptions() {
    _gatewayConnectDebounce?.cancel();
    _gatewayConnectDebounce = null;
    _pendingGatewaySymbols.clear();
    _upstreamSymbols.clear();

    final client = _stompClient;
    for (final symbol in _subscribedSymbols) {
      client?.unsubscribe(stockTopicDestination(symbol));
    }
    AppLogger.info(
      'PriceService: streaming paused (${_subscribedSymbols.length} symbols retained)',
    );
  }

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
  /// When [forceResubscribe] is true, re-binds STOMP topics and re-sends gateway connect.
  Future<void> subscribe(
    List<String> symbols, {
    String provider = 'UPSTOX',
    bool isIndexSymbol = false,
    bool mockMode = false,
    bool forceResubscribe = false,
  }) async {
    if (symbols.isEmpty) return;

    final newSymbols = <String>[];
    for (final symbol in symbols) {
      if (forceResubscribe || _subscribedSymbols.add(symbol)) {
        newSymbols.add(symbol);
      }
    }

    if (!_streamingAllowed) {
      for (final symbol in symbols) {
        _subscribedSymbols.add(symbol);
      }
      AppLogger.info(
        'PriceService: subscribe deferred — market streaming closed '
        '(${symbols.length} symbols remembered)',
      );
      // #region agent log
      agentDebugLog(
        location: 'price_service.dart:subscribe',
        message: 'subscribe deferred because gate closed',
        hypothesisId: 'H4',
        data: {
          'symbolCount': symbols.length,
          'streamingAllowed': _streamingAllowed,
        },
      );
      // #endregion
      return;
    }

    if (forceResubscribe) {
      for (final symbol in symbols) {
        _subscribedSymbols.add(symbol);
      }
      _stompSubscribe(symbols, forceResubscribe: true);
      _queueGatewayConnect(
        symbols,
        provider: provider,
        isIndexSymbol: isIndexSymbol,
        mockMode: mockMode,
        force: true,
      );
      return;
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

  /// Replaces one owner's complete desired set and applies only the effective
  /// union across all owners. This is visibility-aware and safe for kept-alive
  /// pages: inactive pages can retain their cached intent without streaming.
  Future<void> replaceScope(
    String owner,
    Iterable<MarketStreamInstrument> instruments,
  ) async {
    final next = <String, MarketStreamInstrument>{};
    for (final instrument in instruments) {
      final symbol = instrument.symbol.trim().toUpperCase();
      if (symbol.isEmpty) continue;
      next[symbol] = MarketStreamInstrument(
        symbol: symbol,
        isIndexSymbol: instrument.isIndexSymbol,
      );
    }

    _scopes[owner] = next;
    final effective = <String, MarketStreamInstrument>{};
    for (final scope in _scopes.values) {
      effective.addAll(scope);
    }

    final previous = Set<String>.from(_subscribedSymbols);
    final current = effective.keys.toSet();
    final removed = previous.difference(current).toSet();
    final added = current.difference(previous).toSet();
    for (final symbol in previous.intersection(current)) {
      if (_activeInstruments[symbol]?.isIndexSymbol !=
          effective[symbol]?.isIndexSymbol) {
        removed.add(symbol);
        added.add(symbol);
      }
    }

    for (final symbol in removed) {
      _stompClient?.unsubscribe(stockTopicDestination(symbol));
      _upstreamSymbols.remove(symbol);
      _pendingGatewaySymbols.remove(symbol);
      _activeInstruments.remove(symbol);
      _topicSubscribeSentAt.remove(symbol.toUpperCase());
    }

    _subscribedSymbols
      ..clear()
      ..addAll(current);
    _activeInstruments
      ..clear()
      ..addAll(effective);

    if (!_streamingAllowed || added.isEmpty) return;

    final addedInstruments = added.map((symbol) => effective[symbol]!).toList();
    _stompSubscribe(addedInstruments.map((e) => e.symbol).toList());
    for (final group in <bool>[true, false]) {
      final batch = addedInstruments
          .where((instrument) => instrument.isIndexSymbol == group)
          .map((instrument) => instrument.symbol)
          .toList();
      if (batch.isNotEmpty) {
        _queueGatewayConnect(
          batch,
          provider: 'UPSTOX',
          isIndexSymbol: group,
          mockMode: false,
        );
      }
    }
  }

  Future<void> releaseScope(String owner) async {
    if (!_scopes.containsKey(owner)) return;
    _scopes.remove(owner);
    final effective = <MarketStreamInstrument>[];
    for (final scope in _scopes.values) {
      effective.addAll(scope.values);
    }
    await replaceScope('__effective__', effective);
    _scopes.remove('__effective__');
  }

  /// Re-bind all active symbol topics and re-send gateway connect (e.g. after tab return).
  Future<void> resubscribeAll({
    bool isIndexSymbol = false,
    bool mockMode = false,
  }) async {
    if (_scopes.isNotEmpty) {
      await _replayActiveScopes();
      return;
    }
    if (_subscribedSymbols.isEmpty) return;
    await subscribe(
      _subscribedSymbols.toList(),
      isIndexSymbol: isIndexSymbol,
      mockMode: mockMode,
      forceResubscribe: true,
    );
  }

  Future<void> _replayActiveScopes() async {
    if (!_streamingAllowed || _activeInstruments.isEmpty) return;
    final instruments = _activeInstruments.values.toList();
    _stompSubscribe(instruments.map((e) => e.symbol).toList(),
        forceResubscribe: true);
    for (final group in <bool>[true, false]) {
      final batch = instruments
          .where((instrument) => instrument.isIndexSymbol == group)
          .map((instrument) => instrument.symbol)
          .toList();
      if (batch.isEmpty) continue;
      _queueGatewayConnect(
        batch,
        provider: 'UPSTOX',
        isIndexSymbol: group,
        mockMode: false,
        force: true,
      );
    }
  }

  Future<void> unsubscribe(List<String> symbols) async {
    final client = _stompClient;
    for (final symbol in symbols) {
      if (_subscribedSymbols.remove(symbol)) {
        client?.unsubscribe(stockTopicDestination(symbol));
      }
      _upstreamSymbols.remove(symbol);
      _pendingGatewaySymbols.remove(symbol);
      _topicSubscribeSentAt.remove(symbol.toUpperCase());
    }
  }

  void _queueGatewayConnect(
    List<String> symbols, {
    required String provider,
    required bool isIndexSymbol,
    required bool mockMode,
    bool force = false,
  }) {
    for (final symbol in symbols) {
      if (force || !_upstreamSymbols.contains(symbol)) {
        _pendingGatewaySymbols[symbol] = MarketStreamInstrument(
          symbol: symbol,
          isIndexSymbol: isIndexSymbol,
        );
      }
    }
    if (_pendingGatewaySymbols.isEmpty) return;

    _gatewayConnectDebounce?.cancel();
    _gatewayConnectDebounce = Timer(_gatewayConnectDebounceDelay, () {
      _flushGatewayConnect(
        provider: provider,
        mockMode: mockMode,
      );
    });
  }

  void _flushGatewayConnect({
    required String provider,
    required bool mockMode,
  }) {
    final pending = _pendingGatewaySymbols.values.toList();
    _pendingGatewaySymbols.clear();
    if (pending.isEmpty) return;

    for (final group in <bool>[true, false]) {
      final batch = pending
          .where((instrument) => instrument.isIndexSymbol == group)
          .map((instrument) => instrument.symbol)
          .toList();
      if (batch.isEmpty) continue;
      _gatewayConnect(
        batch,
        provider: provider,
        isIndexSymbol: group,
        mockMode: mockMode,
      );
      _upstreamSymbols.addAll(batch);
    }
  }

  void _gatewayConnect(
    List<String> symbols, {
    required String provider,
    required bool isIndexSymbol,
    required bool mockMode,
  }) {
    final client = _stompClient;
    if (client == null) {
      AppLogger.warning(
          'PriceService: Cannot send market subscribe — no AmStompClient.');
      return;
    }

    final body = jsonEncode({
      'instrumentKeys': symbols,
      'timeFrame': '1D',
      'stream': true,
      'expandIndices': false,
      'isIndexSymbol': isIndexSymbol,
      if (mockMode) ...{
        'provider': 'MOCK',
        'mockMode': true,
      },
    });

    AppLogger.info(
      'PriceService: STOMP /app/market/subscribe batch=${symbols.length} '
      '(isIndexSymbol: $isIndexSymbol, server-driven provider)',
    );
    AppLogger.info(
      'PriceService: gateway subscribe sent batch=${symbols.length} '
      'isIndexSymbol=$isIndexSymbol sentAt=${DateTime.now().toUtc().toIso8601String()}',
    );
    // #region agent log
    agentDebugLog(
      location: 'price_service.dart:_gatewayConnect',
      message: 'sending /app/market/subscribe',
      hypothesisId: 'H5',
      data: {
        'batch': symbols.length,
        'stompConnected': client.isConnected,
      },
    );
    // #endregion

    client.send(
      destination: '/app/market/subscribe',
      headers: {'content-type': 'application/json'},
      body: body,
    );
  }

  void _stompSubscribe(List<String> symbols, {bool forceResubscribe = false}) {
    final client = _stompClient;
    if (client == null) {
      AppLogger.warning(
          'PriceService: Cannot STOMP subscribe — no AmStompClient.');
      return;
    }

    for (final symbol in symbols) {
      _topicSubscribeSentAt[symbol.toUpperCase()] = DateTime.now().toUtc();
      client.subscribe(stockTopicDestination(symbol),
          forceResubscribe: forceResubscribe);
    }
  }

  void _resubscribeStompTopics() {
    final client = _stompClient;
    if (client == null || _subscribedSymbols.isEmpty) return;
    if (!_streamingAllowed) return;

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
      client.subscribe(stockTopicDestination(symbol), forceResubscribe: true);
    }

    if (_upstreamSymbols.isNotEmpty) {
      for (final group in <bool>[true, false]) {
        final batch = _upstreamSymbols
            .where(
                (symbol) => _activeInstruments[symbol]?.isIndexSymbol == group)
            .toList();
        if (batch.isEmpty) continue;
        _queueGatewayConnect(
          batch,
          provider: 'UPSTOX',
          isIndexSymbol: group,
          mockMode: false,
          force: true,
        );
      }
    }
  }

  void _onStompFrame(StompFrame frame) {
    final body = frame.body;
    if (body == null || body.isEmpty) return;

    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final symbol = json['symbol']?.toString().trim();
      if (symbol == null || symbol.isEmpty) return;

      final sentAt = _topicSubscribeSentAt.remove(symbol.toUpperCase());
      if (sentAt != null) {
        final latency =
            DateTime.now().toUtc().difference(sentAt).inMilliseconds;
        AppLogger.info(
          'PriceService: first tick latency symbol=$symbol latencyMs=$latency '
          'payloadTime=${json['time'] ?? json['timestamp']}',
        );
      }

      final destination = frame.headers['destination'];
      if (destination != null && destination.startsWith('/topic/stock/')) {
        final topicSymbol =
            destination.substring('/topic/stock/'.length).trim();
        if (topicSymbol != symbol) {
          AppLogger.warning(
            'PriceService: topic/payload symbol mismatch: topic=$topicSymbol payload=$symbol',
          );
        }
      }

      final quoteTime = _parseQuoteTime(json['time'] ?? json['timestamp']);
      final previousTime = _lastQuoteTimes[symbol];
      if (quoteTime != null &&
          previousTime != null &&
          quoteTime.isBefore(previousTime)) {
        AppLogger.warning(
          'PriceService: ignoring out-of-order quote for $symbol '
          '(incoming=$quoteTime cached=$previousTime)',
        );
        return;
      }
      if (quoteTime != null) _lastQuoteTimes[symbol] = quoteTime;

      // #region agent log
      agentDebugLog(
        location: 'price_service.dart:_onStompFrame',
        message: 'received stock frame',
        hypothesisId: 'H5',
        data: {
          'symbol': symbol,
          'destination': frame.headers['destination'],
        },
      );
      // #endregion
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
    _scopes.clear();
    _activeInstruments.clear();
    _upstreamSymbols.clear();
    _lastQuoteTimes.clear();
    _topicSubscribeSentAt.clear();

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

  DateTime? _parseQuoteTime(dynamic raw) {
    if (raw is num) {
      final value = raw.toInt();
      return DateTime.fromMillisecondsSinceEpoch(
        value < 100000000000 ? value * 1000 : value,
        isUtc: true,
      );
    }
    if (raw is String) return DateTime.tryParse(raw)?.toUtc();
    return null;
  }
}
