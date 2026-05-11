import 'package:flutter_test/flutter_test.dart';
import 'package:am_auth_ui/features/authentication/domain/entities/user_entity.dart';
import 'package:am_auth_ui/features/authentication/presentation/cubit/auth_state.dart';

void main() {
  group('AuthState', () {
    const testUser = UserEntity(
      id: 'test-user-id-123',
      email: 'test@example.com',
      displayName: 'Test User',
      authMethod: 'email',
    );

    group('Authenticated', () {
      test('constructs with user and no token by default', () {
        const state = Authenticated(testUser);

        expect(state.user, testUser);
        expect(state.token, isNull);
      });

      test('constructs with user and optional token', () {
        const tokenValue = 'Bearer eyJhbGciOiJub25lIn0.eyJzdWIiOiJ0ZXN0In0.sig';
        const state = Authenticated(testUser, token: tokenValue);

        expect(state.user, testUser);
        expect(state.token, tokenValue);
      });

      test('props includes both user and token when token is provided', () {
        const tokenValue = 'Bearer some.token.here';
        const state = Authenticated(testUser, token: tokenValue);

        expect(state.props, equals([testUser, tokenValue]));
      });

      test('props includes user and null when no token provided', () {
        const state = Authenticated(testUser);

        expect(state.props, equals([testUser, null]));
      });

      test('two Authenticated states with same user and token are equal', () {
        const token = 'Bearer header.payload.sig';
        const state1 = Authenticated(testUser, token: token);
        const state2 = Authenticated(testUser, token: token);

        expect(state1, equals(state2));
      });

      test('two Authenticated states with same user but different tokens are not equal', () {
        const state1 = Authenticated(testUser, token: 'Bearer token.one.sig');
        const state2 = Authenticated(testUser, token: 'Bearer token.two.sig');

        expect(state1, isNot(equals(state2)));
      });

      test('Authenticated without token differs from Authenticated with token', () {
        const stateNoToken = Authenticated(testUser);
        const stateWithToken = Authenticated(testUser, token: 'Bearer a.b.c');

        expect(stateNoToken, isNot(equals(stateWithToken)));
      });

      test('Authenticated state is an AuthState', () {
        const state = Authenticated(testUser);
        expect(state, isA<AuthState>());
      });
    });

    group('AuthInitial', () {
      test('has empty props', () {
        const state = AuthInitial();
        expect(state.props, isEmpty);
      });

      test('two AuthInitial instances are equal', () {
        const a = AuthInitial();
        const b = AuthInitial();
        expect(a, equals(b));
      });
    });

    group('AuthLoading', () {
      test('two AuthLoading instances are equal', () {
        const a = AuthLoading();
        const b = AuthLoading();
        expect(a, equals(b));
      });
    });

    group('AuthError', () {
      test('holds message and includes it in props', () {
        const state = AuthError('Something went wrong');
        expect(state.message, 'Something went wrong');
        expect(state.props, contains('Something went wrong'));
      });

      test('two AuthError states with different messages are not equal', () {
        const a = AuthError('error one');
        const b = AuthError('error two');
        expect(a, isNot(equals(b)));
      });
    });

    group('Unauthenticated', () {
      test('two Unauthenticated instances are equal', () {
        const a = Unauthenticated();
        const b = Unauthenticated();
        expect(a, equals(b));
      });
    });
  });
}