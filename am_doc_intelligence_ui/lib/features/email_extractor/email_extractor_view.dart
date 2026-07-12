// Conditionally export the appropriate implementation
export 'email_extractor_view_stub.dart'
    if (dart.library.html) 'email_extractor_view_web.dart';
