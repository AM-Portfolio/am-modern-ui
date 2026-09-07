import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/utils/browser_zoom.dart';
import '../../../core/utils/browser_zoom_platform.dart';
import '../../../core/utils/common_logger.dart';
import 'app_zoom_scroll_guard.dart';

/// Snapshot exposed to tests and layout breakpoints.
class BrowserZoomData {
  const BrowserZoomData({
    required this.chromeZoom,
    required this.layoutSize,
  });

  final double chromeZoom;
  final Size layoutSize;

  int get percent => BrowserZoomMath.percent(chromeZoom);
}

class _BrowserZoomScope extends InheritedWidget {
  const _BrowserZoomScope({
    required this.data,
    required super.child,
  });

  final BrowserZoomData data;

  @override
  bool updateShouldNotify(_BrowserZoomScope oldWidget) {
    return data.chromeZoom != oldWidget.data.chromeZoom ||
        data.layoutSize != oldWidget.data.layoutSize;
  }
}

/// Unzoomed width for chrome breakpoints (sidebar / desktop vs mobile).
class BrowserZoomScope {
  BrowserZoomScope._();

  static BrowserZoomData? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_BrowserZoomScope>()
        ?.data;
  }

  /// Layout width as if Chrome zoom were 100%. Falls back to CSS size.
  static double layoutWidthOf(BuildContext context) {
    return maybeOf(context)?.layoutSize.width ??
        MediaQuery.sizeOf(context).width;
  }

  static double layoutHeightOf(BuildContext context) {
    return maybeOf(context)?.layoutSize.height ??
        MediaQuery.sizeOf(context).height;
  }
}

/// Re-reads Chrome zoom on resize/maximize and keeps desktop chrome from
/// collapsing. Does not intercept Ctrl+/− — the browser owns zoom and the
/// address-bar percent indicator.
class BrowserZoomHost extends StatefulWidget {
  const BrowserZoomHost({
    required this.child,
    super.key,
    this.metricsReader,
    this.listenToPlatform = true,
  });

  final Widget child;

  /// Test seam. Null → [BrowserZoomPlatform.readMetrics].
  final BrowserZoomMetrics Function()? metricsReader;
  final bool listenToPlatform;

  @override
  State<BrowserZoomHost> createState() => _BrowserZoomHostState();
}

class _BrowserZoomHostState extends State<BrowserZoomHost>
    with WidgetsBindingObserver {
  static const _debounce = Duration(milliseconds: 50);

  double _baselineDpr = 0;
  double _chromeZoom = 1.0;
  Size _cssSize = Size.zero;
  Timer? _debounceTimer;
  double? _lastLoggedChrome;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sample(notify: false);
    if (widget.listenToPlatform) {
      BrowserZoomPlatform.listen(
        _onPlatformChange,
        blockBrowserCtrlWheel: () => AppZoomPointer.overChart,
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (widget.listenToPlatform) {
      BrowserZoomPlatform.unlisten();
    }
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _onPlatformChange();
  }

  void _onPlatformChange() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      if (!mounted) return;
      _sample(notify: true);
    });
  }

  BrowserZoomMetrics? _readMetrics() {
    if (widget.metricsReader != null) return widget.metricsReader!();
    return BrowserZoomPlatform.readMetrics();
  }

  void _sample({bool notify = true}) {
    final metrics = _readMetrics();
    double chrome = _chromeZoom;
    Size css = _cssSize;

    if (metrics != null) {
      if (_baselineDpr <= 0) {
        _baselineDpr = metrics.devicePixelRatio <= 0
            ? 1.0
            : metrics.devicePixelRatio;
      }
      chrome = BrowserZoomMath.detectChromeZoom(
        innerWidth: metrics.innerWidth,
        outerWidth: metrics.outerWidth,
        devicePixelRatio: metrics.devicePixelRatio,
        baselineDpr: _baselineDpr,
      );
      css = Size(metrics.innerWidth, metrics.innerHeight);
    } else {
      final mq = WidgetsBinding.instance.platformDispatcher.views.isEmpty
          ? null
          : WidgetsBinding.instance.platformDispatcher.views.first;
      if (mq != null) {
        final dpr = mq.devicePixelRatio;
        css = mq.physicalSize / dpr;
      }
    }

    final chromeLog = (chrome * 100).round() / 100;
    if (_lastLoggedChrome != chromeLog || css != _cssSize) {
      _lastLoggedChrome = chromeLog;
      CommonLogger.debug(
        'zoom chrome=$chromeLog css=${css.width.toStringAsFixed(0)}x${css.height.toStringAsFixed(0)}',
        tag: 'BrowserZoom',
      );
    }

    if (chrome == _chromeZoom && css == _cssSize) {
      return;
    }

    if (!notify) {
      _chromeZoom = chrome;
      _cssSize = css;
      return;
    }
    if (!mounted) return;
    setState(() {
      _chromeZoom = chrome;
      _cssSize = css;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final css = _cssSize == Size.zero ? mq.size : _cssSize;
    final layout = Size(
      BrowserZoomMath.layoutWidth(css.width, _chromeZoom),
      BrowserZoomMath.layoutHeight(css.height, _chromeZoom),
    );
    final data = BrowserZoomData(
      chromeZoom: _chromeZoom,
      layoutSize: layout,
    );

    return _BrowserZoomScope(
      data: data,
      child: widget.child,
    );
  }
}
