// Conditionally export the appropriate implementation
export 'google_signin_service_web.dart' if (dart.library.io) 'google_signin_service_stub.dart';
