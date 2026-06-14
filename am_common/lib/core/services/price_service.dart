import 'dart:async';
import 'dart:convert';
import 'package:rxdart/rxdart.dart';
import 'package:am_common/core/config/app_config.dart';
import 'package:am_common/core/models/price_update_model.dart';
import 'package:am_common/am_common.dart';
import 'package:am_common/core/network/websocket/am_websocket_client.dart';
import 'package:am_library/core/services/secure_storage_service.dart';
import 'package:http/http.dart' as http;

/// Singleton service to manage global WebSocket connection for real-time prices.
///
/// Flow:
///   1. [connect()] opens a persistent WebSocket to the backend at [MarketDataConfig.wsUrl].
///   2. [subscribe(symbols)] sends a REST POST to [MarketDataConfig.connectEndpoint] which
///      tells the backend to start streaming those symbols from Upstox via its own WebSocket.
///   3. Backend broadcasts [MarketDataUpdate] JSON frames to all connected WS clients.
///   4. [_onMessage] parses frames and emits to [priceStream] / [updateStream].
///   5. On WS reconnect, [subscribe] is automatically re-sent to restart the backend stream.
class PriceService {
  final AppConfig _config;
  final AMWebSocketClient _wsClient;

  StreamSubscription? _subscription;
  StreamSubscription? _statusSubscription;

  // ── Price cache ───────────────────────────────────────────────────────────
  final Map<String, QuoteChange> _priceCache = {};

  // ── Reactive streams ──────────────────────────────────────────────────────
  final BehaviorSubject<Map<String, QuoteChange>> _pricesSubject =
      BehaviorSubject<Map<String, QuoteChange>>.seeded({});

  final PublishSubject<MarketDataUpdate> _updatesSubject =
      PublishSubject<MarketDataUpdate>();

  // ── Subscription state (persisted for auto-resubscribe on reconnect) ──────
  List<String> _subscribedSymbols = [];
  String _subscribedProvider = 'UPSTOX';
  bool _subscribedIsIndex = false;
  bool _subscribedMockMode = false;

  PriceService(this._config) : _wsClient = AMWebSocketClient() {
    final wsUrl = _config.api.marketData?.wsUrl;
    if (wsUrl != null && wsUrl.isNotEmpty) {
      _wsClient.configure(url: wsUrl);
      AppLogger.info('PriceService: Configured WS URL: $wsUrl');
    } else {
      AppLogger.warning('PriceService: No WS URL configured in MarketDataConfig.');
    }

    // When the WS (re)connects, re-send the subscription request so the
    // backend restarts its Upstox stream for the tracked symbols.
    _statusSubscription = _wsClient.status.listen((status) {
      if (status == SocketStatus.connected && _subscribedSymbols.isNotEmpty) {
        AppLogger.info(
            'PriceService: WS (re)connected — re-subscribing ${_subscribedSymbols.length} symbols.');
        _sendSubscriptionRequest();
      }
    });
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Full price-map stream (Symbol → QuoteChange).
  Stream<Map<String, QuoteChange>> get priceStream => _pricesSubject.stream;

  /// Individual update-event stream.
  Stream<MarketDataUpdate> get updateStream => _updatesSubject.stream;

  /// True while the WebSocket is connected.
  Stream<bool> get isConnectedStream =>
      _wsClient.status.map((s) => s == SocketStatus.connected);

  /// Latest quote for a symbol.
  QuoteChange? getQuote(String symbol) => _priceCache[symbol];

  /// Latest price for a symbol (convenience).
  double? getPrice(String symbol) => _priceCache[symbol]?.lastPrice;

  /// Latest quotes for a list of symbols.
  Map<String, QuoteChange> getQuotes(List<String> symbols) {
    final result = <String, QuoteChange>{};
    for (final s in symbols) {
      if (_priceCache.containsKey(s)) result[s] = _priceCache[s]!;
    }
    return result;
  }

  /// Open the WebSocket connection and start listening for messages.
  void connect() {
    _wsClient.connect();
    // Guard: only attach listener once.
    _subscription ??= _wsClient.messages.listen(_onMessage);
  }

  /// Subscribe to [symbols] for real-time price updates.
  ///
  /// This:
  ///   1. Ensures the WebSocket is connected.
  ///   2. Sends a REST POST to the backend to start Upstox streaming for these symbols.
  ///   3. Stores params so they can be re-sent automatically on WS reconnect.
  Future<void> subscribe(
    List<String> symbols, {
    String provider = 'UPSTOX',
    bool isIndexSymbol = false,
    bool mockMode = false,
  }) async {
    _subscribedSymbols = symbols;
    _subscribedProvider = provider;
    _subscribedIsIndex = isIndexSymbol;
    _subscribedMockMode = mockMode;

    AppLogger.info(
        'PriceService: subscribe() called for ${symbols.length} symbols '
        '(isIndexSymbol: $isIndexSymbol, provider: ${mockMode ? 'MOCK' : provider})');

    // Ensure WS is open before sending the subscription REST call.
    if (!_wsClient.isConnected) {
      AppLogger.info('PriceService: WS not connected — connecting first and waiting.');
      connect();
      try {
        await _wsClient.status
            .firstWhere((s) => s == SocketStatus.connected)
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        AppLogger.warning('PriceService: WS connection timeout or error during subscribe.');
        // We still proceed with the REST call as the WS might connect shortly after.
      }
    }

    await _sendSubscriptionRequest();
    }

  // ── Internal ──────────────────────────────────────────────────────────────

  /// POST to the backend connect endpoint to start backend Upstox streaming.
  Future<void> _sendSubscriptionRequest() async {
    if (_subscribedSymbols.isEmpty) return;

    final baseUrl = _config.api.marketData?.baseUrl;
    final endpoint = _config.api.marketData?.connectEndpoint;

    if (baseUrl == null || endpoint == null) {
      AppLogger.warning('PriceService: Missing REST config — cannot subscribe.');
      return;
    }

    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final token = await SecureStorageService().getAccessToken();

      AppLogger.info(
          'PriceService: Sending subscription request → $url '
          '(${_subscribedSymbols.length} symbols, authPresent: ${token != null})');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'instrumentKeys': _subscribedSymbols,
              'provider': _subscribedMockMode ? 'MOCK' : _subscribedProvider,
              'timeFrame': '1D',
              'stream': true,
              'expandIndices': false,
              'isIndexSymbol': _subscribedIsIndex,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        AppLogger.info('PriceService: Subscription successful (200 OK)');
      } else {
        AppLogger.error(
            'PriceService: Subscription failed ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      AppLogger.error('PriceService: Subscription request error', error: e);
    }
  }

  void _onMessage(dynamic message) {
    try {
      if (message is String) {
        final Map<String, dynamic> json = jsonDecode(message);
        final update = MarketDataUpdate.fromJson(json);

        // Broadcast individual update event.
        _updatesSubject.add(update);

        // Update cache and emit full price map.
        if (update.quotes != null && update.quotes!.isNotEmpty) {
          bool cacheChanged = false;
          update.quotes!.forEach((symbol, quote) {
            final existing = _priceCache[symbol];
            if (existing != null) {
              final lastPrice = quote.lastPrice ?? existing.lastPrice;
              final previousClose = quote.previousClose ?? existing.previousClose;
              double? change = quote.change ?? existing.change;
              double? changePercent = quote.changePercent ?? existing.changePercent;
              
              if (lastPrice != null && previousClose != null && previousClose != 0) {
                change = lastPrice - previousClose;
                changePercent = (change / previousClose) * 100;
              }

              _priceCache[symbol] = QuoteChange(
                lastPrice: lastPrice,
                open: quote.open ?? existing.open,
                high: quote.high ?? existing.high,
                low: quote.low ?? existing.low,
                close: quote.close ?? existing.close,
                previousClose: previousClose,
                change: change,
                changePercent: changePercent,
              );
            } else {
              _priceCache[symbol] = quote;
            }
            cacheChanged = true;
          });
          if (cacheChanged) {
            _pricesSubject.add(Map.from(_priceCache));
          }
        }
      }
    } catch (e) {
      AppLogger.error('PriceService: Error parsing WS message', error: e);
    }
  }

  /// Disconnect WebSocket and clean up all resources.
  void disconnect() {
    _wsClient.disconnect();
    _subscription?.cancel();
    _subscription = null;
    _statusSubscription?.cancel();
    _statusSubscription = null;
    _subscribedSymbols = [];
    AppLogger.info('PriceService: Disconnected.');
  }
}
