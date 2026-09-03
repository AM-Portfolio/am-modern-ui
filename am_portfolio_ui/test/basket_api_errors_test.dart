import 'package:flutter_test/flutter_test.dart';
import 'package:am_common/am_common.dart';
import 'package:am_portfolio_ui/features/basket/presentation/utils/basket_api_errors.dart';

void main() {
  group('basketApiErrorMessage', () {
    test('maps 404 ETF not found', () {
      expect(
        basketApiErrorMessage(ApiException('gone', statusCode: 404)),
        'ETF not found — please pick another theme.',
      );
    });

    test('maps 401 and 403 as session expired', () {
      expect(
        basketApiErrorMessage(ApiException('nope', statusCode: 401)),
        'Session expired. Please log in again.',
      );
      expect(
        basketApiErrorMessage(ApiException('nope', statusCode: 403)),
        'Session expired. Please log in again.',
      );
    });

    test('maps 408/504 as slow market data', () {
      expect(
        basketApiErrorMessage(ApiException('slow', statusCode: 408)),
        'Market data is slow. Showing last known prices if available.',
      );
      expect(
        basketApiErrorMessage(ApiException('slow', statusCode: 504)),
        'Market data is slow. Showing last known prices if available.',
      );
    });

    test('maps 5xx as retry', () {
      expect(
        basketApiErrorMessage(ApiException('boom', statusCode: 500)),
        'Something went wrong on our end. Please retry.',
      );
    });

    test('maps DRAFT_LIMIT_REACHED from errorCode data', () {
      expect(
        basketApiErrorMessage(ApiException(
          'Maximum of 5 basket drafts reached.',
          statusCode: 409,
          data: {'errorCode': 'DRAFT_LIMIT_REACHED'},
        )),
        'Maximum of 5 basket drafts reached.',
      );
      expect(
        basketApiErrorCode(ApiException(
          'x',
          statusCode: 409,
          data: {'errorCode': 'DRAFT_LIMIT_REACHED'},
        )),
        'DRAFT_LIMIT_REACHED',
      );
    });
  });
}
