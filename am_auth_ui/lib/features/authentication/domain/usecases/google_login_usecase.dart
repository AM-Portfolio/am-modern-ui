import 'package:dartz/dartz.dart';
import 'package:am_design_system/core/errors/failures.dart';
import '../entities/auth_result_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for Google login
class GoogleLoginUseCase {
  GoogleLoginUseCase(this.repository);
  final AuthRepository repository;

  Future<Either<Failure, AuthResultEntity>> call() async =>
      repository.googleLogin();
}
