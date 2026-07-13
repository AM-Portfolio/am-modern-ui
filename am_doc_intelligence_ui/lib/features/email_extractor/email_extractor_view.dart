/// Platform-safe entry for Email Extractor.
///
/// Web builds use [email_extractor_view_web.dart] (browser APIs / dart:html).
/// Native builds use [email_extractor_view_stub.dart] (unsupported placeholder).
/// Keep this as a conditional export so non-web targets do not import dart:html.
export 'email_extractor_view_stub.dart'
    if (dart.library.html) 'email_extractor_view_web.dart';
