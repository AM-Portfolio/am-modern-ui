import 'package:http/http.dart' as http;

/// Default HTTP client (IO / non-web).
http.Client createPlatformHttpClient() => http.Client();
