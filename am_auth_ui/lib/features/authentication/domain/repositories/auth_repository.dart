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
}
