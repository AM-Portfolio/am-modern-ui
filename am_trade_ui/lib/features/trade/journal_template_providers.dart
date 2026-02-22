import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/config/app_config.dart';
import 'package:am_library/am_library.dart';
import 'internal/data/datasources/journal_template_remote_datasource.dart';
import 'internal/data/repositories/journal_template_repository_impl.dart';
import 'internal/domain/repositories/journal_template_repository.dart';
import 'internal/domain/usecases/create_template_usecase.dart';
import 'internal/domain/usecases/delete_template_usecase.dart';
import 'internal/domain/usecases/get_templates_usecase.dart';
import 'internal/domain/usecases/toggle_favorite_template_usecase.dart';
import 'internal/domain/usecases/use_template_usecase.dart';
import 'presentation/cubit/journal_template/journal_template_cubit.dart';

/// Provider for journal template remote data source
final journalTemplateRemoteDataSourceProvider =
    Provider<JournalTemplateRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final config = ref.watch(appConfigProvider);
  return JournalTemplateRemoteDataSourceImpl(
    apiClient: apiClient,
    tradeConfig: config.api.trade,
  );
});

/// Provider for journal template repository
final journalTemplateRepositoryProvider =
    Provider<JournalTemplateRepository>((ref) {
  final remoteDataSource = ref.watch(journalTemplateRemoteDataSourceProvider);
  return JournalTemplateRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Provider for get templates use case
final getTemplatesUseCaseProvider = Provider<GetTemplatesUseCase>((ref) {
  final repository = ref.watch(journalTemplateRepositoryProvider);
  return GetTemplatesUseCase(repository);
});

/// Provider for create template use case
final createTemplateUseCaseProvider = Provider<CreateTemplateUseCase>((ref) {
  final repository = ref.watch(journalTemplateRepositoryProvider);
  return CreateTemplateUseCase(repository);
});

/// Provider for use template use case
final useTemplateUseCaseProvider = Provider<UseTemplateUseCase>((ref) {
  final repository = ref.watch(journalTemplateRepositoryProvider);
  return UseTemplateUseCase(repository);
});

/// Provider for toggle favorite template use case
final toggleFavoriteTemplateUseCaseProvider =
    Provider<ToggleFavoriteTemplateUseCase>((ref) {
  final repository = ref.watch(journalTemplateRepositoryProvider);
  return ToggleFavoriteTemplateUseCase(repository);
});

/// Provider for delete template use case
final deleteTemplateUseCaseProvider = Provider<DeleteTemplateUseCase>((ref) {
  final repository = ref.watch(journalTemplateRepositoryProvider);
  return DeleteTemplateUseCase(repository);
});

/// Provider for journal template cubit
final journalTemplateCubitProvider =
    Provider.autoDispose<JournalTemplateCubit>((ref) {
  return JournalTemplateCubit(
    getTemplatesUseCase: ref.watch(getTemplatesUseCaseProvider),
    createTemplateUseCase: ref.watch(createTemplateUseCaseProvider),
    useTemplateUseCase: ref.watch(useTemplateUseCaseProvider),
    toggleFavoriteTemplateUseCase:
        ref.watch(toggleFavoriteTemplateUseCaseProvider),
    deleteTemplateUseCase: ref.watch(deleteTemplateUseCaseProvider),
  );
});
