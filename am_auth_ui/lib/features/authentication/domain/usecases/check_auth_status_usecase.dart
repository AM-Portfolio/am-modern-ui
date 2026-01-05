import 'package:dartz/dartz.dart';
import 'package:am_design_system/core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case for checking auth status
class CheckAuthStatusUseCase {
  CheckAuthStatusUseCase(this.repository);
  final AuthRepository repository;

  Future<Either<Failure, bool>> call() async => repository.checkAuthStatus();
}
