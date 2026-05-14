import 'dart:math';

/// Generates W3C Trace Context headers for outbound HTTP requests.
class TraceContext {
  TraceContext._({
    required this.traceId,
    required this.spanId,
  });

  final String traceId;
  final String spanId;

  String get traceparent => '00-$traceId-$spanId-01';

  static final Random _random = Random.secure();

  static TraceContext generate() {
    return TraceContext._(
      traceId: _randomHex(16),
      spanId: _randomHex(8),
    );
  }

  static String _randomHex(int byteCount) {
    final buffer = StringBuffer();
    for (var i = 0; i < byteCount; i++) {
      buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
