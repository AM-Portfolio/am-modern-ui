import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads persisted dashboard layout once per [userId].
class DashboardLayoutBootstrap extends ConsumerStatefulWidget {
  const DashboardLayoutBootstrap({
    super.key,
    required this.userId,
    required this.child,
  });

  final String userId;
  final Widget child;

  @override
  ConsumerState<DashboardLayoutBootstrap> createState() =>
      _DashboardLayoutBootstrapState();
}

class _DashboardLayoutBootstrapState
    extends ConsumerState<DashboardLayoutBootstrap> {
  String? _loadedForUser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureLoaded();
  }

  @override
  void didUpdateWidget(covariant DashboardLayoutBootstrap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loadedForUser = null;
      _ensureLoaded();
    }
  }

  void _ensureLoaded() {
    if (_loadedForUser == widget.userId) return;
    _loadedForUser = widget.userId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(dashboardLayoutProvider.notifier).reloadForUser(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
