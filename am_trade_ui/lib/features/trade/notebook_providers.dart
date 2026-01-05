import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/config/app_config.dart';

import 'package:am_common/core/network/api_client.dart';
import 'internal/data/datasources/notebook_remote_datasource.dart';
import 'internal/data/repositories/notebook_repository_impl.dart';
import 'internal/domain/repositories/notebook_repository.dart';
import 'internal/domain/usecases/notebook_usecases.dart';
import 'presentation/notebook/cubit/notebook_cubit.dart';
import 'package:am_common/core/di/network_providers.dart';

// Infrastructure Providers

/// Provider for NotebookRemoteDataSource
final _notebookRemoteDataSourceProvider = FutureProvider<NotebookRemoteDataSource>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final apiConfig = await ref.watch(appConfigProvider.future);
  return NotebookRemoteDataSourceImpl(apiClient: apiClient, tradeConfig: apiConfig.api.trade);
});

/// Provider for NotebookRepository
final _notebookRepositoryProvider = FutureProvider<NotebookRepository>((ref) async {
  final remoteDataSource = await ref.watch(_notebookRemoteDataSourceProvider.future);
  return NotebookRepositoryImpl(remoteDataSource);
});

// Use Case Providers

/// Provider for GetNotebookItemsUseCase
final _getNotebookItemsUseCaseProvider = FutureProvider<GetNotebookItemsUseCase>((ref) async {
  final repository = await ref.watch(_notebookRepositoryProvider.future);
  return GetNotebookItemsUseCase(repository);
});

/// Provider for CreateNotebookItemUseCase
final _createNotebookItemUseCaseProvider = FutureProvider<CreateNotebookItemUseCase>((ref) async {
  final repository = await ref.watch(_notebookRepositoryProvider.future);
  return CreateNotebookItemUseCase(repository);
});

/// Provider for UpdateNotebookItemUseCase
final _updateNotebookItemUseCaseProvider = FutureProvider<UpdateNotebookItemUseCase>((ref) async {
  final repository = await ref.watch(_notebookRepositoryProvider.future);
  return UpdateNotebookItemUseCase(repository);
});

/// Provider for DeleteNotebookItemUseCase
final _deleteNotebookItemUseCaseProvider = FutureProvider<DeleteNotebookItemUseCase>((ref) async {
  final repository = await ref.watch(_notebookRepositoryProvider.future);
  return DeleteNotebookItemUseCase(repository);
});

/// Provider for GetNotebookTagsUseCase
final _getNotebookTagsUseCaseProvider = FutureProvider<GetNotebookTagsUseCase>((ref) async {
  final repository = await ref.watch(_notebookRepositoryProvider.future);
  return GetNotebookTagsUseCase(repository);
});

/// Provider for CreateNotebookTagUseCase
final _createNotebookTagUseCaseProvider = FutureProvider<CreateNotebookTagUseCase>((ref) async {
  final repository = await ref.watch(_notebookRepositoryProvider.future);
  return CreateNotebookTagUseCase(repository);
});

/// Provider for UpdateNotebookTagUseCase
final _updateNotebookTagUseCaseProvider = FutureProvider<UpdateNotebookTagUseCase>((ref) async {
  final repository = await ref.watch(_notebookRepositoryProvider.future);
  return UpdateNotebookTagUseCase(repository);
});

/// Provider for DeleteNotebookTagUseCase
final _deleteNotebookTagUseCaseProvider = FutureProvider<DeleteNotebookTagUseCase>((ref) async {
  final repository = await ref.watch(_notebookRepositoryProvider.future);
  return DeleteNotebookTagUseCase(repository);
});

// Cubit Provider

/// Provider for NotebookCubit
final notebookCubitProvider = FutureProvider<NotebookCubit>(
  (ref) async => NotebookCubit(
    getNotebookItemsUseCase: await ref.watch(_getNotebookItemsUseCaseProvider.future),
    createNotebookItemUseCase: await ref.watch(_createNotebookItemUseCaseProvider.future),
    updateNotebookItemUseCase: await ref.watch(_updateNotebookItemUseCaseProvider.future),
    deleteNotebookItemUseCase: await ref.watch(_deleteNotebookItemUseCaseProvider.future),
    getNotebookTagsUseCase: await ref.watch(_getNotebookTagsUseCaseProvider.future),
    createNotebookTagUseCase: await ref.watch(_createNotebookTagUseCaseProvider.future),
    updateNotebookTagUseCase: await ref.watch(_updateNotebookTagUseCaseProvider.future),
    deleteNotebookTagUseCase: await ref.watch(_deleteNotebookTagUseCaseProvider.future),
  ),
);
