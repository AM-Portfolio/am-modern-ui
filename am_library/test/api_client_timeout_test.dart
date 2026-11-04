import 'dart:async';

import 'package:am_library/core/errors/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isApiTimeoutError', () {
    test('detects TimeoutException', () {
      expect(
        isApiTimeoutError(TimeoutException('GET timed out after 3s')),
        isTrue,
      );
    });

    test('detects ApiException with status 408', () {
      expect(
        isApiTimeoutError(
          ApiException('Request timed out: slow', statusCode: 408),
        ),
        isTrue,
      );
    });

    test('detects wrapped timeout message without status', () {
      expect(
        isApiTimeoutError(
          ApiException('Request timed out: GET timed out after 3s'),
        ),
        isTrue,
      );
    });

    test('does not treat ordinary ApiException as timeout', () {
      expect(
        isApiTimeoutError(ApiException('Unauthorized', statusCode: 401)),
        isFalse,
      );
    });
  });
}
