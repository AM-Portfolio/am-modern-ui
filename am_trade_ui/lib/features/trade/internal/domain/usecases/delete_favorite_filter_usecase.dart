import '../entities/favorite_filter.dart';
import '../repositories/favorite_filter_repository.dart';

/// Use case for deleting a favorite filter
class DeleteFavoriteFilterUseCase {
  DeleteFavoriteFilterUseCase(this._repository);

  final FavoriteFilterRepository _repository;

  Future<void> call(String userId, String filterId) async => _repository.deleteFavoriteFilter(userId, filterId);
}
