import 'dart:async';
import 'package:flutter/material.dart';

enum ImportProcessPhase { idle, busy, syncing, success, error }

/// Theme-aware status strip for Import holdings (Gmail + upload).
/// Busy/syncing modes show a live elapsed `m:ss` timer.
/// Syncing also shows a linear progress capped at [syncTimeout] (default 60s).
class ImportProcessBanner extends StatefulWidget {
  const ImportProcessBanner({
    super.key,
    required this.phase,
    required this.message,
    this.busyStartedAt,
    this.syncTimeout = const Duration(seconds: 60),
    this.actions,
  });

  final ImportProcessPhase phase;
  final String message;
  final DateTime? busyStartedAt;
  final Duration syncTimeout;
  final Widget? actions;

  @override
  State<ImportProcessBanner> createState() => _ImportProcessBannerState();
}

class _ImportProcessBannerState extends State<ImportProcessBanner> {
  Timer? _tick;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant ImportProcessBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase ||
        oldWidget.busyStartedAt != widget.busyStartedAt) {
      _syncTicker();
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  bool get _timedPhase =>
      widget.phase == ImportProcessPhase.busy ||
      widget.phase == ImportProcessPhase.syncing;

  void _syncTicker() {
    _tick?.cancel();
    _tick = null;
    if (_timedPhase && widget.busyStartedAt != null) {
      _elapsed = DateTime.now().difference(widget.busyStartedAt!);
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || widget.busyStartedAt == null) return;
        setState(() {
          _elapsed = DateTime.now().difference(widget.busyStartedAt!);
        });
      });
    } else {
      _elapsed = Duration.zero;
    }
  }

  static String formatElapsed(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color _color(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (widget.phase) {
      case ImportProcessPhase.error:
        return cs.error;
      case ImportProcessPhase.success:
      case ImportProcessPhase.busy:
      case ImportProcessPhase.syncing:
        return cs.primary;
      case ImportProcessPhase.idle:
        return cs.onSurfaceVariant;
    }
  }

  IconData _icon() {
    switch (widget.phase) {
      case ImportProcessPhase.error:
        return Icons.error_outline;
      case ImportProcessPhase.success:
        return Icons.check_circle_outline;
      case ImportProcessPhase.busy:
        return Icons.hourglass_top_outlined;
      case ImportProcessPhase.syncing:
        return Icons.sync_outlined;
      case ImportProcessPhase.idle:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.isEmpty && widget.phase == ImportProcessPhase.idle) {
      return const SizedBox.shrink();
    }
    final color = _color(context);
    final showTimer = _timedPhase && widget.busyStartedAt != null;
    final syncProgress = widget.phase == ImportProcessPhase.syncing
        ? (_elapsed.inMilliseconds / widget.syncTimeout.inMilliseconds)
            .clamp(0.0, 1.0)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (widget.phase == ImportProcessPhase.busy ||
                  widget.phase == ImportProcessPhase.syncing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(_icon(), size: 18, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.message,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    height: 1.25,
                  ),
                ),
              ),
              if (showTimer) ...[
                const SizedBox(width: 8),
                Text(
                  formatElapsed(_elapsed),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
          if (syncProgress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: syncProgress,
                minHeight: 4,
                backgroundColor: color.withValues(alpha: 0.15),
                color: color,
              ),
            ),
          ],
          if (widget.actions != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: widget.actions!,
            ),
          ],
        ],
      ),
    );
  }
}

void showImportSnackBar(
  BuildContext context, {
  required String message,
  required ImportProcessPhase phase,
  Duration duration = const Duration(seconds: 4),
}) {
  if (!context.mounted || message.isEmpty) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  final cs = Theme.of(context).colorScheme;
  Color bg;
  switch (phase) {
    case ImportProcessPhase.error:
      bg = cs.error;
      break;
    case ImportProcessPhase.success:
    case ImportProcessPhase.busy:
    case ImportProcessPhase.syncing:
      bg = cs.primary;
      break;
    case ImportProcessPhase.idle:
      bg = cs.inverseSurface;
      break;
  }

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          if (phase == ImportProcessPhase.busy ||
              phase == ImportProcessPhase.syncing)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else
            Icon(
              phase == ImportProcessPhase.error
                  ? Icons.error_outline
                  : phase == ImportProcessPhase.success
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
              color: Colors.white,
              size: 18,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      duration: phase == ImportProcessPhase.busy ||
              phase == ImportProcessPhase.syncing
          ? const Duration(seconds: 30)
          : duration,
    ),
  );
}

String shortImportError(Object e) {
  final s = e.toString();
  return s
      .replaceFirst(RegExp(r'^Exception:\s*'), '')
      .replaceFirst(RegExp(r'^ApiException:\s*'), '')
      .trim();
}
