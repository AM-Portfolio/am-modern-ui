import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import '../../data/ai_dio_web_credentials.dart';
import '../../data/ai_usage_service.dart';

final aiUsageServiceProvider = Provider<AiUsageService>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AiUsageService.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      extra: kIsWeb ? const {'withCredentials': true} : null,
    ),
  );
  if (kIsWeb) configureAiWebCredentials(dio);
  AuthProviders.attachAuthInterceptor(dio);
  return AiUsageService(dio);
});

class AiUsageNotifier extends Notifier<AiTokenUsage> {
  @override
  AiTokenUsage build() => AiTokenUsage.empty;

  Future<void> refresh() async {
    try {
      final usage = await ref.read(aiUsageServiceProvider).fetchAiChatTokens();
      state = usage;
    } catch (e, st) {
      debugPrint('aiUsageProvider.refresh failed: $e\n$st');
      // Keep last known usage; button stays empty on cold failure.
    }
  }
}

final aiUsageProvider =
    NotifierProvider<AiUsageNotifier, AiTokenUsage>(AiUsageNotifier.new);
