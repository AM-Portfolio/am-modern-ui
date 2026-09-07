import 'package:am_ai_ui/data/ai_session_errors.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('aiSessionFriendlyError', () {
    test('list sessions 404 is not phrased as Session not found', () {
      final err = DioException(
        requestOptions: RequestOptions(path: 'v1/ai/sessions'),
        response: Response(
          requestOptions: RequestOptions(path: 'v1/ai/sessions'),
          statusCode: 404,
        ),
        type: DioExceptionType.badResponse,
      );
      expect(aiSessionFriendlyError(err), contains('unavailable'));
      expect(aiSessionFriendlyError(err), isNot(contains('Session not found')));
    });

    test('get session 404 stays Session not found', () {
      const path = 'v1/ai/sessions/abc-123';
      final err = DioException(
        requestOptions: RequestOptions(path: path),
        response: Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 404,
        ),
        type: DioExceptionType.badResponse,
      );
      expect(aiSessionFriendlyError(err), 'Session not found.');
    });
  });
}
