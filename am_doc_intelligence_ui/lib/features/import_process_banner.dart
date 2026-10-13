import 'dart:async';
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

enum ImportProcessPhase { idle, busy, success, error }

/// Theme-aware status strip for Import holdings (Gmail + upload).
/// Busy mode shows a live elapsed `m:ss` timer.
class ImportProcessBanner extends StatefulWidget {
  const ImportProcessBanner({
    super.key,
    required this.phase,
    required this.message,
    this.busyStartedAt,
  });

  final ImportProcessPhase phase;
  final String message;
  /// When [phase] is busy, elapsed time is computed from this instant.
  final DateTime? busyStartedAt;

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

  void _syncTicker() {
    _tick?.cancel();
    _tick = null;
    if (widget.phase == ImportProcessPhase.busy &&
        widget.busyStartedAt != null) {
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
        return const Color(0xFF12B76A);
      case ImportProcessPhase.busy:
        return ModuleColors.analytics;
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
    final showTimer =
        widget.phase == ImportProcessPhase.busy && widget.busyStartedAt != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          if (widget.phase == ImportProcessPhase.busy)
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
    );
  }
}

/// Floating SnackBar helpers for import flows (theme-aware).
void showImportSnackBar(
  BuildContext context, {
  required String message,
  required ImportProcessPhase phase,
  Duration duration = const Duration(seconds: 4),
}) {
  if (!context.mounted || message.isEmpty) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  Color bg;
  switch (phase) {
    case ImportProcessPhase.error:
      bg = Theme.of(context).colorScheme.error;
      break;
    case ImportProcessPhase.success:
      bg = const Color(0xFF12B76A);
      break;
    case ImportProcessPhase.busy:
      bg = ModuleColors.analytics;
      break;
    case ImportProcessPhase.idle:
      bg = Theme.of(context).colorScheme.inverseSurface;
      break;
  }

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          if (phase == ImportProcessPhase.busy)
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
      duration: phase == ImportProcessPhase.busy
          ? const Duration(seconds: 30)
          : duration,
    ),
  );
}

String shortImportError(Object e) {
  final s = e.toString();
  // Strip common Exception prefixes for UI.
  return s
      .replaceFirst(RegExp(r'^Exception:\s*'), '')
      .replaceFirst(RegExp(r'^ApiException:\s*'), '')
      .trim();
}
