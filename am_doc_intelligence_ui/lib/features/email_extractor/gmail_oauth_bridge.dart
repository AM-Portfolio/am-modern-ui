/// Platform Gmail OAuth open + optional popup message bridge.
///
/// Web: popup + `postMessage` (`am-gmail-oauth`).
/// Native: external browser via `url_launcher`; status polling detects connect.
export 'gmail_oauth_bridge_io.dart'
    if (dart.library.html) 'gmail_oauth_bridge_web.dart';
