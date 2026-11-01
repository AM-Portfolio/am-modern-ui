import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;

import 'open_url_stub.dart' if (dart.library.html) 'open_url_web.dart';
import 'pointer_modifiers_stub.dart'
    if (dart.library.html) 'pointer_modifiers_web.dart' as modifiers;

/// Web-aware navigation: same-tab GoRouter vs new browser tab (Ctrl/Cmd/middle-click).
class AppWebNavigation {
  AppWebNavigation._();

  static String fullUrlForPath(String path) {
    final base = Uri.base;
    if (base.hasScheme && base.host.isNotEmpty) {
      return base.replace(path: path, query: '', fragment: '').toString();
    }
    return path;
  }

  /// Always open [path] in a new browser tab (web only). No-op off web.
  static void openPathInNewTab(String path) {
    if (!kIsWeb) return;
    final uri = Uri.parse(path);
    final base = Uri.base;
    final full = base
        .replace(
          path: uri.path.isEmpty ? path : uri.path,
          query: uri.hasQuery ? uri.query : '',
          fragment: '',
        )
        .toString();
    // Prefer preserving query from relative path like /app/chart/workspace?symbol=...
    final withQuery = path.contains('?')
        ? '${base.origin}${path.startsWith('/') ? path : '/$path'}'
        : full;
    openUrlInNewTab(withQuery);
  }

  static bool shouldOpenNewTab({
    PointerDownEvent? pointerDown,
    bool modified = false,
  }) {
    if (pointerDown != null && pointerDown.buttons == kMiddleMouseButton) {
      return true;
    }
    return modified;
  }

  static void navigate({
    required BuildContext context,
    required String path,
    required VoidCallback onSameTab,
    PointerDownEvent? pointerDown,
    bool modified = false,
  }) {
    dispatch(
      openInNewTab: kIsWeb &&
          shouldOpenNewTab(pointerDown: pointerDown, modified: modified),
      path: path,
      onSameTab: onSameTab,
      openNewTab: openUrlInNewTab,
    );
  }

  static void dispatch({
    required bool openInNewTab,
    required String path,
    required VoidCallback onSameTab,
    required bool Function(String) openNewTab,
  }) {
    if (openInNewTab) {
      try {
        if (openNewTab(fullUrlForPath(path))) return;
      } catch (_) {
        // A failed browser open must not swallow navigation.
      }
    }
    onSameTab();
  }
}

/// Captures click intent independently of Flutter's persistent keyboard state.
class AppNavigationGesture extends StatefulWidget {
  const AppNavigationGesture({
    required this.path,
    required this.onSameTab,
    required this.child,
    this.onLongPress,
    this.behavior = HitTestBehavior.opaque,
    super.key,
  });

  final String? path;
  final VoidCallback onSameTab;
  final VoidCallback? onLongPress;
  final HitTestBehavior behavior;
  final Widget child;

  @override
  State<AppNavigationGesture> createState() => _AppNavigationGestureState();
}

class _AppNavigationGestureState extends State<AppNavigationGesture> {
  bool _modified = false;

  @override
  void initState() {
    super.initState();
    modifiers.retainPointerModifiers();
  }

  @override
  void dispose() {
    modifiers.releasePointerModifiers();
    super.dispose();
  }

  void _navigate({PointerDownEvent? pointerDown}) {
    final modified = _modified;
    _modified = false;
    final path = widget.path;
    if (path == null) {
      widget.onSameTab();
      return;
    }
    AppWebNavigation.navigate(
      context: context,
      path: path,
      onSameTab: widget.onSameTab,
      pointerDown: pointerDown,
      modified: modified,
    );
  }

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            _modified = false;
            _navigate();
            return null;
          }),
        },
        child: Listener(
          onPointerDown: (event) {
            _modified = event.kind == PointerDeviceKind.mouse &&
                modifiers.pointerRequestsNewTab;
            if (event.buttons == kMiddleMouseButton && widget.path != null) {
              _navigate(pointerDown: event);
            }
          },
          onPointerCancel: (_) => _modified = false,
          child: GestureDetector(
            behavior: widget.behavior,
            onTap: _navigate,
            onTapCancel: () => _modified = false,
            onLongPress: widget.onLongPress == null
                ? null
                : () {
                    _modified = false;
                    widget.onLongPress!();
                  },
            child: widget.child,
          ),
        ),
      );
}
