part of 'app_shell.dart';

/// Global sidebar "+ Sync" quick actions → [GlobalAddActionsBus].
mixin ShellGlobalAdd on State<AppShell> {
  // Satisfied by [ShellNav] on the same State.
  String get _currentLocation;

  List<FloatingMenuAction> _globalAddActions(BuildContext context) {
    return buildGlobalAddMenuActions(
      (kind) => _requestGlobalAdd(context, kind),
    );
  }

  void _requestGlobalAdd(
    BuildContext context,
    common.GlobalAddActionKind kind,
  ) {
    requestGlobalAddAction(
      context,
      kind: kind,
      currentLocation: _currentLocation,
    );
  }
}
