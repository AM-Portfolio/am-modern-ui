import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/core/errors/failures.dart';
import 'package:am_common/am_common.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/demo_login_usecase.dart';
import '../../domain/usecases/email_login_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/google_login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
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
    required AuthRepository authRepository,
  }) : _emailLoginUseCase = emailLoginUseCase,
       _googleLoginUseCase = googleLoginUseCase,
       _demoLoginUseCase = demoLoginUseCase,
       _logoutUseCase = logoutUseCase,
       _checkAuthStatusUseCase = checkAuthStatusUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       _registerUseCase = registerUseCase,
       _authRepository = authRepository,
       super(const AuthInitial());
  final EmailLoginUseCase _emailLoginUseCase;
  final GoogleLoginUseCase _googleLoginUseCase;
  final DemoLoginUseCase _demoLoginUseCase;
  final LogoutUseCase _logoutUseCase;
  final CheckAuthStatusUseCase _checkAuthStatusUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final RegisterUseCase _registerUseCase;
  final AuthRepository _authRepository;

  /// Invalidates in-flight [checkAuthStatus] when a newer auth mutation starts
  /// (e.g. verify-email confirm must not be overwritten by a stale restore).
  int _authGeneration = 0;

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
      (failure) {
        final msg = failure.message.toLowerCase();
        if (msg.contains('verify your email') ||
            msg.contains('not fully set up') ||
            msg.contains('resend verification')) {
          emit(RegisterPendingVerification(email));
          return;
        }
        emit(AuthError(failure.message));
      },
      (authResult) => emit(Authenticated(authResult.user)),
    );
  }

  /// Login with Google
  Future<void> loginWithGoogle() async {
    emit(const AuthLoading());

    final result = await _googleLoginUseCase();

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (authResult) => emit(Authenticated(authResult.user)),
    );
  }

  /// Login with demo account
  Future<void> loginWithDemo() async {
    emit(const AuthLoading());

    final result = await _demoLoginUseCase();

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (authResult) => emit(Authenticated(authResult.user)),
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
    BootTrace.instance.mark('auth_check_start');
    CommonLogger.debug(
      '🔍 Starting authentication status check...',
      tag: 'AuthCubit',
    );
    final generation = ++_authGeneration;
    emit(const AuthLoading());

    final statusResult = await _checkAuthStatusUseCase();
    if (generation != _authGeneration) {
      CommonLogger.debug(
        '⏭️ Auth restore superseded by a newer auth flow',
        tag: 'AuthCubit',
      );
      BootTrace.instance.mark('auth_check_done');
      CommonLogger.methodExit('checkAuthStatus', tag: 'AuthCubit');
      return;
    }

    await statusResult.fold(
      (failure) async {
        if (generation != _authGeneration) return;
        CommonLogger.error(
          '❌ Auth status check failed',
          tag: 'AuthCubit',
          error: failure,
        );
        if (failure is NetworkFailure || _isTransientServerFailure(failure)) {
          CommonLogger.debug(
            '🔄 Emitting AuthRestoreFailed (transient) — stay on current page',
            tag: 'AuthCubit',
          );
          emit(AuthRestoreFailed(failure.message));
          return;
        }
        CommonLogger.debug(
          '🔄 Emitting Unauthenticated state due to check failure',
          tag: 'AuthCubit',
        );
        emit(const Unauthenticated());
      },
      (isAuthenticated) async {
        if (generation != _authGeneration) return;
        CommonLogger.info(
          '✅ Auth status result: $isAuthenticated',
          tag: 'AuthCubit',
        );
        if (isAuthenticated) {
          CommonLogger.debug('📦 Fetching user from storage...', tag: 'AuthCubit');
          // Fetch and restore user from storage
          final userResult = await _getCurrentUserUseCase();
          if (generation != _authGeneration) return;
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
                  CommonLogger.debug(
                    '🔄 Emitting Authenticated state with userId: "$userId"',
                    tag: 'AuthCubit',
                  );
                  emit(Authenticated(authResult.user));
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

    BootTrace.instance.mark('auth_check_done');
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
        (failure) {
          if (failure is ServerFailure && failure.code == '201') {
            emit(RegisterPendingVerification(email));
            return;
          }
          emit(AuthError(failure.message));
        },
        (authResult) => emit(Authenticated(authResult.user)),
      );
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Request password reset
  Future<void> forgotPassword(String email) async {
    final previous = state;
    emit(const AuthLoading());

    try {
      final result = await _authRepository.requestPasswordReset(email);
      result.fold(
        (failure) {
          emit(AuthError(failure.message));
          if (previous is Authenticated) {
            emit(previous);
          }
        },
        (_) => emit(const PasswordResetEmailSent()),
      );
    } catch (e) {
      emit(AuthError(e.toString()));
      if (previous is Authenticated) {
        emit(previous);
      }
    }
  }

  /// Reset password with short mail code or legacy HMAC token.
  Future<void> resetPassword({
    String? resetToken,
    String? resetCode,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      emit(const AuthError('Passwords do not match'));
      return;
    }

    final previous = state;
    emit(const AuthLoading());

    try {
      final result = await _authRepository.confirmPasswordReset(
        token: resetToken,
        code: resetCode,
        newPassword: newPassword,
      );
      result.fold(
        (failure) {
          emit(AuthError(failure.message));
          if (previous is Authenticated) {
            emit(previous);
          }
        },
        (_) => emit(const PasswordResetSuccess()),
      );
    } catch (e) {
      emit(AuthError(e.toString()));
      if (previous is Authenticated) {
        emit(previous);
      }
    }
  }

  /// Confirm email verification from deep link code or token.
  /// On success stores session tokens and emits [Authenticated] (auto-login).
  Future<void> confirmVerifyEmail({String? token, String? code}) async {
    final previous = state;
    // Bump so an in-flight session restore cannot overwrite this confirm.
    final generation = ++_authGeneration;
    emit(const AuthLoading());
    try {
      final result = await _authRepository.confirmVerifyEmail(
        token: token,
        code: code,
      );
      if (generation != _authGeneration) return;
      result.fold(
        (failure) {
          emit(AuthError(failure.message));
          if (previous is Authenticated) {
            emit(previous);
          }
        },
        (authResult) => emit(Authenticated(authResult.user)),
      );
    } catch (e) {
      if (generation != _authGeneration) return;
      emit(AuthError(e.toString()));
      if (previous is Authenticated) {
        emit(previous);
      }
    }
  }

  Future<void> resendVerifyEmail(String email) async {
    final previous = state;
    try {
      final result = await _authRepository.resendVerifyEmail(email);
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (_) {
          emit(RegisterPendingVerification(email));
          if (previous is Authenticated) {
            emit(previous);
          }
        },
      );
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final previous = state;
    emit(const AuthLoading());
    try {
      final result = await _authRepository.changePassword(
        email: email,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      result.fold(
        (failure) {
          emit(AuthError(failure.message));
          if (previous is Authenticated) emit(previous);
        },
        (_) {
          emit(const PasswordResetSuccess());
          if (previous is Authenticated) emit(previous);
        },
      );
    } catch (e) {
      emit(AuthError(e.toString()));
      if (previous is Authenticated) emit(previous);
    }
  }
}

bool _isTransientServerFailure(Failure failure) {
  if (failure is! ServerFailure) return false;
  final status = int.tryParse(failure.code ?? '');
  return status != null && status >= 500;
}

