import 'package:dartz/dartz.dart';

import 'package:am_design_system/core/errors/failures.dart';
import '../entities/auth_result_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for user registration
class RegisterUseCase {
  RegisterUseCase(this.repository);
  final AuthRepository repository;

  Future<Either<Failure, AuthResultEntity>> call({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) {
    return repository.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );
  }
}
