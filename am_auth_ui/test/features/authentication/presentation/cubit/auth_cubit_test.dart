import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:am_design_system/core/errors/failures.dart';
import 'package:am_auth_ui/features/authentication/domain/entities/auth_result_entity.dart';
import 'package:am_auth_ui/features/authentication/domain/entities/auth_tokens_entity.dart';
import 'package:am_auth_ui/features/authentication/domain/entities/user_entity.dart';
import 'package:am_auth_ui/features/authentication/domain/repositories/auth_repository.dart';
import 'package:am_auth_ui/features/authentication/domain/usecases/check_auth_status_usecase.dart';
import 'package:am_auth_ui/features/authentication/domain/usecases/demo_login_usecase.dart';
import 'package:am_auth_ui/features/authentication/domain/usecases/email_login_usecase.dart';
import 'package:am_auth_ui/features/authentication/domain/usecases/get_current_user_usecase.dart';
import 'package:am_auth_ui/features/authentication/domain/usecases/google_login_usecase.dart';
import 'package:am_auth_ui/features/authentication/domain/usecases/logout_usecase.dart';
import 'package:am_auth_ui/features/authentication/domain/usecases/register_usecase.dart';
import 'package:am_auth_ui/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:am_auth_ui/features/authentication/presentation/cubit/auth_state.dart';

/// Stub AuthRepository with configurable return values for testing.
class _StubAuthRepository implements AuthRepository {
  _StubAuthRepository({
    this.emailLoginResult,
    this.googleLoginResult,
    this.demoLoginResult,
    this.checkAuthStatusResult,
    this.getCurrentUserResult,
    this.logoutResult,
    this.registerResult,
  });

  final Either<Failure, AuthResultEntity>? emailLoginResult;
  final Either<Failure, AuthResultEntity>? googleLoginResult;
  final Either<Failure, AuthResultEntity>? demoLoginResult;
  final Either<Failure, bool>? checkAuthStatusResult;
  final Either<Failure, AuthResultEntity?>? getCurrentUserResult;
  final Either<Failure, void>? logoutResult;
  final Either<Failure, AuthResultEntity>? registerResult;

  @override
  Future<Either<Failure, AuthResultEntity>> emailLogin({
    required String email,
    required String password,
  }) async =>
      emailLoginResult ?? Right(_makeAuthResult('email-user-id'));

  @override
  Future<Either<Failure, AuthResultEntity>> googleLogin() async =>
      googleLoginResult ?? Right(_makeAuthResult('google-user-id'));

  @override
  Future<Either<Failure, AuthResultEntity>> demoLogin() async =>
      demoLoginResult ?? Right(_makeAuthResult('demo-user-id'));

  @override
  Future<Either<Failure, void>> logout() async =>
      logoutResult ?? const Right(null);

  @override
  Future<Either<Failure, bool>> checkAuthStatus() async =>
      checkAuthStatusResult ?? const Right(false);

  @override
  Future<Either<Failure, AuthResultEntity?>> getCurrentUser() async =>
      getCurrentUserResult ?? const Right(null);

  @override
  Future<Either<Failure, AuthResultEntity>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async =>
      registerResult ?? Right(_makeAuthResult('register-user-id'));

  @override
  Future<Either<Failure, AuthTokensEntity>> refreshToken(
      String refreshToken) async =>
      Right(AuthTokensEntity(
        accessToken: 'refreshed-token',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ));
}

AuthResultEntity _makeAuthResult(String userId, {String? accessToken}) {
  return AuthResultEntity(
    user: UserEntity(
      id: userId,
      email: '$userId@example.com',
      displayName: 'Test User',
      authMethod: 'email',
    ),
    tokens: AuthTokensEntity(
      accessToken: accessToken ?? 'Bearer mock.token.sig',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    ),
  );
}

AuthCubit _buildCubit(_StubAuthRepository repo) {
  return AuthCubit(
    emailLoginUseCase: EmailLoginUseCase(repo),
    googleLoginUseCase: GoogleLoginUseCase(repo),
    demoLoginUseCase: DemoLoginUseCase(repo),
    logoutUseCase: LogoutUseCase(repo),
    checkAuthStatusUseCase: CheckAuthStatusUseCase(repo),
    getCurrentUserUseCase: GetCurrentUserUseCase(repo),
    registerUseCase: RegisterUseCase(repo),
  );
}

void main() {
  group('AuthCubit', () {
    group('currentUserId getter', () {
      test('returns empty string when state is AuthInitial', () {
        final repo = _StubAuthRepository();
        final cubit = _buildCubit(repo);

        expect(cubit.state, isA<AuthInitial>());
        expect(cubit.currentUserId, equals(''));

        cubit.close();
      });

      test('returns user id when state is Authenticated after email login', () async {
        const userId = 'abc-123-user';
        final repo = _StubAuthRepository(
          emailLoginResult: Right(_makeAuthResult(userId)),
        );
        final cubit = _buildCubit(repo);

        await cubit.loginWithEmail('test@test.com', 'password');

        expect(cubit.state, isA<Authenticated>());
        expect(cubit.currentUserId, equals(userId));

        cubit.close();
      });

      test('returns empty string when state is Unauthenticated after logout', () async {
        final repo = _StubAuthRepository(
          emailLoginResult: Right(_makeAuthResult('some-user')),
          logoutResult: const Right(null),
        );
        final cubit = _buildCubit(repo);

        await cubit.loginWithEmail('test@test.com', 'pass');
        expect(cubit.currentUserId, isNotEmpty);

        await cubit.logout();
        expect(cubit.state, isA<Unauthenticated>());
        expect(cubit.currentUserId, equals(''));

        cubit.close();
      });

      test('returns empty string when state is AuthError', () async {
        const failure = ServerFailure('Login failed');
        final repo = _StubAuthRepository(
          emailLoginResult: const Left(failure),
        );
        final cubit = _buildCubit(repo);

        await cubit.loginWithEmail('bad@test.com', 'wrongpass');

        expect(cubit.state, isA<AuthError>());
        expect(cubit.currentUserId, equals(''));

        cubit.close();
      });

      test('returns user id after demo login', () async {
        const userId = 'demo-user-xyz';
        final repo = _StubAuthRepository(
          demoLoginResult: Right(_makeAuthResult(userId)),
        );
        final cubit = _buildCubit(repo);

        await cubit.loginWithDemo();

        expect(cubit.currentUserId, equals(userId));

        cubit.close();
      });
    });

    group('checkAuthStatus emits Authenticated with token', () {
      test('token from access token is included in Authenticated state', () async {
        const userId = 'restored-user-id';
        const accessToken = 'Bearer header.payload.signature';
        final authResult = _makeAuthResult(userId, accessToken: accessToken);

        final repo = _StubAuthRepository(
          checkAuthStatusResult: const Right(true),
          getCurrentUserResult: Right(authResult),
        );
        final cubit = _buildCubit(repo);

        await cubit.checkAuthStatus();

        expect(cubit.state, isA<Authenticated>());
        final authState = cubit.state as Authenticated;
        expect(authState.token, equals(accessToken));
        expect(authState.user.id, equals(userId));

        cubit.close();
      });

      test('emits Unauthenticated when not authenticated', () async {
        final repo = _StubAuthRepository(
          checkAuthStatusResult: const Right(false),
        );
        final cubit = _buildCubit(repo);

        await cubit.checkAuthStatus();

        expect(cubit.state, isA<Unauthenticated>());
        expect(cubit.currentUserId, equals(''));

        cubit.close();
      });

      test('emits Unauthenticated when user id is empty', () async {
        final authResultEmptyId = AuthResultEntity(
          user: const UserEntity(
            id: '',
            email: 'test@example.com',
            displayName: 'Test',
            authMethod: 'email',
          ),
          tokens: AuthTokensEntity(
            accessToken: 'some-token',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
          ),
        );

        final repo = _StubAuthRepository(
          checkAuthStatusResult: const Right(true),
          getCurrentUserResult: Right(authResultEmptyId),
        );
        final cubit = _buildCubit(repo);

        await cubit.checkAuthStatus();

        expect(cubit.state, isA<Unauthenticated>());

        cubit.close();
      });
    });

    group('register', () {
      test('emits AuthError when passwords do not match', () async {
        final repo = _StubAuthRepository();
        final cubit = _buildCubit(repo);

        await cubit.register(
          name: 'Test',
          email: 'test@test.com',
          password: 'pass1',
          confirmPassword: 'pass2',
        );

        expect(cubit.state, isA<AuthError>());
        expect((cubit.state as AuthError).message, contains('Passwords do not match'));

        cubit.close();
      });
    });
  });
}