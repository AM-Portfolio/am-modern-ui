import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/config/app_config.dart';

import 'package:am_library/am_library.dart';
import 'internal/data/datasources/journal_remote_data_source.dart';
import 'internal/data/repositories/journal_repository_impl.dart';
import 'internal/domain/repositories/journal_repository.dart';
import 'internal/domain/usecases/create_journal_entry_usecase.dart';
import 'internal/domain/usecases/delete_journal_entry_usecase.dart';
import 'internal/domain/usecases/get_journal_entries_usecase.dart';
import 'internal/domain/usecases/update_journal_entry_usecase.dart';
import 'presentation/cubit/journal/journal_cubit.dart';
import 'package:am_common/core/di/network_providers.dart';

// Infrastructure Providers

/// Provider for JournalRemoteDataSource
final _journalRemoteDataSourceProvider = FutureProvider<JournalRemoteDataSource>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final apiConfig = await ref.watch(appConfigProvider.future);
  return JournalRemoteDataSourceImpl(apiClient: apiClient, tradeConfig: apiConfig.api.trade);
});

/// Provider for JournalRepository
final _journalRepositoryProvider = FutureProvider<JournalRepository>((ref) async {
  final remoteDataSource = await ref.watch(_journalRemoteDataSourceProvider.future);
  return JournalRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Use Case Providers

/// Provider for GetJournalEntriesUseCase
final _getJournalEntriesUseCaseProvider = FutureProvider<GetJournalEntriesUseCase>((ref) async {
  final repository = await ref.watch(_journalRepositoryProvider.future);
  return GetJournalEntriesUseCase(repository);
});

/// Provider for CreateJournalEntryUseCase
final _createJournalEntryUseCaseProvider = FutureProvider<CreateJournalEntryUseCase>((ref) async {
  final repository = await ref.watch(_journalRepositoryProvider.future);
  return CreateJournalEntryUseCase(repository);
});

/// Provider for UpdateJournalEntryUseCase
final _updateJournalEntryUseCaseProvider = FutureProvider<UpdateJournalEntryUseCase>((ref) async {
  final repository = await ref.watch(_journalRepositoryProvider.future);
  return UpdateJournalEntryUseCase(repository);
});

/// Provider for DeleteJournalEntryUseCase
final _deleteJournalEntryUseCaseProvider = FutureProvider<DeleteJournalEntryUseCase>((ref) async {
  final repository = await ref.watch(_journalRepositoryProvider.future);
  return DeleteJournalEntryUseCase(repository);
});

// Cubit Provider

/// Provider for JournalCubit
final journalCubitProvider = FutureProvider<JournalCubit>(
  (ref) async => JournalCubit(
    getJournalEntries: await ref.watch(_getJournalEntriesUseCaseProvider.future),
    createJournalEntry: await ref.watch(_createJournalEntryUseCaseProvider.future),
    updateJournalEntry: await ref.watch(_updateJournalEntryUseCaseProvider.future),
    deleteJournalEntry: await ref.watch(_deleteJournalEntryUseCaseProvider.future),
  ),
);
