import '../entities/favorite_filter.dart';
import '../entities/metrics_filter_config.dart';
import '../repositories/favorite_filter_repository.dart';

/// Use case for creating a favorite filter
class CreateFavoriteFilterUseCase {
  CreateFavoriteFilterUseCase(this._repository);

  final FavoriteFilterRepository _repository;

  Future<FavoriteFilter> call({
    required String userId,
    required String name,
    required MetricsFilterConfig filterConfig,
    String? description,
    bool? isDefault,
  }) async =>
      _repository.createFavoriteFilter(userId, name, filterConfig, description: description, isDefault: isDefault);
}
