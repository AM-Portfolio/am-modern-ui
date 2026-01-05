import '../entities/favorite_filter.dart';
import '../repositories/favorite_filter_repository.dart';

/// Use case for setting a filter as default
class SetDefaultFilterUseCase {
  SetDefaultFilterUseCase(this._repository);

  final FavoriteFilterRepository _repository;

  Future<FavoriteFilter> call(String userId, String filterId) async => _repository.setDefaultFilter(userId, filterId);
}
