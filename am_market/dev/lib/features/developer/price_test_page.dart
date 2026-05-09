import 'package:am_auth_ui/core/services/secure_storage_service.dart';


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/services/api_service.dart';
import 'package:http/http.dart' as http;

class PriceTestPage extends StatefulWidget {
  const PriceTestPage({super.key});

  @override
  State<PriceTestPage> createState() => _PriceTestPageState();
}

class _PriceTestPageState extends State<PriceTestPage> {
  final _symbolController = TextEditingController(text: 'RELIANCE');
  final ApiService _apiService = ApiService();

  // Test State
  Map<String, dynamic>? _priceData;
  String _rawResponse = '';
  bool _isLoading = false;
  String _error = '';

  // Config
  String _provider = 'UPSTOX'; // Default
  bool _isIndex = false;
  bool _useLocal = false;
  final _portController = TextEditingController(text: '8080');

  Future<void> _fetchPrice() async {
    setState(() {
      _isLoading = true;
      _priceData = null;
      _rawResponse = '';
      _error = '';
    });

    try {
      final symbol = _symbolController.text.trim().toUpperCase();
      
      // Direct call to debug raw response
      // Use ApiService logic but maybe expose debug method or just copy minimal logic
      final token = await GetIt.I<SecureStorageService>().getAccessToken();
      final forceRefresh = context.read<MarketProvider>().forceRefresh;
      
      final baseUrl = _useLocal 
          ? 'http://localhost:${_portController.text.trim()}' 
          : ApiService.baseUrl;
          
      final response = await http.get(
        Uri.parse('$baseUrl/v1/market-data/quotes?symbols=$symbol&provider=$_provider&isIndex=$_isIndex&refresh=$forceRefresh'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      
      setState(() {
         _rawResponse = response.body; 
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // Check for quotes in both flat and wrapped structures
          Map<String, dynamic>? quotes;
          if (data is Map) {
            if (data.containsKey(symbol)) {
              // Flat structure (symbol is at top level)
              _priceData = Map<String, dynamic>.from(data[symbol] as Map);
              return;
            } else if (data.containsKey('quotes') && data['quotes'] is Map) {
              // Wrapped structure
              quotes = Map<String, dynamic>.from(data['quotes'] as Map);
            } else {
              // Assume the whole map might be quotes if it doesn't have metadata keys
              // or just use it as fallback
              quotes = Map<String, dynamic>.from(data);
            }
          }

          if (quotes != null && quotes.containsKey(symbol)) {
            _priceData = Map<String, dynamic>.from(quotes[symbol] as Map);
          } else if (quotes != null && quotes.isNotEmpty && !quotes.containsKey('count')) {
            // Fallback: show the first available quote (excluding metadata keys)
            final firstKey = quotes.keys.firstWhere((k) => k != 'count' && k != 'cached' && k != 'timestamp', orElse: () => '');
            if (firstKey.isNotEmpty) {
              _priceData = Map<String, dynamic>.from(quotes[firstKey] as Map);
            }
          }

          if (_priceData == null) {
            _error = 'No quote returned for $symbol. '
                'Check if the Upstox token is valid and the symbol format is correct.';
          }
        });
      } else {
        setState(() => _error = 'Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Price Fetch Test', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          iconTheme: theme.iconTheme,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               // Control Card
               Container(
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(
                   color: theme.cardColor,
                   borderRadius: BorderRadius.circular(16),
                   boxShadow: [
                     BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                   ]
                 ),
                 child: Column(
                   children: [
                     Row(
                       children: [
                         Expanded(
                           child: TextField(
                             controller: _symbolController,
                             style: theme.textTheme.bodyMedium,
                             decoration: InputDecoration(
                               labelText: 'Symbol', 
                               labelStyle: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                               enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.dividerColor)),
                             ),
                           ),
                         ),
                         const SizedBox(width: 16),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12),
                           decoration: BoxDecoration(
                             border: Border.all(color: theme.dividerColor),
                             borderRadius: BorderRadius.circular(8),
                           ),
                           child: DropdownButtonHideUnderline(
                             child: DropdownButton<String>(
                               value: _provider,
                               items: ['UPSTOX', 'ZERODHA'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                               onChanged: (v) => setState(() => _provider = v!),
                               style: theme.textTheme.bodyMedium,
                               dropdownColor: theme.cardColor,
                             ),
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 16),
                      Row(
                        children: [
                          Text("Is Index?", style: theme.textTheme.bodyMedium),
                          Switch(
                            value: _isIndex, 
                            onChanged: (v) => setState(() => _isIndex = v),
                            activeColor: theme.primaryColor,
                          ),
                          const SizedBox(width: 24),
                          Text("Local Host?", style: theme.textTheme.bodyMedium),
                          Switch(
                            value: _useLocal, 
                            onChanged: (v) => setState(() => _useLocal = v),
                            activeColor: Colors.orange,
                          ),
                          if (_useLocal) ...[
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: _portController,
                                decoration: const InputDecoration(labelText: 'Port', isDense: true),
                                keyboardType: TextInputType.number,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _fetchPrice,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text("Fetch Price"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: theme.colorScheme.onPrimary, 
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          )
                        ],
                      )
                   ],
                 ),
               ),
               
               const SizedBox(height: 24),
               
               if (_error.isNotEmpty)
                 Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     color: theme.colorScheme.error.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child: Text(_error, style: TextStyle(color: theme.colorScheme.error)),
                 ),
               
               if (_isLoading)
                 Center(child: Padding(padding: const EdgeInsets.all(20), child: CircularProgressIndicator(color: theme.primaryColor))),
                  
               if (_priceData != null) ...[
                 Text("Parsed Data", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                 const SizedBox(height: 10),
                 _buildDataCard(context, _priceData!),
               ],
               
               const SizedBox(height: 24),
               
               if (_rawResponse.isNotEmpty) ...[
                  Text("Raw Response", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark ? Colors.black : Colors.grey.shade900, 
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _formatJson(_rawResponse),
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.greenAccent),
                        ),
                      ),
                    ),
                  )
               ]
            ],
          ),
        ),
      );
  }

  Widget _buildDataCard(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(data['symbol'] ?? 'UNKNOWN', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
           Divider(color: theme.dividerColor),
           Wrap(
             spacing: 24,
             runSpacing: 16,
             children: [
               _kv(context, "LTP", "${data['lastPrice'] ?? data['ltp'] ?? data['last_price'] ?? '-'}"),
               _kv(
                 context,
                 "Change",
                 "${data['change'] ?? '-'}",
                 color: ((data['change'] as num?) ?? 0) >= 0 ? Colors.green : Colors.red,
               ),
               _kv(context, "Open", "${data['openPrice'] ?? data['open'] ?? '-'}"),
               _kv(context, "High", "${data['highPrice'] ?? data['high'] ?? '-'}"),
               _kv(context, "Low", "${data['lowPrice'] ?? data['low'] ?? '-'}"),
               _kv(context, "Close", "${data['closePrice'] ?? data['close'] ?? '-'}"),
               _kv(context, "Volume", "${data['volume'] ?? '-'}"),
             ],
           )
        ],
      )
    );
  }

  Widget _kv(BuildContext context, String k, String v, {Color? color}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
        Text(v, style: theme.textTheme.titleMedium?.copyWith(
          color: color ?? theme.textTheme.bodyLarge?.color, 
          fontWeight: FontWeight.bold,
        )),
      ],
    );
  }

  String _formatJson(String jsonStr) {
    try {
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(jsonDecode(jsonStr));
    } catch (e) {
      return jsonStr;
    }
  }
}
