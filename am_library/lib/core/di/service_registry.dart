import 'dart:async';

import 'package:get_it/get_it.dart';
import '../auth/user_context.dart';
import '../network/api_client.dart';
import '../network/analysis_api_client.dart';
import '../network/websocket/am_stomp_client.dart';
import '../services/secure_storage_service.dart';
import '../utils/logger.dart';
import '../telemetry/telemetry_service.dart';
import '../telemetry/product_telemetry.dart';

/// The central hub for all core services in the AM Ecosystem.
/// Provides a unified singleton access point and lifecycle management.
class ServiceRegistry {
  static final GetIt I = GetIt.instance;

  /// Initialize all core services with the given configuration.
  /// Typically called during app startup.
  static void initialize({
    String? analysisBaseUrl,
    String? wsUrl,
    String? loggingBaseUrl,
    String? env,
  }) {
    // 1. Storage, Logging & Telemetry
    if (!I.isRegistered<SecureStorageService>()) {
      I.registerLazySingleton<SecureStorageService>(
        () => SecureStorageService(),
      );
    }
    if (!I.isRegistered<TelemetryService>()) {
      I.registerLazySingleton<TelemetryService>(() => TelemetryService());
    }
    AppLogger.initialize();

    // 2. Network Clients (REST)
    if (!I.isRegistered<ApiClient>()) {
      I.registerLazySingleton<ApiClient>(
        () => ApiClient(baseUrl: analysisBaseUrl),
      );
    }

    // 3. Analysis SDK Wrapper
    if (!I.isRegistered<AnalysisApiClient>()) {
      I.registerLazySingleton<AnalysisApiClient>(
        () => AnalysisApiClient(baseUrl: analysisBaseUrl),
      );
    }

    // 4. WebSocket (STOMP)
    if (!I.isRegistered<AmStompClient>()) {
      I.registerLazySingleton<AmStompClient>(
        () => AmStompClient(url: wsUrl),
      );
    }

    // 5. Product telemetry sink (fire-and-forget; gated by analyticsEnabled)
    if (loggingBaseUrl != null && loggingBaseUrl.isNotEmpty) {
      unawaited(
        ProductTelemetry.instance.initialize(
          loggingBaseUrl: loggingBaseUrl,
          env: env,
        ),
      );
    }

    AppLogger.info('✅ ServiceRegistry: Core infrastructure initialized.', tag: 'Registry');
  }

  /// Reset all services to their initial state.
  /// Useful for logout or clearing corrupted states.
  static Future<void> reset() async {
    AppLogger.warning('🔄 ServiceRegistry: Initiating global reset...', tag: 'Registry');

    // 1. Clear session data + in-memory user context cache
    if (I.isRegistered<SecureStorageService>()) {
      await I<SecureStorageService>().clearAuthData();
    }
    UserContext.instance.invalidate();

    // 2. Disconnect WebSocket
    if (I.isRegistered<AmStompClient>()) {
      I<AmStompClient>().disconnect();
    }

    // Note: We don't usually unregister from GetIt unless we need a fresh instance with different config.
    AppLogger.info('✅ ServiceRegistry: Reset complete.', tag: 'Registry');
  }

  // Convenience accessors
  static ApiClient get api => I<ApiClient>();
  static AnalysisApiClient get analysis => I<AnalysisApiClient>();
  static AmStompClient get stomp => I<AmStompClient>();
  static SecureStorageService get storage => I<SecureStorageService>();
  static TelemetryService get telemetry => I<TelemetryService>();
  /// Current user identity & auth header — use instead of raw storage reads.
  static UserContext get user => UserContext.instance;
}
