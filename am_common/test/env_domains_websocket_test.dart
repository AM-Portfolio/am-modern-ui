import 'package:flutter_test/flutter_test.dart';
import 'package:am_common/core/config/env_domains.dart';

void main() {
  test('default STOMP endpoint uses the gateway module prefix', () {
    final uri = Uri.parse(EnvDomains.wsStream);

    expect(uri.path, endsWith('/gateway/v1/streams'));
  });
}
