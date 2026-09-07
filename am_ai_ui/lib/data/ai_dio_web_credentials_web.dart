import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

/// Ensures cookie sessions work on web (normal + incognito) for AI APIs.
///
/// Always replace [Dio.options.extra] with a mutable copy — BaseOptions may
/// hand an unmodifiable/const map (Flutter web), and writing into it throws
/// `Unsupported operation: Cannot modify unmodifiable Map`, which kills the
/// Riverpod provider (history / usage / chat).
void configureAiWebCredentials(Dio dio) {
  dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
  dio.options.extra = Map<String, dynamic>.from(dio.options.extra)
    ..['withCredentials'] = true;
}
