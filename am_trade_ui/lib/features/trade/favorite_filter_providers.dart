import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/config/app_config.dart';

import 'package:am_common/core/network/api_client.dart';
import 'internal/data/datasources/favorite_filter_remote_data_source.dart';
import 'internal/data/repositories/favorite_filter_repository_impl.dart';
import 'internal/domain/entities/favorite_filter.dart';
import 'internal/domain/repositories/favorite_filter_repository.dart';
import 'internal/domain/usecases/create_favorite_filter_usecase.dart';
import 'internal/domain/usecases/delete_favorite_filter_usecase.dart';
import 'internal/domain/usecases/get_favorite_filters_usecase.dart';
import 'internal/domain/usecases/set_default_filter_usecase.dart';
import 'presentation/cubit/favorite_filter/favorite_filter_cubit.dart';
import 'package:am_common/core/di/network_providers.dart';

// Infrastructure Providers

/// Provider for FavoriteFilterRemoteDataSource
final _favoriteFilterRemoteDataSourceProvider = FutureProvider<FavoriteFilterRemoteDataSource>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final apiConfig = await ref.watch(appConfigProvider.future);
  return FavoriteFilterRemoteDataSourceImpl(apiClient: apiClient, tradeConfig: apiConfig.api.trade);
});

/// Provider for FavoriteFilterRepository
final _favoriteFilterRepositoryProvider = FutureProvider<FavoriteFilterRepository>((ref) async {
  final remoteDataSource = await ref.watch(_favoriteFilterRemoteDataSourceProvider.future);
  return FavoriteFilterRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Public Providers for UI

/// Provider to get all favorite filters for a user
final favoriteFiltersProvider = FutureProvider.family<FavoriteFilterList, String>((ref, userId) async {
  final repository = await ref.watch(_favoriteFilterRepositoryProvider.future);
  return repository.getFavoriteFilters(userId);
});

/// Provider to get a specific favorite filter by ID
final favoriteFilterByIdProvider = FutureProvider.family<FavoriteFilter, ({String userId, String filterId})>((
  ref,
  params,
) async {
  final repository = await ref.watch(_favoriteFilterRepositoryProvider.future);
  return repository.getFavoriteFilterById(params.userId, params.filterId);
});

/// Provider to watch favorite filters stream for real-time updates
final watchFavoriteFiltersProvider = StreamProvider.family<FavoriteFilterList, String>((ref, userId) async* {
  final repository = await ref.watch(_favoriteFilterRepositoryProvider.future);
  yield* repository.watchFavoriteFilters(userId);
});

/// Provider to get the repository instance for direct method calls
final favoriteFilterRepositoryProvider = FutureProvider<FavoriteFilterRepository>(
  (ref) async => await ref.watch(_favoriteFilterRepositoryProvider.future),
);

// Use Case Providers

/// Provider for GetFavoriteFiltersUseCase
final _getFavoriteFiltersUseCaseProvider = FutureProvider<GetFavoriteFiltersUseCase>((ref) async {
  final repository = await ref.watch(_favoriteFilterRepositoryProvider.future);
  return GetFavoriteFiltersUseCase(repository);
});

/// Provider for CreateFavoriteFilterUseCase
final _createFavoriteFilterUseCaseProvider = FutureProvider<CreateFavoriteFilterUseCase>((ref) async {
  final repository = await ref.watch(_favoriteFilterRepositoryProvider.future);
  return CreateFavoriteFilterUseCase(repository);
});

/// Provider for DeleteFavoriteFilterUseCase
final _deleteFavoriteFilterUseCaseProvider = FutureProvider<DeleteFavoriteFilterUseCase>((ref) async {
  final repository = await ref.watch(_favoriteFilterRepositoryProvider.future);
  return DeleteFavoriteFilterUseCase(repository);
});

/// Provider for SetDefaultFilterUseCase
final _setDefaultFilterUseCaseProvider = FutureProvider<SetDefaultFilterUseCase>((ref) async {
  final repository = await ref.watch(_favoriteFilterRepositoryProvider.future);
  return SetDefaultFilterUseCase(repository);
});

// Cubit Provider

/// Provider for FavoriteFilterCubit
final favoriteFilterCubitProvider = FutureProvider<FavoriteFilterCubit>(
  (ref) async => FavoriteFilterCubit(
    getFavoriteFilters: await ref.watch(_getFavoriteFiltersUseCaseProvider.future),
    createFavoriteFilter: await ref.watch(_createFavoriteFilterUseCaseProvider.future),
    deleteFavoriteFilter: await ref.watch(_deleteFavoriteFilterUseCaseProvider.future),
    setDefaultFilter: await ref.watch(_setDefaultFilterUseCaseProvider.future),
  ),
);
