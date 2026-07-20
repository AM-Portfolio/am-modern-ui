import 'package:dartz/dartz.dart';
import 'package:am_design_system/core/errors/failures.dart';
import '../entities/auth_result_entity.dart';
import '../entities/auth_tokens_entity.dart';

/// Authentication repository interface
abstract class AuthRepository {
  /// Login with email and password
  Future<Either<Failure, AuthResultEntity>> emailLogin({
    required String email,
    required String password,
  });

  /// Login with Google
  Future<Either<Failure, AuthResultEntity>> googleLogin();

  /// Login with demo account
  Future<Either<Failure, AuthResultEntity>> demoLogin();

  /// Logout
  Future<Either<Failure, void>> logout();

  /// Refresh authentication token
  Future<Either<Failure, AuthTokensEntity>> refreshToken(String refreshToken);

  /// Check authentication status
  Future<Either<Failure, bool>> checkAuthStatus();

  /// Register new user
  Future<Either<Failure, AuthResultEntity>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  });

  /// Get current user
  Future<Either<Failure, AuthResultEntity?>> getCurrentUser();

  /// Request password reset email (always succeeds from caller POV).
  Future<Either<Failure, void>> requestPasswordReset(String email);

  /// Confirm password reset with mail token or short code.
  Future<Either<Failure, void>> confirmPasswordReset({
    String? token,
    String? code,
    required String newPassword,
  });

  /// Confirm email verification with mail token or short code.
  /// On success returns an authenticated session (tokens) for auto-login.
  Future<Either<Failure, AuthResultEntity>> confirmVerifyEmail({
    String? token,
    String? code,
  });

  /// Resend verification email (always succeeds from caller POV).
  Future<Either<Failure, void>> resendVerifyEmail(String email);

  /// Change password for email/password users (requires current password).
  Future<Either<Failure, void>> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  });

  /// Request account deletion with feedback
  Future<Either<Failure, void>> requestAccountDeletion({
    required String feedback,
  });
}
