import 'dart:convert';

import 'package:http/http.dart' as http;

void agentDebugLog({
  required String location,
  required String message,
  required String hypothesisId,
  Map<String, Object?> data = const {},
}) {
  // #region agent log
  http
      .post(
        Uri.parse(
          'http://127.0.0.1:7434/ingest/7a3e0f7b-df13-4fca-acf7-f756a04f3b85',
        ),
        headers: {
          'Content-Type': 'application/json',
          'X-Debug-Session-Id': 'd7dcd5',
        },
        body: jsonEncode({
          'sessionId': 'd7dcd5',
          'runId': 'pre-fix',
          'hypothesisId': hypothesisId,
          'location': location,
          'message': message,
          'data': data,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      )
      .catchError((_) => http.Response('', 599));
  // #endregion
}
