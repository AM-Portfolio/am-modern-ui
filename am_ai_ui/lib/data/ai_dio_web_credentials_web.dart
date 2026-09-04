import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

/// Ensures cookie sessions work on web (normal + incognito) for AI APIs.
void configureAiWebCredentials(Dio dio) {
  dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
  dio.options.extra['withCredentials'] = true;
}
