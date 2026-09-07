import 'package:dio/dio.dart';

/// Maps Dio / session-API failures to short drawer copy.
String aiSessionFriendlyError(Object e) {
  if (e is DioException) {
    final code = e.response?.statusCode;
    if (code == 401 || code == 403) {
      return 'Sign in again to load chat history.';
    }
    // List endpoint 404 usually means gateway/session routes are not deployed.
    final path = e.requestOptions.path;
    if (code == 404) {
      if (path.contains('/sessions/') && !path.endsWith('/sessions')) {
        return 'Session not found.';
      }
      return 'Chat history is unavailable. The AI gateway may be missing session routes.';
    }
    if (code == 502 || code == 503) {
      return 'Chat history service is temporarily unavailable.';
    }
    return e.message ?? 'Could not reach chat history.';
  }
  return e.toString();
}
