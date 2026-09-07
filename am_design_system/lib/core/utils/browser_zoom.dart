/// Pure zoom math. Safe in unit tests (no dart:html).
import 'dart:ui' show Size;

class BrowserZoomMath {
  BrowserZoomMath._();

  static const String storageKey = 'am_ui_zoom';

  /// Chrome-like steps (67% … 200%).
  static const List<double> steps = [
    0.67,
    0.75,
    0.80,
    0.90,
    1.0,
    1.10,
    1.25,
    1.50,
    1.75,
    2.0,
  ];

  static const double minZoom = 0.67;
  static const double maxZoom = 2.0;

  static double clampZoom(double zoom) => zoom.clamp(minZoom, maxZoom);

  static double nearestStep(double zoom) {
    var best = steps.first;
    var bestDist = (zoom - best).abs();
    for (final step in steps) {
      final dist = (zoom - step).abs();
      if (dist < bestDist) {
        best = step;
        bestDist = dist;
      }
    }
    return best;
  }

  static double nextStep(double zoom) {
    for (final step in steps) {
      if (step > zoom + 0.001) return step;
    }
    return maxZoom;
  }

  static double prevStep(double zoom) {
    for (final step in steps.reversed) {
      if (step < zoom - 0.001) return step;
    }
    return minZoom;
  }

  /// Detect Chrome page zoom. OS display scale must not count as zoom.
  ///
  /// [outerWidth] / [innerWidth] is used when it clearly leaves the 100% band
  /// (window chrome makes the ratio ~1.0–1.08 at 100%). Otherwise DPR vs
  /// [baselineDpr] (captured at first sample) is used.
  static double detectChromeZoom({
    required double innerWidth,
    required double outerWidth,
    required double devicePixelRatio,
    required double baselineDpr,
  }) {
    if (innerWidth <= 0) return 1.0;
    try {
      final fromOuter = outerWidth > 0 ? outerWidth / innerWidth : 1.0;
      final base = baselineDpr <= 0 ? devicePixelRatio : baselineDpr;
      final fromDpr = (base <= 0) ? 1.0 : devicePixelRatio / base;
      if (fromOuter < 0.97 || fromOuter > 1.08) {
        return clampZoom(fromOuter);
      }
      return clampZoom(fromDpr);
    } catch (_) {
      return 1.0;
    }
  }

  static double layoutWidth(double cssWidth, double chromeZoom) =>
      cssWidth * chromeZoom;

  static double layoutHeight(double cssHeight, double chromeZoom) =>
      cssHeight * chromeZoom;

  /// In-app page scale after Chrome already applied its own zoom.
  static double pageScale({
    required double appZoom,
    required double chromeZoom,
  }) {
    if (chromeZoom <= 0) return appZoom;
    return (appZoom / chromeZoom).clamp(0.5, 3.0);
  }

  /// Layout size for a full-page [Transform]/[FittedBox] at [pageScale].
  static Size pageLayoutSize(Size view, double pageScale) {
    if (pageScale <= 0) return view;
    return Size(view.width / pageScale, view.height / pageScale);
  }

  /// Visual text scale after Chrome already painted CSS pixels larger.
  static double textScale({
    required double appZoom,
    required double chromeZoom,
  }) =>
      pageScale(appZoom: appZoom, chromeZoom: chromeZoom);

  static double? parseStored(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final value = double.tryParse(raw);
    if (value == null) return null;
    return clampZoom(value);
  }

  static int percent(double zoom) => (zoom * 100).round();
}

/// Snapshot of browser viewport metrics used to detect zoom.
class BrowserZoomMetrics {
  const BrowserZoomMetrics({
    required this.innerWidth,
    required this.innerHeight,
    required this.outerWidth,
    required this.devicePixelRatio,
  });

  final double innerWidth;
  final double innerHeight;
  final double outerWidth;
  final double devicePixelRatio;
}
