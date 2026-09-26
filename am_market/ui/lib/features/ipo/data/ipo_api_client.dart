import 'dart:convert';
import 'package:am_market_ui/core/services/market_data_sdk_service.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:am_market_sdk/market/api.dart';

class IpoApiClient {
  final MarketDataSdkService sdkService;

  IpoApiClient(this.sdkService);

  ApiClient get _client => sdkService.marketDataApi.apiClient;

  Future<AsraxIpoCountsDto> getIpoCounts() async {
    final response = await _client.invokeAPI(
      '/v1/market-data/ipo/counts',
      'GET',
      [],
      null,
      {},
      {},
      null,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonResponse = json.decode(response.body);
      return AsraxIpoCountsDto.fromJson(jsonResponse['data'] ?? jsonResponse);
    } else {
      throw Exception('Failed to load IPO counts: ${response.statusCode}');
    }
  }

  Future<List<AsraxIpoSummaryDto>> getIpos(String status) async {
    final response = await _client.invokeAPI(
      '/v1/market-data/ipo',
      'GET',
      [QueryParam('status', status)],
      null,
      {},
      {},
      null,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonResponse = json.decode(response.body);
      final List data = jsonResponse['data'] ?? [];
      return data.map((e) => AsraxIpoSummaryDto.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load IPOs: ${response.statusCode}');
    }
  }

  Future<AsraxIpoDetailsDto> getIpoDetails(String id) async {
    final response = await _client.invokeAPI(
      '/v1/market-data/ipo/$id',
      'GET',
      [],
      null,
      {},
      {},
      null,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonResponse = json.decode(response.body);
      final data = jsonResponse['data'] ?? jsonResponse;
      return AsraxIpoDetailsDto.fromJson(data);
    } else {
      throw Exception('Failed to load IPO details: ${response.statusCode}');
    }
  }
}
