import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rxdart/rxdart.dart';
import 'package:am_common/core/config/app_config.dart';
import 'package:am_common/core/models/price_update_model.dart';
import 'package:am_common/am_common.dart';
import 'package:am_common/core/network/websocket/am_websocket_client.dart';
import 'package:http/http.dart' as http;

/// Singleton service to manage global WebSocket connection for real-time prices.
class PriceService {
  final AppConfig _config;
  final AMWebSocketClient _wsClient;
  
  StreamSubscription? _subscription;
  
  // Cache of latest prices: Symbol -> QuoteChange
  final Map<String, QuoteChange> _priceCache = {};
  
  // Subject to broadcast full price map updates
  final BehaviorSubject<Map<String, QuoteChange>> _pricesSubject = 
      BehaviorSubject<Map<String, QuoteChange>>.seeded({});

  // Subject to broadcast individual updates (for logs/feed)
  final PublishSubject<MarketDataUpdate> _updatesSubject = PublishSubject<MarketDataUpdate>();

  PriceService(this._config) : _wsClient = AMWebSocketClient() {
    // Configure socket
    final wsUrl = _config.api.marketData?.wsUrl;
    if (wsUrl != null && wsUrl.isNotEmpty) {
      _wsClient.configure(url: wsUrl);
    }
  }

  /// Get stream of all price updates (full map)
  Stream<Map<String, QuoteChange>> get priceStream => _pricesSubject.stream;

  /// Get stream of individual update events
  Stream<MarketDataUpdate> get updateStream => _updatesSubject.stream;
  
  /// Get current connection status stream
  Stream<bool> get isConnectedStream => _wsClient.status.map((s) => s == SocketStatus.connected);

  /// Get latest quote for a specific symbol
  QuoteChange? getQuote(String symbol) => _priceCache[symbol];
  
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
     _wsClient.connect();
     
     _subscription ??= _wsClient.messages.listen(_onMessage);
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
           'expandIndices': false, 
           'isIndexSymbol': true 
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
        // Log sample of message (debug level)
        // final preview = message.length > 50 ? "${message.substring(0, 50)}..." : message;
        // AppLogger.debug('PriceService: Received: $preview');

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
            _pricesSubject.add(Map.from(_priceCache));
          }
        }
      }
    } catch (e) {
      AppLogger.error('PriceService: Error parsing message', error: e);
    }
  }

  void disconnect() {
    _wsClient.disconnect();
    _subscription?.cancel();
    _subscription = null;
    _pricesSubject.close();
    _updatesSubject.close();
  }
}

