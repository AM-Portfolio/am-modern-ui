import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:am_common/am_common.dart';
import '../../../internal/domain/entities/favorite_filter.dart';
import '../../../internal/domain/entities/metrics_filter_config.dart';
import '../../../internal/domain/usecases/create_favorite_filter_usecase.dart';
import '../../../internal/domain/usecases/delete_favorite_filter_usecase.dart';
import '../../../internal/domain/usecases/get_favorite_filters_usecase.dart';
import '../../../internal/domain/usecases/set_default_filter_usecase.dart';

part 'favorite_filter_cubit.freezed.dart';
part 'favorite_filter_state.dart';

/// Cubit for managing favorite filter state
class FavoriteFilterCubit extends Cubit<FavoriteFilterState> {
  FavoriteFilterCubit({
    required GetFavoriteFiltersUseCase getFavoriteFilters,
    required CreateFavoriteFilterUseCase createFavoriteFilter,
    required DeleteFavoriteFilterUseCase deleteFavoriteFilter,
    required SetDefaultFilterUseCase setDefaultFilter,
  }) : _getFavoriteFilters = getFavoriteFilters,
       _createFavoriteFilter = createFavoriteFilter,
       _deleteFavoriteFilter = deleteFavoriteFilter,
       _setDefaultFilter = setDefaultFilter,
       super(const FavoriteFilterState.initial());

  final GetFavoriteFiltersUseCase _getFavoriteFilters;
  final CreateFavoriteFilterUseCase _createFavoriteFilter;
  final DeleteFavoriteFilterUseCase _deleteFavoriteFilter;
  final SetDefaultFilterUseCase _setDefaultFilter;

  /// Load favorite filters for the current user (JWT)
  Future<void> loadFilters() async {
    AppLogger.methodEntry('loadFilters', tag: 'FavoriteFilterCubit');

    emit(const FavoriteFilterState.loading());

    try {
      final filterList = await _getFavoriteFilters();
      emit(FavoriteFilterState.loaded(filterList));

      AppLogger.info('Filters loaded successfully: ${filterList.totalCount} filters', tag: 'FavoriteFilterCubit');
      AppLogger.methodExit('loadFilters', tag: 'FavoriteFilterCubit', result: 'success');
    } catch (e, stack) {
      AppLogger.error('Failed to load filters', tag: 'FavoriteFilterCubit', error: e, stackTrace: stack);
      emit(FavoriteFilterState.error(e.toString()));
      AppLogger.methodExit('loadFilters', tag: 'FavoriteFilterCubit', result: 'error');
    }
  }

  /// Create a new favorite filter
  Future<void> createFilter({
    required String name,
    required MetricsFilterConfig filterConfig,
    String? description,
    bool? isDefault,
  }) async {
    AppLogger.methodEntry('createFilter', tag: 'FavoriteFilterCubit', params: {'name': name});

    try {
      await _createFavoriteFilter(
        name: name,
        filterConfig: filterConfig,
        description: description,
        isDefault: isDefault,
      );

      await loadFilters();

      AppLogger.info('Filter created successfully', tag: 'FavoriteFilterCubit');
      AppLogger.methodExit('createFilter', tag: 'FavoriteFilterCubit', result: 'success');
    } catch (e, stack) {
      AppLogger.error('Failed to create filter', tag: 'FavoriteFilterCubit', error: e, stackTrace: stack);
      emit(FavoriteFilterState.error(e.toString()));
      AppLogger.methodExit('createFilter', tag: 'FavoriteFilterCubit', result: 'error');
    }
  }

  /// Delete a favorite filter
  Future<void> deleteFilter(String filterId) async {
    AppLogger.methodEntry('deleteFilter', tag: 'FavoriteFilterCubit', params: {'filterId': filterId});

    try {
      await _deleteFavoriteFilter(filterId);
      await loadFilters();

      AppLogger.info('Filter deleted successfully', tag: 'FavoriteFilterCubit');
      AppLogger.methodExit('deleteFilter', tag: 'FavoriteFilterCubit', result: 'success');
    } catch (e, stack) {
      AppLogger.error('Failed to delete filter', tag: 'FavoriteFilterCubit', error: e, stackTrace: stack);
      emit(FavoriteFilterState.error(e.toString()));
      AppLogger.methodExit('deleteFilter', tag: 'FavoriteFilterCubit', result: 'error');
    }
  }

  /// Set a filter as default
  Future<void> setAsDefault(String filterId) async {
    AppLogger.methodEntry('setAsDefault', tag: 'FavoriteFilterCubit', params: {'filterId': filterId});

    try {
      await _setDefaultFilter(filterId);
      await loadFilters();

      AppLogger.info('Filter set as default successfully', tag: 'FavoriteFilterCubit');
      AppLogger.methodExit('setAsDefault', tag: 'FavoriteFilterCubit', result: 'success');
    } catch (e, stack) {
      AppLogger.error('Failed to set default filter', tag: 'FavoriteFilterCubit', error: e, stackTrace: stack);
      emit(FavoriteFilterState.error(e.toString()));
      AppLogger.methodExit('setAsDefault', tag: 'FavoriteFilterCubit', result: 'error');
    }
  }

  /// Select a filter
  void selectFilter(FavoriteFilter? filter) {
    state.maybeWhen(
      loaded: (filterList, _) {
        emit(FavoriteFilterState.loaded(filterList, selectedFilter: filter));
      },
      orElse: () {},
    );
  }
}
