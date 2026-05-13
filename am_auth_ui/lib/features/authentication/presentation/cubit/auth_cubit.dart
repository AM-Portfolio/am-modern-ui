import 'package:am_design_system/am_design_system.dart';
import 'package:am_common/am_common.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_common/am_common.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/demo_login_usecase.dart';
import '../../domain/usecases/email_login_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/google_login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/entities/user_entity.dart';
import 'auth_state.dart';

/// Authentication Cubit
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required EmailLoginUseCase emailLoginUseCase,
    required GoogleLoginUseCase googleLoginUseCase,
    required DemoLoginUseCase demoLoginUseCase,
    required LogoutUseCase logoutUseCase,
    required CheckAuthStatusUseCase checkAuthStatusUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required RegisterUseCase registerUseCase,
  }) : _emailLoginUseCase = emailLoginUseCase,
       _googleLoginUseCase = googleLoginUseCase,
       _demoLoginUseCase = demoLoginUseCase,
       _logoutUseCase = logoutUseCase,
       _checkAuthStatusUseCase = checkAuthStatusUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       _registerUseCase = registerUseCase,
       super(const AuthInitial());
  final EmailLoginUseCase _emailLoginUseCase;
  final GoogleLoginUseCase _googleLoginUseCase;
  final DemoLoginUseCase _demoLoginUseCase;
  final LogoutUseCase _logoutUseCase;
  final CheckAuthStatusUseCase _checkAuthStatusUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final RegisterUseCase _registerUseCase;

  /// Login with email and password
  Future<void> loginWithEmail(
    String email, 
    String password,
  ) async {
    emit(const AuthLoading());

    final result = await _emailLoginUseCase(
      email: email, 
      password: password,
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (authResult) => emit(Authenticated(_guardUser(authResult.user))),
    );
  }

  /// Login with Google
  Future<void> loginWithGoogle() async {
    emit(const AuthLoading());

    final result = await _googleLoginUseCase();

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (authResult) => emit(Authenticated(_guardUser(authResult.user))),
    );
  }

  /// Login with demo account
  Future<void> loginWithDemo() async {
    emit(const AuthLoading());

    final result = await _demoLoginUseCase();

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (authResult) => emit(Authenticated(_guardUser(authResult.user))),
    );
  }

  /// Logout
  Future<void> logout() async {
    emit(const AuthLoading());

    final result = await _logoutUseCase();

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const Unauthenticated()),
    );
  }

  /// Check authentication status and restore session if valid
  Future<void> checkAuthStatus() async {
    CommonLogger.methodEntry('checkAuthStatus', tag: 'AuthCubit');
    CommonLogger.debug(
      '🔍 Starting authentication status check...',
      tag: 'AuthCubit',
    );
    emit(const AuthLoading());

    final statusResult = await _checkAuthStatusUseCase();

    await statusResult.fold(
      (failure) async {
        CommonLogger.error(
          '❌ Auth status check failed',
          tag: 'AuthCubit',
          error: failure,
        );
        CommonLogger.debug(
          '🔄 Emitting Unauthenticated state due to check failure',
          tag: 'AuthCubit',
        );
        emit(const Unauthenticated());
      },
      (isAuthenticated) async {
        CommonLogger.info(
          '✅ Auth status result: $isAuthenticated',
          tag: 'AuthCubit',
        );
        if (isAuthenticated) {
          CommonLogger.debug('📦 Fetching user from storage...', tag: 'AuthCubit');
          // Fetch and restore user from storage
          final userResult = await _getCurrentUserUseCase();
          userResult.fold(
            (failure) {
              CommonLogger.error(
                '❌ Failed to get current user from storage',
                tag: 'AuthCubit',
                error: failure,
              );
              CommonLogger.debug(
                '🔄 Emitting Unauthenticated state due to user fetch failure',
                tag: 'AuthCubit',
              );
              emit(const Unauthenticated());
            },
            (authResult) {
              if (authResult != null) {
                final userId = authResult.user.id;
                final email = authResult.user.email;

                CommonLogger.info(
                  '✅ User retrieved from storage - userId: "$userId" (length: ${userId.length}), email: "$email"',
                  tag: 'AuthCubit',
                );

                // CRITICAL: Log if userId is empty before emitting state
                if (userId.isEmpty) {
                  CommonLogger.error(
                    '🚨 CRITICAL: Retrieved userId is EMPTY! email: "$email", authMethod: ${authResult.user.authMethod}',
                    tag: 'AuthCubit',
                  );
                  CommonLogger.debug(
                    '🔄 Emitting Unauthenticated state due to empty userId',
                    tag: 'AuthCubit',
                  );
                  emit(const Unauthenticated());
                } else {
                  final guardedUser = _guardUser(authResult.user);
                  CommonLogger.debug(
                    '🔄 Emitting Authenticated state with userId: "${guardedUser.id}"',
                    tag: 'AuthCubit',
                  );
                  emit(Authenticated(guardedUser, token: authResult.tokens.accessToken));
                  CommonLogger.info(
                    '✅ Authentication state emitted successfully',
                    tag: 'AuthCubit',
                  );
                }
              } else {
                CommonLogger.warning(
                  '⚠️ No auth result found in storage (null)',
                  tag: 'AuthCubit',
                );
                CommonLogger.debug(
                  '🔄 Emitting Unauthenticated state due to null auth result',
                  tag: 'AuthCubit',
                );
                emit(const Unauthenticated());
              }
            },
          );
        } else {
          CommonLogger.debug(
            '🔄 Emitting Unauthenticated state (isAuthenticated = false)',
            tag: 'AuthCubit',
          );
          emit(const Unauthenticated());
        }
      },
    );

    CommonLogger.methodExit('checkAuthStatus', tag: 'AuthCubit');
  }

  /// Register new user
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? phone,
  }) async {
    if (password != confirmPassword) {
      emit(const AuthError('Passwords do not match'));
      return;
    }

    emit(const AuthLoading());

    try {
      final result = await _registerUseCase(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );

      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (authResult) => emit(Authenticated(_guardUser(authResult.user))),
      );
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Request password reset
  Future<void> forgotPassword(String email) async {
    emit(const AuthLoading());

    try {
      // TODO: Implement forgot password with proper use case integration
      // Critical: Do not emit false success without backend verification
      emit(
        const AuthError(
          'Password reset feature is not yet fully implemented. Please contact support to reset your password.',
        ),
      );
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Reset password with token
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    emit(const AuthLoading());

    try {
      // TODO: Implement reset password with proper use case integration
      // Critical: Do not emit false success without backend verification
      emit(
        const AuthError(
          'Password reset feature is not yet fully implemented. Please contact support to reset your password.',
        ),
      );
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Get current user ID if authenticated
  String get currentUserId {
    final currentState = state;
    if (currentState is Authenticated) {
      return currentState.user.id;
    }
    return '';
  }

  /// Global Identity Guard: Corrects legacy hardcoded IDs to production IDs
  UserEntity _guardUser(UserEntity user) {
    if (user.id == 'user_gyaan') {
      CommonLogger.info('🛡️ [GlobalIdentityGuard] Authorized test user session detected: user_gyaan.', tag: 'AuthCubit');
      return user; // Allow user_gyaan to pass through
    }
    // Correct legacy UUID if it somehow leaks through
    if (user.id == 'b75743c9-fe0e-4c54-8ee0-8da350cc27b3') {
       return user.copyWith(id: 'user_gyaan');
    }
    return user;
  }
}

