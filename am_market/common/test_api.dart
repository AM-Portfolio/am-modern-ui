import 'package:am_market_common/services/api_service.dart';
import 'package:am_auth_ui/core/services/secure_storage_service.dart';
import 'package:get_it/get_it.dart';

void main() async {
  GetIt.I.registerSingleton<SecureStorageService>(SecureStorageService());
  final api = ApiService();
  try {
     final response = await api.fetchHistoricalData(
       symbols: ['NIFTY 50'],
       from: '2025-06-05',
       to: '2026-06-05',
       interval: '1d',
       isIndexSymbol: true
     );
     print('Data: $response');
  } catch (e) {
     print('Error: $e');
  }
}
