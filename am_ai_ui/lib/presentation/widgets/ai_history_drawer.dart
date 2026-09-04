import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../data/ai_session_models.dart';
import '../providers/ai_session_provider.dart';
import '../theme/ai_chat_theme.dart';

/// End-drawer listing durable AI sessions from the gateway / user-platform.
class AiHistoryDrawer extends ConsumerStatefulWidget {
  final String? activeSessionId;
  final ValueChanged<String> onSelectSession;

  const AiHistoryDrawer({
    super.key,
    this.activeSessionId,
    required this.onSelectSession,
  });

  @override
  ConsumerState<AiHistoryDrawer> createState() => _AiHistoryDrawerState();
}

class _AiHistoryDrawerState extends ConsumerState<AiHistoryDrawer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiSessionProvider.notifier).refresh();
    });
  }

  Future<void> _confirmDelete(AiSessionSummary session) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete chat?'),
        content: Text(
          '“${session.title}” will be removed from history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final deleted =
        await ref.read(aiSessionProvider.notifier).deleteSession(session.id);
    if (!deleted && mounted) {
      final err = ref.read(aiSessionProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Could not delete session.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiSessionProvider);
    final width = MediaQuery.sizeOf(context).width;
    final drawerWidth = width < 480 ? width * 0.92 : 360.0;

    return Drawer(
      width: drawerWidth,
      backgroundColor: context.surfaceColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, color: context.aiPrimary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Chat history',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: state.isLoading
                        ? null
                        : () => ref.read(aiSessionProvider.notifier).refresh(),
                    icon: Icon(Icons.refresh_rounded, color: context.textSecondary),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.close_rounded, color: context.textSecondary),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.dividerColor),
            if (state.isLoading && state.sessions.isEmpty)
              const Expanded(
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (state.error != null && state.sessions.isEmpty)
              Expanded(
                child: _EmptyOrError(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(aiSessionProvider.notifier).refresh(),
                ),
              )
            else if (state.sessions.isEmpty)
              const Expanded(
                child: _EmptyOrError(
                  message: 'No saved chats yet.\nSend a message to start one.',
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      ref.read(aiSessionProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.sessions.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: context.dividerColor.withValues(alpha: 0.5),
                    ),
                    itemBuilder: (context, index) {
                      final session = state.sessions[index];
                      final selected = session.id == widget.activeSessionId;
                      return _SessionTile(
                        session: session,
                        selected: selected,
                        onTap: () => widget.onSelectSession(session.id),
                        onDelete: () => _confirmDelete(session),
                      );
                    },
                  ),
                ),
              ),
            if (state.isLoading && state.sessions.isNotEmpty)
              const LinearProgressIndicator(minHeight: 2),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final AiSessionSummary session;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionTile({
    required this.session,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat.yMMMd().add_jm().format(session.updatedAt);
    return Material(
      color: selected
          ? context.aiPrimary.withValues(alpha: 0.12)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 14,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (session.agentType.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        session.agentType,
                        style: TextStyle(
                          color: context.textSecondary.withValues(alpha: 0.85),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyOrError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _EmptyOrError({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              onRetry != null ? Icons.cloud_off_rounded : Icons.chat_bubble_outline,
              size: 40,
              color: context.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary, height: 1.4),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
