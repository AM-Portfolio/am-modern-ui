import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/core/config/app_config.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_library/am_library.dart';

final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  await ConfigService.initialize();
  return ConfigService.config;
});

final apiClientProvider = FutureProvider<ApiClient>((ref) async {
  final config = await ref.watch(appConfigProvider.future);
  return ApiClient(
    baseUrl: config.api.baseUrl,
    fallbackToken: config.devAuthToken,
  );
});

final gmailApiConfigProvider = FutureProvider<GmailApiConfig>((ref) async {
  final config = await ref.watch(appConfigProvider.future);
  if (config.api.gmail == null) {
    throw Exception('Gmail API configuration is not available');
  }
  return config.api.gmail!;
});

final portfolioApiConfigProvider = FutureProvider<PortfolioApiConfig>((ref) async {
  final config = await ref.watch(appConfigProvider.future);
  if (config.api.portfolio == null) {
    throw Exception('Portfolio API configuration is not available');
  }
  return config.api.portfolio!;
});

final analysisApiClientProvider = FutureProvider<ApiClient>((ref) async {
  final config = await ref.watch(appConfigProvider.future);
  if (config.api.analysis == null) {
    throw Exception('Analysis API configuration is not available');
  }
  return ApiClient(
    baseUrl: config.api.analysis!.baseUrl,
    fallbackToken: config.devAuthToken,
  );
});

final stompClientProvider = Provider<AmStompClient>((ref) {
  return ServiceRegistry.stomp;
});

