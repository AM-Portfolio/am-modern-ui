import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'open_url_stub.dart' if (dart.library.html) 'open_url_web.dart';

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

  static bool shouldOpenNewTab({PointerDownEvent? pointerDown}) {
    if (pointerDown != null && pointerDown.buttons == kMiddleMouseButton) {
      return true;
    }
    return HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
  }

  static void navigate({
    required BuildContext context,
    required String path,
    required VoidCallback onSameTab,
    PointerDownEvent? pointerDown,
  }) {
    if (kIsWeb && shouldOpenNewTab(pointerDown: pointerDown)) {
      openUrlInNewTab(fullUrlForPath(path));
      return;
    }
    onSameTab();
  }
}
