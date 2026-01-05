import 'package:dartz/dartz.dart';
import 'package:am_design_system/core/errors/failures.dart';
import '../entities/auth_result_entity.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  GetCurrentUserUseCase(this._repository);
  final AuthRepository _repository;

  Future<Either<Failure, AuthResultEntity?>> call() async =>
      _repository.getCurrentUser();
}
