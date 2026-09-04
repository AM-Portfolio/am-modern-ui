import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import '../../data/ai_chat_service.dart';
import '../../data/ai_intent_response.dart';
import '../../data/ai_stream_event.dart';
import 'ai_session_provider.dart';
import 'ai_usage_provider.dart';

// ─── Service Provider ─────────────────────────────────────────────────────────

/// Builds a [Dio] instance configured for the AI Gateway with [AuthInterceptor].
final aiChatServiceProvider = Provider<AiChatService>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AiChatService.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 45),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  AuthProviders.attachAuthInterceptor(dio);
  return AiChatService(dio);
});

// ─── Chat State ───────────────────────────────────────────────────────────────

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? sessionId;
  final String? activeTool;
  final String? currentTraceId;
  final bool quotaExceeded;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.sessionId,
    this.activeTool,
    this.currentTraceId,
    this.quotaExceeded = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? sessionId,
    String? activeTool,
    String? currentTraceId,
    bool? quotaExceeded,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        sessionId: sessionId ?? this.sessionId,
        activeTool: activeTool,
        currentTraceId: currentTraceId ?? this.currentTraceId,
        quotaExceeded: quotaExceeded ?? this.quotaExceeded,
      );
}

// ─── Chat Notifier (Riverpod v3) ──────────────────────────────────────────────

class AiChatNotifier extends Notifier<ChatState> {
  CancelToken? _cancelToken;
  StreamSubscription<AiStreamEvent>? _streamSub;

  @override
  ChatState build() {
    ref.onDispose(() {
      _cancelToken?.cancel();
      _streamSub?.cancel();
    });
    return const ChatState();
  }

  /// Sends message and streams token/tool/widget responses in real time.
  Future<void> sendMessage({
    required String text,
    required String userId,
    bool stream = true,
  }) async {
    if (kIsWeb) stream = false;
    if (text.trim().isEmpty || state.isLoading) return;

    final userMsg = ChatMessage(role: ChatRole.user, text: text);
    final assistantMsg = ChatMessage(
      role: ChatRole.assistant,
      text: '',
      isStreaming: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, assistantMsg],
      isLoading: true,
      activeTool: null,
      quotaExceeded: false,
    );

    final service = ref.read(aiChatServiceProvider);
    _cancelToken = CancelToken();

    if (!stream) {
      try {
        final response = await service.chat(
          message: text,
          userId: userId,
          sessionId: state.sessionId,
          cancelToken: _cancelToken,
        );
        _updateLastMessage(
          text: response.message,
          response: response,
          isStreaming: false,
          activeTool: null,
        );
        state = state.copyWith(
          isLoading: false,
          sessionId:
              response.sessionId.isNotEmpty ? response.sessionId : state.sessionId,
        );
        unawaited(ref.read(aiUsageProvider.notifier).refresh());
      } on AiQuotaExceededException catch (e) {
        _handleQuotaExceeded(e);
      } catch (e) {
        final error = AiIntentResponse.error('Could not reach AI: $e');
        _updateLastMessage(
          text: error.message,
          response: error,
          isStreaming: false,
          activeTool: null,
        );
        state = state.copyWith(isLoading: false);
      } finally {
        _cancelToken = null;
      }
      return;
    }

    // Real-time SSE streaming path
    StringBuffer fullText = StringBuffer();
    String widgetId = 'NONE';
    Map<String, dynamic> widgetParams = {};
    String traceId = '';
    String? sessionReceived = state.sessionId;
    List<String> toolsUsed = [];

    try {
      final eventStream = service.chatStream(
        message: text,
        userId: userId,
        sessionId: state.sessionId,
        cancelToken: _cancelToken,
      );

      await for (final event in eventStream) {
        switch (event.type) {
          case StreamEventType.token:
            if (event.content != null) {
              fullText.write(event.content!);
              _updateLastMessage(text: fullText.toString(), isStreaming: true);
            }
            break;

          case StreamEventType.toolStart:
            state = state.copyWith(activeTool: event.tool);
            _updateLastMessage(
              text: fullText.toString(),
              activeTool: event.tool,
              isStreaming: true,
            );
            break;

          case StreamEventType.toolEnd:
            if (event.tool != null && !toolsUsed.contains(event.tool!)) {
              toolsUsed.add(event.tool!);
            }
            state = state.copyWith(activeTool: null);
            _updateLastMessage(
              text: fullText.toString(),
              activeTool: null,
              isStreaming: true,
            );
            break;

          case StreamEventType.widget:
            if (event.widgetId != null) widgetId = event.widgetId!;
            if (event.widgetParams != null) widgetParams = event.widgetParams!;
            if (event.sessionId != null && event.sessionId!.isNotEmpty) {
              sessionReceived = event.sessionId;
            }
            break;

          case StreamEventType.done:
            if (event.traceId != null) traceId = event.traceId!;
            if (event.sessionId != null && event.sessionId!.isNotEmpty) {
              sessionReceived = event.sessionId;
            }
            if (event.toolsUsed != null) toolsUsed = event.toolsUsed!;
            break;

          case StreamEventType.error:
            if (_shouldFallbackToOneShotChat(event.content)) {
              final fallbackResponse = await service.chat(
                message: text,
                userId: userId,
                sessionId: state.sessionId,
                cancelToken: _cancelToken,
              );
              _updateLastMessage(
                text: fallbackResponse.message,
                response: fallbackResponse,
                isStreaming: false,
                activeTool: null,
              );
              state = state.copyWith(
                isLoading: false,
                sessionId: fallbackResponse.sessionId.isNotEmpty ? fallbackResponse.sessionId : state.sessionId,
              );
              return;
            }
            fullText.write(event.content ?? 'An error occurred.');
            widgetId = 'ERROR';
            widgetParams = {'reason': event.content ?? 'Stream error', 'traceId': traceId};
            break;

          case StreamEventType.cancelled:
            fullText.write(' [Stopped]');
            break;

          case StreamEventType.unknown:
            break;
        }
      }
    } on AiQuotaExceededException catch (e) {
      _handleQuotaExceeded(e);
      _cancelToken = null;
      return;
    } catch (e) {
      fullText.write('\nError: ');
      widgetId = 'ERROR';
    } finally {
      var finalText = fullText.toString();
      var finalWidgetId = widgetId;
      var finalWidgetParams = widgetParams;
      var finalToolsUsed = toolsUsed;
      var finalSessionId = sessionReceived;
      var finalTraceId = traceId;

      if (_shouldRetryOneShotChat(
        finalText: finalText,
        widgetId: finalWidgetId,
        toolsUsed: finalToolsUsed,
        cancelled: _cancelToken?.isCancelled ?? false,
      )) {
        try {
          final oneShot = await service.chat(
            message: text,
            userId: userId,
            sessionId: state.sessionId,
            cancelToken: _cancelToken,
          );
          finalText = oneShot.message;
          finalWidgetId = oneShot.widgetId;
          finalWidgetParams = oneShot.widgetParams;
          finalToolsUsed = oneShot.toolsUsed;
          if (oneShot.sessionId.isNotEmpty) finalSessionId = oneShot.sessionId;
          if (oneShot.traceId.isNotEmpty) finalTraceId = oneShot.traceId;
        } catch (_) {
          // Keep partial stream state if one-shot also fails.
        }
      }

      final finalResponse = AiIntentResponse(
        message: finalText,
        widgetId: finalWidgetId,
        widgetParams: finalWidgetParams,
        sessionId: finalSessionId ?? '',
        toolsUsed: finalToolsUsed,
        traceId: finalTraceId,
      );

      _updateLastMessage(
        text: finalText,
        response: finalResponse,
        isStreaming: false,
        activeTool: null,
      );

      state = state.copyWith(
        isLoading: false,
        activeTool: null,
        sessionId: finalSessionId,
      );
      unawaited(ref.read(aiUsageProvider.notifier).refresh());
      _cancelToken = null;
    }
  }

  void _handleQuotaExceeded(AiQuotaExceededException e) {
    final lower = e.message.toLowerCase();
    final isRealQuota = lower.contains('quota') ||
        e.details.containsKey('limit') ||
        e.details.containsKey('used');
    final error = AiIntentResponse(
      message: e.message,
      widgetId: 'ERROR',
      widgetParams: {
        'reason': isRealQuota ? 'quota_exceeded' : 'subscription_error',
        'code': isRealQuota ? 'QUOTA_EXCEEDED' : 'SUBSCRIPTION_ERROR',
        ...e.details,
      },
      sessionId: state.sessionId ?? '',
      toolsUsed: const [],
      traceId: '',
    );
    _updateLastMessage(
      text: error.message,
      response: error,
      isStreaming: false,
      activeTool: null,
    );
    state = state.copyWith(
      isLoading: false,
      activeTool: null,
      // Upgrade dialog only for genuine quota exhaustion
      quotaExceeded: isRealQuota,
    );
  }

  void clearQuotaExceeded() {
    if (state.quotaExceeded) {
      state = state.copyWith(quotaExceeded: false);
    }
  }

  /// Stream on web often completes with no tokens/widgets; retry one-shot POST.
  static bool _shouldRetryOneShotChat({
    required String finalText,
    required String widgetId,
    required List<String> toolsUsed,
    required bool cancelled,
  }) {
    if (cancelled) return false;
    if (finalText.trim().isNotEmpty &&
        widgetId != 'NONE' &&
        widgetId != 'TEXT_RESPONSE') {
      return false;
    }
    if (finalText.trim().isEmpty) return true;
    return widgetId == 'NONE' ||
        (widgetId == 'TEXT_RESPONSE' && toolsUsed.isNotEmpty);
  }

  /// Fall back to POST /v1/ai/chat when SSE is unavailable (e.g. Flutter web XHR).
  static bool _shouldFallbackToOneShotChat(String? content) {
    if (content == null || content.isEmpty) return false;
    final lower = content.toLowerCase();
    return lower.contains('404') ||
        lower.contains('xmlhttprequest') ||
        lower.contains('connection errored') ||
        lower.contains('network layer') ||
        lower.contains('stream connection failed');
  }

  /// Helper to update the latest assistant bubble in place
  void _updateLastMessage({
    required String text,
    AiIntentResponse? response,
    bool isStreaming = true,
    String? activeTool,
  }) {
    if (state.messages.isEmpty) return;
    final updatedList = List<ChatMessage>.from(state.messages);
    final lastIndex = updatedList.length - 1;
    final current = updatedList[lastIndex];

    updatedList[lastIndex] = current.copyWith(
      text: text,
      response: response ?? current.response,
      isStreaming: isStreaming,
      activeTool: activeTool,
    );

    state = state.copyWith(messages: updatedList);
  }

  /// Cancels any currently active HTTP/SSE generation.
  void stopGeneration() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('User stopped generation');
    }
    state = state.copyWith(isLoading: false, activeTool: null);
  }

  /// Submits feedback for a completed turn.
  Future<void> rateMessage({
    required int messageIndex,
    required String rating,
    String? comment,
  }) async {
    if (messageIndex < 0 || messageIndex >= state.messages.length) return;
    final msg = state.messages[messageIndex];
    final sessionId = msg.response?.sessionId ?? state.sessionId;

    if (sessionId == null || sessionId.isEmpty) return;

    final service = ref.read(aiChatServiceProvider);
    await service.sendFeedback(sessionId: sessionId, rating: rating, comment: comment);

    final updated = List<ChatMessage>.from(state.messages);
    updated[messageIndex] = msg.copyWith(userRating: rating);
    state = state.copyWith(messages: updated);
  }

  /// Confirms a Human-In-The-Loop action (Phase 4 Smart Order).
  Future<bool> confirmAction({
    required String confirmToken,
    required String userId,
  }) async {
    final service = ref.read(aiChatServiceProvider);
    final response = await service.confirmAction(
      confirmToken: confirmToken,
      userId: userId,
    );
    return response != null && response['status'] == 'confirmed';
  }

  /// Drops local messages and resets sessionId for a fresh conversation.
  void clearChat() {
    stopGeneration();
    state = const ChatState();
  }

  /// Loads a persisted session from the gateway and replaces the local transcript.
  Future<void> loadSession(String sessionId) async {
    if (sessionId.isEmpty) return;
    stopGeneration();
    state = state.copyWith(isLoading: true, activeTool: null);
    try {
      final service = ref.read(aiSessionServiceProvider);
      final detail = await service.getSession(sessionId);
      state = ChatState(
        messages: detail.toChatMessages(),
        isLoading: false,
        sessionId: detail.session.id,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, activeTool: null);
      rethrow;
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final aiChatProvider =
    NotifierProvider<AiChatNotifier, ChatState>(AiChatNotifier.new);
