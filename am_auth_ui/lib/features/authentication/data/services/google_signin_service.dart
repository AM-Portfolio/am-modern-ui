// Conditionally export the platform Google Sign-In implementation.
// Web → GIS / popup flow; IO (Android/iOS) → google_sign_in plugin; else stub.
export 'google_signin_service_stub.dart'
    if (dart.library.html) 'google_signin_service_web.dart'
    if (dart.library.io) 'google_signin_service_io.dart';
