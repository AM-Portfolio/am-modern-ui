import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rxdart/rxdart.dart';
import 'package:am_common/core/config/app_config.dart';
import 'package:am_common/core/models/price_update_model.dart';
import 'package:am_common/core/utils/logger.dart';
import 'package:http/http.dart' as http;

/// Singleton service to manage global WebSocket connection for real-time prices.
class PriceService {
  final AppConfig _config;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  
  // Cache of latest prices: Symbol -> QuoteChange
  final Map<String, QuoteChange> _priceCache = {};
  
  // Subject to broadcast full price map updates
  final BehaviorSubject<Map<String, QuoteChange>> _pricesSubject = 
      BehaviorSubject<Map<String, QuoteChange>>.seeded({});

  // Subject to broadcast individual updates (for logs/feed)
  final PublishSubject<MarketDataUpdate> _updatesSubject = PublishSubject<MarketDataUpdate>();
      
  // Connection status subject
  final BehaviorSubject<bool> _isConnectedSubject = BehaviorSubject<bool>.seeded(false);

  PriceService(this._config);

  /// Get stream of all price updates (full map)
  Stream<Map<String, QuoteChange>> get priceStream => _pricesSubject.stream;

  /// Get stream of individual update events
  Stream<MarketDataUpdate> get updateStream => _updatesSubject.stream;
  
  /// Get current connection status stream
  Stream<bool> get isConnectedStream => _isConnectedSubject.stream;

  /// Get latest quote for a specific symbol
  QuoteChange? getQuote(String symbol) => _priceCache[symbol];
  
  /// Get latest price for a specific symbol (convenience)
  /// Get latest price for a specific symbol (convenience)
  double? getPrice(String symbol) => _priceCache[symbol]?.lastPrice;

  /// Get latest quotes for a list of symbols
  Map<String, QuoteChange> getQuotes(List<String> symbols) {
    final Map<String, QuoteChange> result = {};
    for (final symbol in symbols) {
      if (_priceCache.containsKey(symbol)) {
        result[symbol] = _priceCache[symbol]!;
      }
    }
    return result;
  }

  /// Connect to the WebSocket
  void connect() {
    final wsUrl = _config.api.marketData?.wsUrl;
    if (wsUrl == null || wsUrl.isEmpty) {
      AppLogger.warning('PriceService: No WS URL configured, skipping connection.');
      return;
    }

    if (_channel != null) {
      AppLogger.info('PriceService: Already connected or connecting.');
      return;
    }

    try {
      AppLogger.info('PriceService: WebSocket Connecting to $wsUrl ...');
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnectedSubject.add(true); 
      AppLogger.info('PriceService: WebSocket Channel created (optimistic)');

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
    } catch (e) {
      AppLogger.error('PriceService: Connection failed', error: e);
      _isConnectedSubject.add(false);
      _scheduleReconnect();
    }
  }

  /// Subscribe to symbols (initiates stream via REST)
  Future<void> subscribe(List<String> symbols, {String provider = 'UPSTOX'}) async {
    final baseUrl = _config.api.marketData?.baseUrl;
    final endpoint = _config.api.marketData?.connectEndpoint;
    
    if (baseUrl == null || endpoint == null) {
       AppLogger.warning('PriceService: Missing REST config for subscription.');
       return;
    }

    try {
       final url = Uri.parse('$baseUrl$endpoint');
       AppLogger.info('PriceService: Subscribing to $symbols via $url');
       
       final response = await http.post(
         url,
         headers: {'Content-Type': 'application/json'},
         body: jsonEncode({
           'instrumentKeys': symbols,
           'provider': provider,
           'timeFrame': '1D',
           'stream': true,
           'expandIndices': false, // Explicitly false as we are passing specific symbols
           'isIndexSymbol': true // Assuming mostly indices for now based on context, or pass as param
         }),
       );
       
       if (response.statusCode == 200) {
          AppLogger.info('PriceService: Subscription successful');
       } else {
          AppLogger.error('PriceService: Subscription failed ${response.statusCode}: ${response.body}');
       }
    } catch (e) {
       AppLogger.error('PriceService: Subscription failed', error: e);
    }
  }

  void _onMessage(dynamic message) {
    try {
      if (message is String) {
        // Log sample of message to verify data flow
        final preview = message.length > 50 ? "${message.substring(0, 50)}..." : message;
        AppLogger.debug('PriceService: Received message: $preview');

        final Map<String, dynamic> json = jsonDecode(message);
        final update = MarketDataUpdate.fromJson(json);
        
        // Broadcast the event
        _updatesSubject.add(update);
        
        if (update.quotes != null && update.quotes!.isNotEmpty) {
          bool cacheChanged = false;
          update.quotes!.forEach((symbol, quote) {
             _priceCache[symbol] = quote;
             cacheChanged = true;
          });
          
          if (cacheChanged) {
            // Emit a new map to trigger consumers
            _pricesSubject.add(Map.from(_priceCache));
          }
        }
      }
    } catch (e) {
      AppLogger.error('PriceService: Error parsing message', error: e);
    }
  }

  void _onError(dynamic error) {
    AppLogger.error('PriceService: WebSocket error', error: error);
    _isConnectedSubject.add(false);
    _scheduleReconnect();
  }

  void _onDone() {
    AppLogger.info('PriceService: WebSocket connection closed');
    _isConnectedSubject.add(false);
    _cleanup();
    _scheduleReconnect();
  }

  void _cleanup() {
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
  }

  void disconnect() {
    _cleanup();
    _pricesSubject.close();
    _isConnectedSubject.close();
    _updatesSubject.close();
  }

  void _scheduleReconnect() {
    // Basic reconnect strategy: wait 5 seconds and retry
    Timer(const Duration(seconds: 5), () {
      AppLogger.info('PriceService: Attempting reconnect...');
      connect();
    });
  }
}
