import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import '../../data/ai_chat_service.dart';
import '../../data/ai_dio_web_credentials.dart';
import '../../data/ai_session_errors.dart';
import '../../data/ai_session_models.dart';
import '../../data/ai_session_service.dart';

/// Dio for AI gateway session APIs (same auth as chat).
///
/// Web BFF / cookie sessions need credentials so cookies are sent in
/// normal and incognito windows when the UI host differs from the AI domain.
final aiSessionServiceProvider = Provider<AiSessionService>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AiChatService.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      extra: kIsWeb ? const {'withCredentials': true} : null,
    ),
  );
  if (kIsWeb) configureAiWebCredentials(dio);
  AuthProviders.attachAuthInterceptor(dio);
  return AiSessionService(dio);
});

class SessionListState {
  final List<AiSessionSummary> sessions;
  final bool isLoading;
  final String? error;

  const SessionListState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
  });

  SessionListState copyWith({
    List<AiSessionSummary>? sessions,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      SessionListState(
        sessions: sessions ?? this.sessions,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class AiSessionNotifier extends Notifier<SessionListState> {
  @override
  SessionListState build() => const SessionListState();

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final service = ref.read(aiSessionServiceProvider);
      final sessions = await service.listSessions();
      state = SessionListState(sessions: sessions, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: aiSessionFriendlyError(e),
      );
    }
  }

  Future<bool> deleteSession(String sessionId) async {
    try {
      final service = ref.read(aiSessionServiceProvider);
      await service.deleteSession(sessionId);
      state = state.copyWith(
        sessions: state.sessions.where((s) => s.id != sessionId).toList(),
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: aiSessionFriendlyError(e));
      return false;
    }
  }
}

final aiSessionProvider =
    NotifierProvider<AiSessionNotifier, SessionListState>(AiSessionNotifier.new);
