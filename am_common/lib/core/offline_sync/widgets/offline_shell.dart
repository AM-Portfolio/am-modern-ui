import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'package:am_design_system/core/theme/color_extensions.dart';

import '../offline_sync_engine.dart';
import '../offline_sync_facade.dart';
import '../offline_sync_providers.dart';
import '../offline_widget_policy.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!GetIt.instance.isRegistered<OfflineSyncEngine>()) {
      return const SizedBox.shrink();
    }
    if (!OfflineSync.readsEnabled) return const SizedBox.shrink();

    final onlineAsync = ref.watch(offlineIsOnlineProvider);
    final pendingAsync = ref.watch(offlinePendingCountProvider);
    final isOnline = onlineAsync.maybeWhen(data: (v) => v, orElse: () => true);
    final pending = pendingAsync.maybeWhen(data: (v) => v, orElse: () => 0);

    if (isOnline && pending == 0) return const SizedBox.shrink();

    final colors = context.colors;
    final label = isOnline
        ? 'Back online · Syncing… Pending $pending'
        : (pending > 0
            ? 'You\'re offline · Pending sync: $pending'
            : 'You\'re offline · Showing saved data');

    return Material(
      color: colors.surface.withValues(alpha: 0.95),
      child: InkWell(
        onTap: onTap,
        child: SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.border.withValues(alpha: 0.6)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isOnline
                      ? Icons.cloud_upload_outlined
                      : Icons.cloud_off_outlined,
                  size: 18,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colors.textPrimary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps a child and hides it when central offline config says so.
class OfflineAware extends ConsumerWidget {
  const OfflineAware({
    super.key,
    required this.widgetId,
    required this.child,
    this.placeholder,
  });

  final OfflineWidgetId widgetId;
  final Widget child;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hide = ref.watch(offlineHideWidgetProvider(widgetId));
    if (hide) {
      return placeholder ?? const SizedBox.shrink();
    }
    return child;
  }
}

class OfflineShell extends ConsumerStatefulWidget {
  const OfflineShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<OfflineShell> createState() => _OfflineShellState();
}

class _OfflineShellState extends ConsumerState<OfflineShell> {
  bool _showOverlay = false;
  bool _checkedOverlay = false;

  @override
  Widget build(BuildContext context) {
    final readsOn = OfflineSync.readsEnabled;
    final onlineAsync = ref.watch(offlineIsOnlineProvider);
    final isOnline = onlineAsync.maybeWhen(data: (v) => v, orElse: () => true);

    if (readsOn && !isOnline && !_checkedOverlay) {
      _checkedOverlay = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!GetIt.instance.isRegistered<OfflineSyncEngine>()) return;
        final engine = GetIt.instance<OfflineSyncEngine>();
        final userId = engine.currentUserId ?? 'anon';
        if (engine.shouldShowOverlayOnce(userId) && mounted) {
          setState(() => _showOverlay = true);
          Future<void>.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _showOverlay = false);
          });
        }
      });
    }

    if (isOnline && _showOverlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _showOverlay) setState(() => _showOverlay = false);
      });
    }

    return Stack(
      children: [
        widget.child,
        if (readsOn)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: OfflineBanner(),
          ),
        if (_showOverlay && readsOn)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.colors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_off_outlined,
                          size: 40,
                          color: context.colors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You\'re offline',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Showing saved data',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: context.colors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
