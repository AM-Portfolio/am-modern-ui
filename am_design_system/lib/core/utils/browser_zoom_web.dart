import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'browser_zoom.dart';

/// Web: window metrics. Chrome/Brave own Ctrl+/− zoom (address-bar %).
class BrowserZoomPlatform {
  BrowserZoomPlatform._();

  static final List<StreamSubscription<html.Event>> _subs = [];
  static bool Function()? _blockBrowserCtrlWheel;
  static Object? _wheelListener;

  static BrowserZoomMetrics? readMetrics() {
    try {
      final innerW = (html.window.innerWidth ?? 0).toDouble();
      final innerH = (html.window.innerHeight ?? 0).toDouble();
      if (innerW <= 0) return null;
      return BrowserZoomMetrics(
        innerWidth: innerW,
        innerHeight: innerH,
        outerWidth: (html.window.outerWidth ?? innerW).toDouble(),
        devicePixelRatio: html.window.devicePixelRatio.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  static String? readStoredZoom() {
    try {
      return html.window.localStorage[BrowserZoomMath.storageKey];
    } catch (_) {
      return null;
    }
  }

  static void writeStoredZoom(String value) {
    try {
      html.window.localStorage[BrowserZoomMath.storageKey] = value;
    } catch (_) {}
  }

  static void listen(
    void Function() onChange, {
    bool Function()? blockBrowserCtrlWheel,
  }) {
    unlisten();
    _blockBrowserCtrlWheel = blockBrowserCtrlWheel;
    _subs.add(html.window.onResize.listen((_) => onChange()));
    try {
      final viewport = html.window.visualViewport;
      if (viewport != null) {
        _subs.add(viewport.onResize.listen((_) => onChange()));
        _subs.add(viewport.onScroll.listen((_) => onChange()));
      }
    } catch (_) {}
    _attachChartWheelGuard();
  }

  /// Let the browser zoom everywhere except over charts (Ctrl+wheel).
  static void _attachChartWheelGuard() {
    _wheelListener = js_util.allowInterop((dynamic raw) {
      try {
        final e = raw as html.WheelEvent;
        if (!(e.ctrlKey || e.metaKey)) return;
        if (_blockBrowserCtrlWheel?.call() != true) return;
        e.preventDefault();
      } catch (_) {}
    });
    js_util.callMethod(html.window, 'addEventListener', [
      'wheel',
      _wheelListener,
      js_util.jsify({'capture': true, 'passive': false}),
    ]);
  }

  static void unlisten() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    _blockBrowserCtrlWheel = null;
    if (_wheelListener != null) {
      try {
        js_util.callMethod(html.window, 'removeEventListener', [
          'wheel',
          _wheelListener,
          true,
        ]);
      } catch (_) {}
      _wheelListener = null;
    }
  }
}
