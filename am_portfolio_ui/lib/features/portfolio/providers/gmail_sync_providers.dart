import 'package:am_design_system/am_design_system.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/core/di/network_providers.dart';

import 'package:am_common/am_common.dart';

import '../internal/data/datasources/gmail_remote_data_source.dart';
import '../internal/data/repositories/gmail_repository_impl.dart';
import '../internal/domain/entities/gmail_status.dart';
import '../internal/domain/repositories/gmail_repository.dart';

part 'gmail_sync_providers.g.dart';

/// Data layer providers

@riverpod
Future<GmailRemoteDataSource> gmailRemoteDataSource(Ref ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final gmailConfig = await ref.watch(gmailApiConfigProvider.future);

  return GmailRemoteDataSourceImpl(apiClient: apiClient, config: gmailConfig);
}

@riverpod
Future<GmailRepository> gmailRepository(Ref ref) async {
  final remoteDataSource = await ref.watch(
    gmailRemoteDataSourceProvider.future,
  );
  return GmailRepositoryImpl(remoteDataSource: remoteDataSource);
}

/// Feature state providers

// Provider for connection status
@riverpod
class GmailSyncStatus extends _$GmailSyncStatus {
  @override
  Future<GmailStatus> build() async {
    return _checkStatus();
  }

  Future<GmailStatus> _checkStatus() async {
    try {
      final repository = await ref.watch(gmailRepositoryProvider.future);
      return await repository.checkStatus();
    } catch (e) {
      CommonLogger.error(
        'Failed to check Gmail status',
        tag: 'GmailSyncStatus',
        error: e,
      );
      // Return disconnected on error
      return GmailStatus.empty;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _checkStatus());
  }
}

// Provider for getting the connect URL
@riverpod
Future<String> gmailConnectUrl(Ref ref) async {
  final repository = await ref.watch(gmailRepositoryProvider.future);
  return repository.getConnectUrl();
}

// Controller for syncing portfolio
@riverpod
class GmailPortfolioSync extends _$GmailPortfolioSync {
  @override
  FutureOr<void> build() {
    // idle state
  }

  Future<int> syncPortfolio({required String broker, String? pan}) async {
    state = const AsyncValue.loading();
    try {
      final repository = await ref.read(gmailRepositoryProvider.future);
      final count = await repository.syncPortfolio(broker, pan);

      state = const AsyncValue.data(null);
      return count;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
