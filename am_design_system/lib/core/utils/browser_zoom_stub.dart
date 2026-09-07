import 'browser_zoom.dart';

/// Non-web: no browser zoom APIs.
class BrowserZoomPlatform {
  BrowserZoomPlatform._();

  static BrowserZoomMetrics? readMetrics() => null;

  static String? readStoredZoom() => null;

  static void writeStoredZoom(String value) {}

  static void listen(
    void Function() onChange, {
    bool Function()? blockBrowserCtrlWheel,
  }) {}

  static void unlisten() {}
}
