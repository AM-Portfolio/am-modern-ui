import 'package:dartz/dartz.dart';
import 'package:am_design_system/core/errors/failures.dart';
import '../entities/auth_result_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for email/password login
class EmailLoginUseCase {
  EmailLoginUseCase(this.repository);
  final AuthRepository repository;

  Future<Either<Failure, AuthResultEntity>> call({
    required String email,
    required String password,
  }) async {
    return repository.emailLogin(email: email, password: password);
  }
}
