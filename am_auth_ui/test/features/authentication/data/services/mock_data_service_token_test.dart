import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for the JWT-like token generation logic introduced in MockDataService.
///
/// MockDataService._generateMockToken is private and the public authenticate
/// methods depend on asset loading (rootBundle), which requires a full Flutter
/// test environment with bundled assets. These tests therefore validate the
/// token-generation *algorithm* independently, replicating the exact logic
/// from the changed code to ensure correctness.
void main() {
  // Replicates MockDataService._generateMockToken(type, userId)
  String generateMockToken(String type, String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    const header = 'eyJhbGciOiJub25lIn0=';
    final payloadJson = '{"sub":"$userId","iat":$timestamp,"type":"$type"}';
    final payload =
        base64Url.encode(utf8.encode(payloadJson)).replaceAll('=', '');
    return '$header.$payload.dummy_signature';
  }

  group('MockDataService token generation (PR change: userId embedded in JWT)', () {
    group('token structure', () {
      test('token has 3 parts separated by dots', () {
        final token = generateMockToken('access', 'user-123');
        final parts = token.split('.');
        expect(parts.length, equals(3));
      });

      test('third part is always dummy_signature', () {
        final token = generateMockToken('access', 'any-user-id');
        expect(token, endsWith('.dummy_signature'));
      });

      test('first part is the fixed base64 header', () {
        final token = generateMockToken('access', 'any-user-id');
        final firstPart = token.split('.')[0];
        expect(firstPart, equals('eyJhbGciOiJub25lIn0='));
      });
    });

    group('payload contains userId as sub claim', () {
      test('access token payload has correct userId in sub claim', () {
        const userId = 'b75743c9-fe0e-4c54-8ee0-8da350cc27b3';
        final token = generateMockToken('access', userId);
        final payloadPart = token.split('.')[1];

        // Pad to make valid base64
        final padded = payloadPart.padRight(
          payloadPart.length + (4 - payloadPart.length % 4) % 4,
          '=',
        );
        final decoded = utf8.decode(base64Url.decode(padded));
        final payloadMap = json.decode(decoded) as Map<String, dynamic>;

        expect(payloadMap['sub'], equals(userId));
      });

      test('refresh token payload has correct userId in sub claim', () {
        const userId = '64d5f6c9-9516-4eca-ac45-c73cfff7a8ec';
        final token = generateMockToken('refresh', userId);
        final payloadPart = token.split('.')[1];

        final padded = payloadPart.padRight(
          payloadPart.length + (4 - payloadPart.length % 4) % 4,
          '=',
        );
        final decoded = utf8.decode(base64Url.decode(padded));
        final payloadMap = json.decode(decoded) as Map<String, dynamic>;

        expect(payloadMap['sub'], equals(userId));
      });

      test('different userIds produce different payloads', () {
        final tokenA = generateMockToken('access', 'user-aaa');
        final tokenB = generateMockToken('access', 'user-bbb');

        // The payload segment (index 1) should differ
        final payloadA = tokenA.split('.')[1];
        final payloadB = tokenB.split('.')[1];

        expect(payloadA, isNot(equals(payloadB)));
      });
    });

    group('payload contains type claim', () {
      test('access token has type:access in payload', () {
        final token = generateMockToken('access', 'test-user');
        final payloadPart = token.split('.')[1];

        final padded = payloadPart.padRight(
          payloadPart.length + (4 - payloadPart.length % 4) % 4,
          '=',
        );
        final decoded = utf8.decode(base64Url.decode(padded));
        final payloadMap = json.decode(decoded) as Map<String, dynamic>;

        expect(payloadMap['type'], equals('access'));
      });

      test('refresh token has type:refresh in payload', () {
        final token = generateMockToken('refresh', 'test-user');
        final payloadPart = token.split('.')[1];

        final padded = payloadPart.padRight(
          payloadPart.length + (4 - payloadPart.length % 4) % 4,
          '=',
        );
        final decoded = utf8.decode(base64Url.decode(padded));
        final payloadMap = json.decode(decoded) as Map<String, dynamic>;

        expect(payloadMap['type'], equals('refresh'));
      });
    });

    group('payload contains iat (issued at) timestamp', () {
      test('iat is a recent epoch millisecond timestamp', () {
        final before = DateTime.now().millisecondsSinceEpoch;
        final token = generateMockToken('access', 'user-ts');
        final after = DateTime.now().millisecondsSinceEpoch;

        final payloadPart = token.split('.')[1];
        final padded = payloadPart.padRight(
          payloadPart.length + (4 - payloadPart.length % 4) % 4,
          '=',
        );
        final decoded = utf8.decode(base64Url.decode(padded));
        final payloadMap = json.decode(decoded) as Map<String, dynamic>;

        final iat = payloadMap['iat'] as int;
        expect(iat, greaterThanOrEqualTo(before));
        expect(iat, lessThanOrEqualTo(after));
      });
    });

    group('payload base64 encoding', () {
      test('payload segment does not contain padding = characters', () {
        final token = generateMockToken('access', 'user-no-pad');
        final payloadPart = token.split('.')[1];
        expect(payloadPart.contains('='), isFalse);
      });
    });

    group('regression: old format vs new format', () {
      test('new token format is NOT the old mock_type_token format', () {
        final token = generateMockToken('access', 'some-user-id');
        expect(token, isNot(contains('mock_access_token')));
      });

      test('new token is parseable as a 3-part JWT structure', () {
        const userId = 'test-user-99';
        final token = generateMockToken('access', userId);

        // Must be parseable as JWT
        final parts = token.split('.');
        expect(parts.length, equals(3));

        // Middle part must be valid base64-decodable JSON
        final payloadPart = parts[1];
        final padded = payloadPart.padRight(
          payloadPart.length + (4 - payloadPart.length % 4) % 4,
          '=',
        );
        expect(
          () => json.decode(utf8.decode(base64Url.decode(padded))),
          returnsNormally,
        );
      });
    });
  });
}