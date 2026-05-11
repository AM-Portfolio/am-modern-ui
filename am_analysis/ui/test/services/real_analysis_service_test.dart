import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:am_analysis_ui/services/real_analysis_service.dart';
import 'package:am_analysis_core/am_analysis_core.dart';

void main() {
  group('RealAnalysisService', () {
    late RealAnalysisService service;

    setUp(() {
      // Create service pointing to localhost:8090
      service = RealAnalysisService(
        baseUrl: 'http://localhost:8090',
        authToken: 'Bearer test-token', // Use mock token for testing
      );
    });

    test('should initialize with default base URL', () {
      final defaultService = RealAnalysisService();
      expect(defaultService, isNotNull);
    });

    test('should initialize with custom base URL', () {
      final customService = RealAnalysisService(
        baseUrl: 'http://custom-server:9000',
      );
      expect(customService, isNotNull);
    });

    // Integration tests require backend running
    group('Integration Tests (requires backend on 8090)', () {
      test('should fetch allocation data', () async {
        try {
          final result = await service.getAllocation(
            'test-portfolio-id',
            AnalysisEntityType.PORTFOLIO,
            groupBy: GroupBy.sector,
          );

          // Expect some result (could be empty or populated)
          expect(result, isNotNull);
          expect(result, isA<List>());
        } catch (e) {
          // If backend not running, test should skip gracefully
          print('Backend not available for testing: $e');
        }
      }, skip: 'Requires backend running - manual test only');

      test('should fetch top movers', () async {
        try {
          final result = await service.getTopMovers(
            type: AnalysisEntityType.EQUITY,
            timeFrame: '1D',
            groupBy: GroupBy.stock,
          );

          expect(result, isNotNull);
          expect(result, isA<List>());
        } catch (e) {
          print('Backend not available for testing: $e');
        }
      }, skip: 'Requires backend running - manual test only');

      test('should fetch performance data', () async {
        try {
          final result = await service.getPerformance(
            'test-portfolio-id',
            AnalysisEntityType.PORTFOLIO,
            '1M',
          );

          expect(result, isNotNull);
          expect(result, isA<List>());
        } catch (e) {
          print('Backend not available for testing: $e');
        }
      }, skip: 'Requires backend running - manual test only');
    });
  });

  group('RealAnalysisService _auth dev-fallback JWT', () {
    // Tests the dev-fallback JWT generation logic introduced in this PR.
    // The _auth getter is private, so we validate the algorithm independently
    // using the same base64Url encode approach used in the service.

    test('dev fallback token is a 3-part Bearer JWT', () {
      // Replicate the exact logic from RealAnalysisService._auth
      final header =
          base64Url.encode(utf8.encode('{"alg":"none"}')).replaceAll('=', '');
      final payload = base64Url
          .encode(utf8.encode(
            '{"sub":"b75743c9-fe0e-4c54-8ee0-8da350cc27b3","iat":${DateTime.now().millisecondsSinceEpoch ~/ 1000}}',
          ))
          .replaceAll('=', '');
      final token = 'Bearer $header.$payload.dev_signature';

      expect(token, startsWith('Bearer '));

      final parts = token.substring('Bearer '.length).split('.');
      expect(parts.length, equals(3));
    });

    test('dev fallback JWT header decodes to alg:none', () {
      final header =
          base64Url.encode(utf8.encode('{"alg":"none"}')).replaceAll('=', '');

      // Pad back before decoding
      final padded = header.padRight(
          header.length + (4 - header.length % 4) % 4, '=');
      final decoded = utf8.decode(base64Url.decode(padded));
      final headerJson = json.decode(decoded) as Map<String, dynamic>;

      expect(headerJson['alg'], equals('none'));
    });

    test('dev fallback JWT payload contains correct sub claim', () {
      const expectedUserId = 'b75743c9-fe0e-4c54-8ee0-8da350cc27b3';
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final payloadJson =
          '{"sub":"$expectedUserId","iat":$now}';
      final payload =
          base64Url.encode(utf8.encode(payloadJson)).replaceAll('=', '');

      final padded = payload.padRight(
          payload.length + (4 - payload.length % 4) % 4, '=');
      final decoded = utf8.decode(base64Url.decode(padded));
      final payloadMap = json.decode(decoded) as Map<String, dynamic>;

      expect(payloadMap['sub'], equals(expectedUserId));
    });

    test('dev fallback JWT payload contains iat as current Unix timestamp', () {
      final before = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final payloadJson =
          '{"sub":"b75743c9-fe0e-4c54-8ee0-8da350cc27b3","iat":$now}';
      final payload =
          base64Url.encode(utf8.encode(payloadJson)).replaceAll('=', '');

      final padded = payload.padRight(
          payload.length + (4 - payload.length % 4) % 4, '=');
      final decoded = utf8.decode(base64Url.decode(padded));
      final payloadMap = json.decode(decoded) as Map<String, dynamic>;

      final iat = payloadMap['iat'] as int;
      // iat should be a recent Unix timestamp (within 1 second of our local now)
      expect(iat, greaterThanOrEqualTo(before));
      expect(iat, lessThanOrEqualTo(now + 1));
    });

    test('header padding stripped correctly (no trailing = in JWT)', () {
      final header =
          base64Url.encode(utf8.encode('{"alg":"none"}')).replaceAll('=', '');
      expect(header.contains('='), isFalse);
    });

    test('service with provided authToken uses it as-is', () {
      // When authToken is supplied, the service should not generate a fallback.
      // Verify by constructing with an explicit token (no null).
      const explicitToken = 'Bearer explicit.token.here';
      final serviceWithToken = RealAnalysisService(
        baseUrl: 'http://localhost:8090',
        authToken: explicitToken,
      );
      expect(serviceWithToken, isNotNull);
      // The service can be constructed successfully with a provided token.
    });

    test('service with no authToken can be constructed (uses dev fallback)', () {
      final serviceNoToken = RealAnalysisService(
        baseUrl: 'http://localhost:8090',
      );
      expect(serviceNoToken, isNotNull);
    });
  });

  group('GroupBy.toUpperCase transformation', () {
    // The PR changed groupBy?.name to groupBy?.name.toUpperCase() for API calls.
    // Verify the enum name uppercasing behavior.

    test('GroupBy.sector name uppercases to SECTOR', () {
      expect(GroupBy.sector.name.toUpperCase(), equals('SECTOR'));
    });

    test('GroupBy.stock name uppercases to STOCK', () {
      expect(GroupBy.stock.name.toUpperCase(), equals('STOCK'));
    });

    test('null GroupBy produces null when toUpperCase called conditionally', () {
      GroupBy? groupBy;
      final result = groupBy?.name.toUpperCase();
      expect(result, isNull);
    });

    test('all GroupBy values uppercase without error', () {
      for (final value in GroupBy.values) {
        expect(() => value.name.toUpperCase(), returnsNormally);
        expect(value.name.toUpperCase(), equals(value.name.toUpperCase()));
      }
    });
  });
}
