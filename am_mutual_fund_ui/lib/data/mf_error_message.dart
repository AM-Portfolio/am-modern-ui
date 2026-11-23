import 'package:dio/dio.dart';

/// Turns Dio / BFF failures into short desk-readable copy (not raw dumps).
String mfErrorMessage(Object error, {String fallback = 'Request failed'}) {
  if (error is DioException) {
    final data = error.response?.data;
    final fromBody = _fromBody(data);
    if (fromBody != null && fromBody.isNotEmpty) return fromBody;
    final status = error.response?.statusCode;
    if (status != null) {
      return switch (status) {
        401 || 403 => 'Not authenticated — sign in again',
        404 => 'Not found',
        409 => fromBody ?? 'Conflict — check idempotency or existing record',
        422 => fromBody ?? 'Invalid request',
        >= 500 => 'MF service error ($status)',
        _ => fromBody ?? 'HTTP $status',
      };
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Timed out talking to MF BFF',
      DioExceptionType.connectionError => 'Cannot reach MF BFF',
      _ => error.message?.isNotEmpty == true ? error.message! : fallback,
    };
  }
  final s = error.toString();
  if (s.startsWith('Exception: ')) return s.substring(11);
  return s;
}

String? _fromBody(Object? data) {
  if (data == null) return null;
  if (data is String && data.trim().isNotEmpty) {
    return data.length > 280 ? '${data.substring(0, 277)}…' : data;
  }
  if (data is Map) {
    for (final key in ['message', 'detail', 'error', 'failure_message']) {
      final v = data[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v is List && v.isNotEmpty) {
        return v.map((e) => e.toString()).join('; ');
      }
      if (v is Map) {
        final nested = _fromBody(v);
        if (nested != null) return nested;
      }
    }
  }
  return null;
}
