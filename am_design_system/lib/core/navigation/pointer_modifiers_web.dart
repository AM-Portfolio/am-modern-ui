import 'dart:js_interop';

@JS('window')
external _BrowserWindow get _window;

extension type _BrowserWindow(JSObject _) implements JSObject {
  external void addEventListener(
      String type, JSFunction listener, bool capture);
  external void removeEventListener(
      String type, JSFunction listener, bool capture);
}

extension type _PointerEvent(JSObject _) implements JSObject {
  external bool? get ctrlKey;
  external bool? get metaKey;
}

int _users = 0;
bool _modified = false;

// Capture runs before Flutter dispatches the corresponding pointer event.
// Guarded against undefined properties or non-mouse events (e.g. touch emulation).
final _onPointerDown = ((JSAny? raw) {
  try {
    if (raw != null && raw is JSObject) {
      final event = _PointerEvent(raw);
      _modified = (event.ctrlKey == true) || (event.metaKey == true);
    } else {
      _modified = false;
    }
  } catch (_) {
    _modified = false;
  }
}).toJS;

final _onBlur = ((JSAny? event) {
  _modified = false;
}).toJS;

void retainPointerModifiers() {
  try {
    if (_users++ != 0) return;
    _window.addEventListener('pointerdown', _onPointerDown, true);
    _window.addEventListener('blur', _onBlur, true);
  } catch (_) {}
}

void releasePointerModifiers() {
  try {
    if (_users <= 0) {
      _users = 0;
      return;
    }
    if (--_users != 0) return;
    _window.removeEventListener('pointerdown', _onPointerDown, true);
    _window.removeEventListener('blur', _onBlur, true);
    _modified = false;
  } catch (_) {
    _modified = false;
  }
}

bool get pointerRequestsNewTab {
  try {
    return _modified;
  } catch (_) {
    return false;
  }
}
