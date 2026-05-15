import 'package:flutter_test/flutter_test.dart';

import 'package:am_library/am_library.dart';

void main() {
  test('generates W3C traceparent headers', () {
    final context = TraceContext.generate();

    expect(context.traceId, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(context.spanId, matches(RegExp(r'^[0-9a-f]{16}$')));
    expect(
      context.traceparent,
      matches(RegExp(r'^00-[0-9a-f]{32}-[0-9a-f]{16}-01$')),
    );
  });
}
