import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';
import '../providers/ai_chat_provider.dart';
import '../widgets/ai_widget_factory.dart';
import '../../data/ai_intent_response.dart';

/// AI Chat Screen with SSE real-time streaming, dynamic widgets, Stop Generation, and feedback.
class AiChatScreen extends ConsumerStatefulWidget {
  final String userId;
  const AiChatScreen({super.key, required this.userId});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    ref.read(aiChatProvider.notifier).sendMessage(
      text: text,
      userId: widget.userId,
      stream: true,
    );
    _scrollToBottom();
  }

  void _stop() {
    ref.read(aiChatProvider.notifier).stopGeneration();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);
    ref.listen(aiChatProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AM Finance AI',
                    style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                Text(
                  chatState.activeTool != null
                      ? '⚡ Running ${chatState.activeTool}…'
                      : 'AI Gateway Edge',
                  style: TextStyle(
                    color: chatState.activeTool != null
                        ? AppColors.primary
                        : context.textSecondary,
                    fontSize: 11,
                    fontWeight: chatState.activeTool != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: context.textSecondary),
            onPressed: () => ref.read(aiChatProvider.notifier).clearChat(),
            tooltip: 'New conversation',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.dividerColor),
        ),
      ),
      body: Column(
        children: [
          // ── Message List ────────────────────────────────────────────────────
          Expanded(
            child: chatState.messages.isEmpty
                ? _EmptyState(
                    userId: widget.userId,
                    onSuggestion: (text) {
                      _input.text = text;
                      _send();
                    })
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chatState.messages[index];
                      return _MessageBubble(
                        message: msg,
                        index: index,
                        onRate: (rating) => ref
                            .read(aiChatProvider.notifier)
                            .rateMessage(messageIndex: index, rating: rating),
                      );
                    },
                  ),
          ),

          // ── Input Bar with Send & Stop ───────────────────────────────────────
          _InputBar(
            controller: _input,
            isLoading: chatState.isLoading,
            onSend: _send,
            onStop: _stop,
          ),
        ],
      ),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final int index;
  final ValueChanged<String> onRate;

  const _MessageBubble({
    required this.message,
    required this.index,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final time = DateFormat('HH:mm').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Timestamp label
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
            child: Text(
              isUser ? 'You · $time' : 'AM AI · $time',
              style: TextStyle(
                  fontSize: 10,
                  color: context.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
          ),

          // Bubble
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.82),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primary : context.cardColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: isUser
                  ? null
                  : Border.all(color: context.borderColor),
            ),
            child: message.text.isEmpty && message.isStreaming
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        message.activeTool != null
                            ? 'Calling ${message.activeTool}…'
                            : 'Thinking…',
                        style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondary,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  )
                : Text(
                    message.text,
                    style: TextStyle(
                      color: isUser
                          ? AppColors.textPrimaryDark
                          : context.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
          ),

          // Active Tool chip if currently executing
          if (!isUser && message.isStreaming && message.activeTool != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Running ${message.activeTool}…',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),

          // Intent widget card below AI message
          if (!isUser && message.response != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: AiWidgetFactory.build(message.response!),
            ),

          // Tools used summary + Feedback thumbs
          if (!isUser && !message.isStreaming && message.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
              child: Row(
                children: [
                  if (message.response != null &&
                      message.response!.toolsUsed.isNotEmpty)
                    Expanded(
                      child: Text(
                        '⚡ ${message.response!.toolsUsed.join(', ')}',
                        style: TextStyle(
                            fontSize: 10, color: context.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  // Thumbs Up / Down feedback
                  InkWell(
                    onTap: () => onRate('thumbs_up'),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        message.userRating == 'thumbs_up'
                            ? Icons.thumb_up
                            : Icons.thumb_up_outlined,
                        size: 14,
                        color: message.userRating == 'thumbs_up'
                            ? AppColors.profit
                            : context.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => onRate('thumbs_down'),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        message.userRating == 'thumbs_down'
                            ? Icons.thumb_down
                            : Icons.thumb_down_outlined,
                        size: 14,
                        color: message.userRating == 'thumbs_down'
                            ? AppColors.loss
                            : context.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Input Bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;
  final VoidCallback onStop;

  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(top: BorderSide(color: context.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(color: context.textPrimary, fontSize: 14),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Ask about your portfolio…',
                hintStyle:
                    TextStyle(color: context.textSecondary, fontSize: 14),
                filled: true,
                fillColor: context.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? InkWell(
                    key: const ValueKey('stop'),
                    onTap: onStop,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Icon(Icons.stop_rounded,
                          color: AppColors.error, size: 22),
                    ),
                  )
                : InkWell(
                    key: const ValueKey('send'),
                    onTap: onSend,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String userId;
  final ValueChanged<String> onSuggestion;

  const _EmptyState({required this.userId, required this.onSuggestion});

  static const _suggestions = [
    '📊 Show my portfolio summary',
    '🧺 List my investment baskets',
    '📈 What are my top movers today?',
    '🥧 Show my sector allocation',
    '📋 List all my holdings',
    '🔄 Show recent activity',
    '🔍 Analyze NIFTYBEES ETF overlap',
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            Text('AM Finance AI',
                style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Ask anything about your portfolio or investment baskets',
              style:
                  TextStyle(color: context.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestions
                  .map((s) => _SuggestionChip(
                      label: s, onTap: () => onSuggestion(s)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                color: context.textSecondary, fontSize: 13)),
      ),
    );
  }
}
