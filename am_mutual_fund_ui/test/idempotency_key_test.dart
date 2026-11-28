import 'package:am_mutual_fund_ui/data/mf_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('newIdempotencyKey returns unique non-empty UUIDs', () {
    final a = MfApiClient.newIdempotencyKey();
    final b = MfApiClient.newIdempotencyKey();
    expect(a, isNotEmpty);
    expect(b, isNotEmpty);
    expect(a, isNot(b));
  });
}
