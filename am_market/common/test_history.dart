import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final requestBody = {
    'symbols': 'NIFTY 50,NIFTY 500',
    'from': '2025-06-05',
    'to': '2026-06-05',
    'interval': '1d',
    'forceRefresh': false,
    'isIndexSymbol': true,
    'instrumentType': 'STOCK',
    'continuous': false,
  };

  final response = await http.post(
    Uri.parse('https://am-dev.asrax.in/market/v1/historical/batch'),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: json.encode(requestBody),
  );

  print('Status: ${response.statusCode}');
  if (response.statusCode == 200) {
    final decoded = json.decode(response.body);
    if (decoded is Map && decoded.containsKey('data')) {
      final data = decoded['data'] as Map;
      print('Keys in data: ${data.keys.toList()}');
      for (var key in data.keys) {
         final points = data[key]['dataPoints'] as List?;
         print('Symbol: $key, points count: ${points?.length}');
         if (points != null && points.isNotEmpty) {
           print('First point for $key: ${points.first}');
         }
      }
    } else {
      print('No data key. Body: ${response.body}');
    }
  } else {
    print('Body: ${response.body}');
  }
}
