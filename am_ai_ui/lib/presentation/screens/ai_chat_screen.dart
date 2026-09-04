import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_design_system/am_design_system.dart';
import '../providers/ai_chat_provider.dart';
import '../providers/ai_session_provider.dart';
import '../providers/ai_usage_provider.dart';
import '../theme/ai_chat_theme.dart';
import '../widgets/ai_history_drawer.dart';
import '../widgets/ai_message_format.dart';
import '../widgets/ai_widget_factory.dart';
import '../../data/ai_intent_response.dart';
import '../../data/ai_usage_service.dart';

/// AI Chat Screen with SSE real-time streaming, dynamic widgets, Stop Generation, and feedback.
class AiChatScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? displayName;

  const AiChatScreen({
    super.key,
    required this.userId,
    this.displayName,
  });

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiUsageProvider.notifier).refresh();
    });
  }

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

  void _send([String? preset]) {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty) return;
    _input.clear();
    ref.read(aiChatProvider.notifier).sendMessage(
          text: text,
          userId: widget.userId,
          // Flutter web Dio cannot POST SSE streams (XHR onError); use one-shot.
          stream: !kIsWeb,
        );
    _scrollToBottom();
  }

  void _stop() {
    ref.read(aiChatProvider.notifier).stopGeneration();
  }

  void _openHistory() {
    ref.read(aiSessionProvider.notifier).refresh();
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Future<void> _resumeSession(String sessionId) async {
    Navigator.of(context).maybePop();
    try {
      await ref.read(aiChatProvider.notifier).loadSession(sessionId);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load chat: $e')),
      );
    }
  }

  Future<void> _showUpgradeDialog() async {
    ref.read(aiChatProvider.notifier).clearQuotaExceeded();
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Token limit reached'),
        content: const Text(
          'You’ve used this month’s AI chat tokens. Upgrade your plan for a higher allowance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('View plans'),
          ),
        ],
      ),
    );
    if (go == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Open Profile → Subscription to upgrade your plan.'),
        ),
      );
    }
  }

  String _resolveDisplayName(BuildContext context) {
    final passed = widget.displayName?.trim();
    if (passed != null && passed.isNotEmpty) return passed;
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is Authenticated) {
        final dn = authState.user.displayName?.trim();
        if (dn != null && dn.isNotEmpty) return dn;
        return _nameFromEmail(authState.user.email);
      }
    } catch (_) {}
    return '';
  }

  String _nameFromEmail(String email) {
    if (!email.contains('@')) return '';
    final local = email.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ').trim();
    if (local.isEmpty) return '';
    return local
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }

  String _firstName(BuildContext context) {
    final name = _resolveDisplayName(context);
    if (name.isEmpty) return 'there';
    return name.split(RegExp(r'\s+')).first;
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
    final usage = ref.watch(aiUsageProvider);
    ref.listen(aiChatProvider, (_, __) => _scrollToBottom());
    ref.listen<ChatState>(aiChatProvider, (prev, next) {
      if (next.quotaExceeded && prev?.quotaExceeded != true) {
        _showUpgradeDialog();
      }
    });

    final firstName = _firstName(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.backgroundColor,
      endDrawer: AiHistoryDrawer(
        activeSessionId: chatState.sessionId,
        onSelectSession: _resumeSession,
      ),
      appBar: _ChatAppBar(
        activeTool: chatState.activeTool,
        onHistory: _openHistory,
        onNewChat: () => ref.read(aiChatProvider.notifier).clearChat(),
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.messages.isEmpty
                ? _EmptyState(
                    firstName: firstName,
                    onSuggestion: _send,
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      const maxContentWidth = 920.0;
                      final horizontalPad = (constraints.maxWidth - maxContentWidth)
                              .clamp(0.0, double.infinity) /
                          2;
                      final pad = EdgeInsets.fromLTRB(
                        20 + horizontalPad,
                        8,
                        20 + horizontalPad,
                        16,
                      );
                      return ListView.builder(
                        controller: _scroll,
                        padding: pad,
                        itemCount: chatState.messages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _WelcomeHeader(
                              firstName: firstName,
                              compact: true,
                            );
                          }
                          final msgIndex = index - 1;
                          final msg = chatState.messages[msgIndex];
                          return _MessageBubble(
                            message: msg,
                            index: msgIndex,
                            onRate: (rating) => ref
                                .read(aiChatProvider.notifier)
                                .rateMessage(
                                  messageIndex: msgIndex,
                                  rating: rating,
                                ),
                          );
                        },
                      );
                    },
                  ),
          ),
          _InputBar(
            controller: _input,
            isLoading: chatState.isLoading,
            usage: usage,
            onSend: () => _send(),
            onStop: _stop,
          ),
        ],
      ),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? activeTool;
  final VoidCallback onHistory;
  final VoidCallback onNewChat;

  const _ChatAppBar({
    required this.activeTool,
    required this.onHistory,
    required this.onNewChat,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.surfaceColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: context.aiPrimaryGradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: context.aiPrimary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.auto_awesome, color: context.aiOnPrimary, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AM Finance AI',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                activeTool != null
                    ? '⚡ Running ${AiMessageFormat.toolLabel(activeTool!)}…'
                    : 'AI Gateway Edge',
                style: TextStyle(
                  color: activeTool != null
                      ? context.aiPrimary
                      : context.textSecondary,
                  fontSize: 11,
                  fontWeight:
                      activeTool != null ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.history_rounded, color: context.textSecondary),
          onPressed: onHistory,
          tooltip: 'Chat history',
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Icon(Icons.add_rounded, color: context.textSecondary),
            onPressed: onNewChat,
            tooltip: 'New chat',
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: context.dividerColor),
      ),
    );
  }
}

// ─── Welcome Header ───────────────────────────────────────────────────────────

class _WelcomeHeader extends StatelessWidget {
  final String firstName;
  final bool compact;

  const _WelcomeHeader({
    required this.firstName,
    this.compact = false,
  });

  static String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16, top: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: context.aiPrimary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: context.aiPrimary.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            children: [
              Text(
                '👋',
                style: TextStyle(fontSize: 16, height: 1.2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${_timeGreeting()}, ',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: firstName,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '👋 ${_timeGreeting()}, ',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                TextSpan(
                  text: firstName,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How can I help you today?',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ask about portfolio, holdings, markets, and more.',
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message Bubble ─────────────────────────────────────────────────────────

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
    final displayText = isUser
        ? message.text
        : AiMessageFormat.cleanDisplayText(message.text, message.response);
    final baseStyle = TextStyle(
      color: isUser ? context.aiOnPrimary : context.textPrimary,
      fontSize: 14,
      height: 1.5,
    );
    final widgetId = message.response?.widgetId;
    final inlineWidget = !message.isStreaming &&
        message.response != null &&
        AiMessageFormat.usesInlineWidgetLayout(widgetId);
    final showTextBubble = message.isStreaming || displayText.isNotEmpty;
    final structuredWidget = AiMessageFormat.isStructuredWidget(widgetId);
    final fallbackText = message.response?.message.trim().isNotEmpty == true
        ? message.response!.message.trim()
        : message.text.trim();

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6, right: 4),
              child: Text(
                'You · $time',
                style: TextStyle(
                  fontSize: 10,
                  color: context.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: context.aiPrimaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: context.aiPrimary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(message.text, style: baseStyle),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 2, right: 10),
            decoration: BoxDecoration(
              gradient: context.aiPrimaryGradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: context.aiPrimary.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.auto_awesome, color: context.aiOnPrimary, size: 14),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 2),
                  child: Text(
                    'AM AI · $time',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (inlineWidget)
                  _InlineWidgetMessage(
                    displayText: displayText,
                    message: message,
                    baseStyle: baseStyle,
                  )
                else ...[
                  if (showTextBubble)
                    _AssistantTextBubble(
                      message: message,
                      displayText: displayText,
                      baseStyle: baseStyle,
                    ),
                  if (!message.isStreaming &&
                      !showTextBubble &&
                      !inlineWidget &&
                      !structuredWidget)
                    _AssistantTextBubble(
                      message: message,
                      displayText: fallbackText.isNotEmpty
                          ? fallbackText
                          : 'No response received. Check your connection and try again.',
                      baseStyle: baseStyle,
                    ),
                  if (message.isStreaming && message.activeTool != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Row(
                        children: [
                          Icon(Icons.bolt_rounded,
                              size: 12, color: context.aiPrimary),
                          const SizedBox(width: 4),
                          Text(
                            'Running ${AiMessageFormat.toolLabel(message.activeTool!)}…',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: context.aiPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (message.response != null)
                    AiWidgetFactory.build(
                      message.response!,
                      messageText: message.text,
                    ),
                ],
                if (!message.isStreaming &&
                    message.text.isNotEmpty &&
                    message.response != null &&
                    message.response!.toolsUsed.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 2, right: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: message.response!.toolsUsed
                                .map(
                                  (tool) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.surfaceColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: context.borderColor),
                                    ),
                                    child: Text(
                                      AiMessageFormat.toolLabel(tool),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: context.textSecondary,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        _FeedbackButton(
                          icon: message.userRating == 'thumbs_up'
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined,
                          color: message.userRating == 'thumbs_up'
                              ? context.marketPositive
                              : context.textSecondary,
                          onTap: () => onRate('thumbs_up'),
                        ),
                        const SizedBox(width: 4),
                        _FeedbackButton(
                          icon: message.userRating == 'thumbs_down'
                              ? Icons.thumb_down
                              : Icons.thumb_down_outlined,
                          color: message.userRating == 'thumbs_down'
                              ? context.marketNegative
                              : context.textSecondary,
                          onTap: () => onRate('thumbs_down'),
                        ),
                      ],
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

class _AssistantTextBubble extends StatelessWidget {
  final ChatMessage message;
  final String displayText;
  final TextStyle baseStyle;
  final bool fullWidth;

  const _AssistantTextBubble({
    required this.message,
    required this.displayText,
    required this.baseStyle,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = message.text.isEmpty && message.isStreaming
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.aiPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                message.activeTool != null
                    ? 'Calling ${AiMessageFormat.toolLabel(message.activeTool!)}…'
                    : 'Thinking…',
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          )
        : AiMessageFormat.richText(
            displayText.isNotEmpty ? displayText : message.text,
            baseStyle,
          );

    return Container(
      width: fullWidth ? double.infinity : null,
      constraints: fullWidth
          ? null
          : BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.45),
        ),
      ),
      child: content,
    );
  }
}

class _AssistantIntroLine extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;

  const _AssistantIntroLine({
    required this.text,
    required this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: context.aiPrimary.withValues(alpha: 0.55),
            width: 3,
          ),
        ),
      ),
      child: AiMessageFormat.richText(text, baseStyle),
    );
  }
}

/// Intro line + full-width structured widget (portfolio cards, etc.).
class _InlineWidgetMessage extends StatelessWidget {
  final String displayText;
  final ChatMessage message;
  final TextStyle baseStyle;

  const _InlineWidgetMessage({
    required this.displayText,
    required this.message,
    required this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    final widget = AiWidgetFactory.build(
      message.response!,
      messageText: message.text,
      embedded: true,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: context.shadow(context.isDark ? 0.22 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (displayText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _AssistantIntroLine(
                text: displayText,
                baseStyle: baseStyle.copyWith(
                  fontSize: 13.5,
                  height: 1.45,
                  color: context.textPrimary,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              displayText.isNotEmpty ? 12 : 0,
              12,
              12,
            ),
            child: widget,
          ),
        ],
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeedbackButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

// ─── Follow-up Suggestions ────────────────────────────────────────────────────

class _FollowUpSuggestions extends StatelessWidget {
  final ValueChanged<String> onTap;

  const _FollowUpSuggestions({required this.onTap});

  static const _items = [
    (Icons.trending_up_rounded, 'Top performing assets'),
    (Icons.receipt_long_rounded, 'Recent transactions'),
    (Icons.shield_outlined, 'Check portfolio risk'),
    (Icons.pie_chart_outline_rounded, 'Asset allocation'),
    (Icons.insights_rounded, 'Investment insights'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You can also try:',
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FollowUpChip(
                        icon: item.$1,
                        label: item.$2,
                        onTap: () => onTap(item.$2),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowUpChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FollowUpChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.aiPrimary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: context.aiPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Input Bar ────────────────────────────────────────────────────────────────

class _InputBar extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final bool isLoading;
  final AiTokenUsage usage;
  final VoidCallback onSend;
  final VoidCallback onStop;

  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.usage,
    required this.onSend,
    required this.onStop,
  });

  @override
  ConsumerState<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends ConsumerState<_InputBar> {
  bool _usagePanelOpen = false;

  Future<void> _toggleUsagePanel() async {
    if (!_usagePanelOpen && !widget.usage.hasLimit) {
      await ref.read(aiUsageProvider.notifier).refresh();
    }
    if (!mounted) return;
    setState(() => _usagePanelOpen = !_usagePanelOpen);
  }

  void _closeUsagePanel() {
    if (_usagePanelOpen) setState(() => _usagePanelOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final usage = ref.watch(aiUsageProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        const maxContentWidth = 920.0;
        final horizontalPad =
            (constraints.maxWidth - maxContentWidth).clamp(0.0, double.infinity) /
                2;
        return Container(
          padding: EdgeInsets.fromLTRB(
            20 + horizontalPad,
            10,
            20 + horizontalPad,
            16,
          ),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            border: Border(top: BorderSide(color: context.dividerColor)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRect(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  heightFactor: _usagePanelOpen ? 1 : 0,
                  alignment: Alignment.bottomCenter,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _usagePanelOpen ? 1 : 0,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TokenUsagePopover(
                        usage: usage,
                        onClose: _closeUsagePanel,
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: context.borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: context.shadow(context.isDark ? 0.2 : 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: widget.controller,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 14,
                        ),
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => widget.onSend(),
                        decoration: InputDecoration(
                          hintText: 'Ask about your portfolio…',
                          hintStyle: TextStyle(
                            color: context.textSecondary,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _TokenUsageRingButton(
                    usage: usage,
                    isActive: _usagePanelOpen,
                    onTap: _toggleUsagePanel,
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: widget.isLoading
                        ? InkWell(
                            key: const ValueKey('stop'),
                            onTap: widget.onStop,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: context.statusError.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: context.statusError),
                              ),
                              child: Icon(Icons.stop_rounded,
                                  color: context.statusError, size: 22),
                            ),
                          )
                        : InkWell(
                            key: const ValueKey('send'),
                            onTap: widget.onSend,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: context.aiPrimaryGradient,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: context.aiPrimary
                                        .withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(Icons.send_rounded,
                                  color: context.aiOnPrimary, size: 18),
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'AM Finance AI can make mistakes. Verify important information.',
                style: TextStyle(
                  fontSize: 10,
                  color: context.textSecondary.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Cursor-style panel — floats above the composer, no modal barrier.
class _TokenUsagePopover extends StatelessWidget {
  final AiTokenUsage usage;
  final VoidCallback onClose;

  const _TokenUsagePopover({
    required this.usage,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final hasLimit = usage.hasLimit;

    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.borderColor.withValues(alpha: context.isDark ? 0.55 : 0.9),
          ),
          boxShadow: [
            BoxShadow(
              color: context.shadow(context.isDark ? 0.35 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'AI chat tokens',
                    style: TextStyle(
                      color: context.textSecondary.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.close_rounded, size: 18, color: context.textSecondary),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hasLimit ? '${usage.percentFull}% Full' : 'Usage unavailable',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  usage.detailTokensLabelTilde,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Cursor-style track: colored used segment(s) + remaining
            _TokenUsageProgressLine(usage: usage),
            const SizedBox(height: 14),
            _UsageBreakdownRow(
              color: context.aiUsageUsed,
              label: 'Used this month',
              value: hasLimit ? '~${AiTokenUsage.formatCount(usage.used)}' : '—',
            ),
            const SizedBox(height: 8),
            _UsageBreakdownRow(
              color: context.aiUsageRemaining,
              label: 'Remaining',
              value: hasLimit ? '~${AiTokenUsage.formatCount(usage.remaining)}' : '—',
            ),
          ],
        ),
      ),
    );
  }
}

class _TokenUsageProgressLine extends StatelessWidget {
  final AiTokenUsage usage;

  const _TokenUsageProgressLine({required this.usage});

  @override
  Widget build(BuildContext context) {
    final frac = usage.hasLimit ? usage.fractionUsed.clamp(0.0, 1.0) : 0.0;
    final segments = context.aiUsageBarSegments;
    final weights = context.aiUsageBarSegmentWeights;

    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 9,
        width: double.infinity,
        child: CustomPaint(
          painter: _TokenUsageBarPainter(
            fractionUsed: frac,
            trackColor: context.aiUsageTrack,
            segmentColors: segments,
            segmentWeights: weights,
          ),
        ),
      ),
    );
  }
}

class _TokenUsageBarPainter extends CustomPainter {
  final double fractionUsed;
  final Color trackColor;
  final List<Color> segmentColors;
  final List<double> segmentWeights;

  const _TokenUsageBarPainter({
    required this.fractionUsed,
    required this.trackColor,
    required this.segmentColors,
    required this.segmentWeights,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()..color = trackColor;
    canvas.drawRect(Offset.zero & size, trackPaint);

    if (fractionUsed <= 0 || size.width <= 0) return;

    final usedWidth = size.width * fractionUsed;
    final weightSum = segmentWeights.fold<double>(0, (a, b) => a + b);
    var x = 0.0;
    for (var i = 0; i < segmentColors.length; i++) {
      final w = usedWidth * (segmentWeights[i] / weightSum);
      canvas.drawRect(
        Rect.fromLTWH(x, 0, w, size.height),
        Paint()..color = segmentColors[i],
      );
      x += w;
    }
  }

  @override
  bool shouldRepaint(covariant _TokenUsageBarPainter oldDelegate) {
    return oldDelegate.fractionUsed != fractionUsed ||
        oldDelegate.trackColor != trackColor;
  }
}

class _UsageBreakdownRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _UsageBreakdownRow({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Circular ring beside send — toggles the usage popover.
class _TokenUsageRingButton extends StatelessWidget {
  final AiTokenUsage usage;
  final bool isActive;
  final VoidCallback onTap;

  const _TokenUsageRingButton({
    required this.usage,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fill = usage.fractionUsed;
    final ringColor = usage.percentFull >= 90
        ? context.statusError
        : context.aiPrimary;
    final tooltip = usage.hasLimit
        ? '${usage.chipLabel} · ${usage.remainingLabel}'
        : 'Token usage';

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? context.aiPrimary.withValues(alpha: 0.12)
                      : context.cardColor,
                  border: Border.all(
                    color: isActive ? context.aiPrimary : context.borderColor,
                    width: isActive ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.shadow(context.isDark ? 0.2 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  value: usage.hasLimit ? fill : 0,
                  strokeWidth: 3.5,
                  backgroundColor: context.borderColor.withValues(alpha: 0.45),
                  color: ringColor,
                ),
              ),
              Text(
                usage.percentLabel,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: usage.hasLimit && usage.percentFull >= 100 ? 10 : 11,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String firstName;
  final ValueChanged<String> onSuggestion;

  const _EmptyState({
    required this.firstName,
    required this.onSuggestion,
  });

  static const _suggestions = [
    (Icons.account_balance_wallet_outlined, 'Show my portfolio summary'),
    (Icons.shopping_basket_outlined, 'List my investment baskets'),
    (Icons.show_chart_rounded, 'What are my top movers today?'),
    (Icons.pie_chart_outline_rounded, 'Show my sector allocation'),
    (Icons.table_chart_outlined, 'List all my holdings'),
    (Icons.sync_rounded, 'Show recent activity'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeHeader(firstName: firstName),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map(
                  (s) => _FollowUpChip(
                    icon: s.$1,
                    label: s.$2,
                    onTap: () => onSuggestion(s.$2),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
