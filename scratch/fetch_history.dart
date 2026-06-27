import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  try {
    final uri = Uri.parse('https://am-dev.asrax.in/market/v1/analysis/historical-charts?symbols=NIFTY%2050,NIFTY%20BANK&range=1W');
    final request = await client.getUrl(uri);
    request.headers.add('Accept', 'application/json');

    final response = await request.close();

    print('Status: ${response.statusCode}');
    final responseBody = await response.transform(utf8.decoder).join();
    if (response.statusCode == 200) {
      final decoded = json.decode(responseBody);
      if (decoded is Map && decoded.containsKey('data')) {
        final data = decoded['data'] as Map;
        for (var key in data.keys) {
           final points = data[key]['dataPoints'] as List?;
           print('Symbol: $key, points count: ${points?.length}');
           if (points != null && points.isNotEmpty) {
             print('Points:');
             for (var p in points) {
               print('  $p');
             }
           }
        }
      } else {
        print('No data key. Body: $responseBody');
      }
    } else {
      print('Body: $responseBody');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
