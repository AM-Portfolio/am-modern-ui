import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/ai_chat_service.dart';
import '../../data/ai_intent_response.dart';

// ─── Service Provider ─────────────────────────────────────────────────────────

final aiChatServiceProvider = Provider<AiChatService>((_) => AiChatService());

// ─── Chat State ───────────────────────────────────────────────────────────────

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? sessionId;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.sessionId,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? sessionId,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        sessionId: sessionId ?? this.sessionId,
      );
}

// ─── Chat Notifier (Riverpod v3) ──────────────────────────────────────────────

class AiChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();

  Future<void> sendMessage({required String text, required String userId}) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(role: ChatRole.user, text: text);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    final service = ref.read(aiChatServiceProvider);
    final response = await service.chat(
      message: text,
      userId: userId,
      sessionId: state.sessionId,
    );

    final assistantMsg = ChatMessage(
      role: ChatRole.assistant,
      text: response.message,
      response: response,
    );

    state = state.copyWith(
      messages: [...state.messages, assistantMsg],
      isLoading: false,
      sessionId: response.sessionId.isNotEmpty
          ? response.sessionId
          : state.sessionId,
    );
  }

  void clearChat() => state = const ChatState();
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final aiChatProvider =
    NotifierProvider<AiChatNotifier, ChatState>(AiChatNotifier.new);
