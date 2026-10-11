import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

/// Web: send cookies for BFF / cross-origin session auth.
http.Client createPlatformHttpClient() =>
    BrowserClient()..withCredentials = true;
