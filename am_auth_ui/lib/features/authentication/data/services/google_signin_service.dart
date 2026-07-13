// Conditionally export the appropriate implementation
export 'google_signin_service_stub.dart'
    if (dart.library.html) 'google_signin_service_web.dart';
