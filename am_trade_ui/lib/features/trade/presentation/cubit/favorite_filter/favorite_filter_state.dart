part of 'favorite_filter_cubit.dart';

@freezed
abstract class FavoriteFilterState with _$FavoriteFilterState {
  /// Initial state
  const factory FavoriteFilterState.initial() = _Initial;

  /// Loading filters
  const factory FavoriteFilterState.loading() = _Loading;

  /// Filters loaded successfully
  const factory FavoriteFilterState.loaded(FavoriteFilterList filterList, {FavoriteFilter? selectedFilter}) = _Loaded;

  /// Error state
  const factory FavoriteFilterState.error(String message) = _Error;
}
