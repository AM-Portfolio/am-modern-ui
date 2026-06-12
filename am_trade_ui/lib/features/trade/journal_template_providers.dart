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

import 'package:am_common/core/di/network_providers.dart';

/// Provider for journal template remote data source
final journalTemplateRemoteDataSourceProvider =
    FutureProvider<JournalTemplateRemoteDataSource>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final config = await ref.watch(appConfigProvider.future);
  return JournalTemplateRemoteDataSourceImpl(
    apiClient: apiClient,
    tradeConfig: config.api.trade,
  );
});

/// Provider for journal template repository
final journalTemplateRepositoryProvider =
    FutureProvider<JournalTemplateRepository>((ref) async {
  final remoteDataSource = await ref.watch(journalTemplateRemoteDataSourceProvider.future);
  return JournalTemplateRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Provider for get templates use case
final getTemplatesUseCaseProvider = FutureProvider<GetTemplatesUseCase>((ref) async {
  final repository = await ref.watch(journalTemplateRepositoryProvider.future);
  return GetTemplatesUseCase(repository);
});

/// Provider for create template use case
final createTemplateUseCaseProvider = FutureProvider<CreateTemplateUseCase>((ref) async {
  final repository = await ref.watch(journalTemplateRepositoryProvider.future);
  return CreateTemplateUseCase(repository);
});

/// Provider for use template use case
final useTemplateUseCaseProvider = FutureProvider<UseTemplateUseCase>((ref) async {
  final repository = await ref.watch(journalTemplateRepositoryProvider.future);
  return UseTemplateUseCase(repository);
});

/// Provider for toggle favorite template use case
final toggleFavoriteTemplateUseCaseProvider =
    FutureProvider<ToggleFavoriteTemplateUseCase>((ref) async {
  final repository = await ref.watch(journalTemplateRepositoryProvider.future);
  return ToggleFavoriteTemplateUseCase(repository);
});

/// Provider for delete template use case
final deleteTemplateUseCaseProvider = FutureProvider<DeleteTemplateUseCase>((ref) async {
  final repository = await ref.watch(journalTemplateRepositoryProvider.future);
  return DeleteTemplateUseCase(repository);
});

/// Provider for journal template cubit
final journalTemplateCubitProvider =
    FutureProvider.autoDispose<JournalTemplateCubit>((ref) async {
  return JournalTemplateCubit(
    getTemplatesUseCase: await ref.watch(getTemplatesUseCaseProvider.future),
    createTemplateUseCase: await ref.watch(createTemplateUseCaseProvider.future),
    useTemplateUseCase: await ref.watch(useTemplateUseCaseProvider.future),
    toggleFavoriteTemplateUseCase:
        await ref.watch(toggleFavoriteTemplateUseCaseProvider.future),
    deleteTemplateUseCase: await ref.watch(deleteTemplateUseCaseProvider.future),
  );
});
