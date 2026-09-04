import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import '../../data/ai_chat_service.dart';
import '../../data/ai_session_models.dart';
import '../../data/ai_session_service.dart';

/// Dio for AI gateway session APIs (same auth as chat).
final aiSessionServiceProvider = Provider<AiSessionService>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AiChatService.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  dio.interceptors.add(AuthInterceptor(SecureStorageService()));
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
        error: _friendlyError(e),
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
      state = state.copyWith(error: _friendlyError(e));
      return false;
    }
  }

  static String _friendlyError(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        return 'Sign in again to load chat history.';
      }
      if (code == 404) return 'Session not found.';
      return e.message ?? 'Could not reach chat history.';
    }
    return e.toString();
  }
}

final aiSessionProvider =
    NotifierProvider<AiSessionNotifier, SessionListState>(AiSessionNotifier.new);
