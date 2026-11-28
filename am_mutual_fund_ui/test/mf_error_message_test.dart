import 'package:am_mutual_fund_ui/data/mf_error_message.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('connectionError with CORS dump becomes short desk copy', () {
    final err = DioException(
      requestOptions: RequestOptions(path: '/v1/mf/schemes/X'),
      type: DioExceptionType.connectionError,
      message:
          'The XMLHttpRequest onError callback was called. This typically '
          'indicates an error on the network layer. If this is a cross-origin '
          'request, the browser may have blocked it because of CORS.',
    );
    final msg = mfErrorMessage(err);
    expect(msg.toLowerCase(), contains('cannot reach mf bff'));
    expect(msg.toLowerCase(), contains('cors'));
    expect(msg.length, lessThan(120));
  });

  test('plain connectionError stays short', () {
    final err = DioException(
      requestOptions: RequestOptions(path: '/v1/mf/schemes'),
      type: DioExceptionType.connectionError,
      message: 'Connection refused',
    );
    expect(mfErrorMessage(err), 'Cannot reach MF BFF');
  });
}
