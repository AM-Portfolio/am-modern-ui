import 'dart:convert';

import 'package:http/http.dart' as http;

void agentDebugLog({
  required String location,
  required String message,
  required String hypothesisId,
  Map<String, Object?> data = const {},
}) {
  // Empty - removed hardcoded 127.0.0.1 test telemetry.
}
