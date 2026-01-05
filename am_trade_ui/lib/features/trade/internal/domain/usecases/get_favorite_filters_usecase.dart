import '../entities/favorite_filter.dart';
import '../repositories/favorite_filter_repository.dart';

/// Use case for getting favorite filters
class GetFavoriteFiltersUseCase {
  GetFavoriteFiltersUseCase(this._repository);

  final FavoriteFilterRepository _repository;

  Future<FavoriteFilterList> call(String userId) async => _repository.getFavoriteFilters(userId);

  Stream<FavoriteFilterList> watch(String userId) => _repository.watchFavoriteFilters(userId);
}
