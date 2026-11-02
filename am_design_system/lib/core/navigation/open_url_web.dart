import 'dart:js_interop';

@JS('window')
external _BrowserWindow get _window;

extension type _BrowserWindow(JSObject _) implements JSObject {
  external JSObject? open(String url, String target);
}

bool openUrlInNewTab(String url) {
  // Keep the native nullable result: browsers return null when opening is blocked.
  return _window.open(url, '_blank') != null;
}
