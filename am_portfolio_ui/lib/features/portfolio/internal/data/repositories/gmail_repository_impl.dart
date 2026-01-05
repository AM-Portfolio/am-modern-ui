import 'package:am_design_system/am_design_system.dart';
import 'package:am_common/core/utils/logger.dart';
import '../../domain/entities/gmail_status.dart';
import '../../domain/repositories/gmail_repository.dart';
import '../datasources/gmail_remote_data_source.dart';

/// Concrete implementation of GmailRepository
class GmailRepositoryImpl implements GmailRepository {
  const GmailRepositoryImpl({
    required GmailRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final GmailRemoteDataSource _remoteDataSource;

  @override
  Future<GmailStatus> checkStatus() async {
    try {
      final dto = await _remoteDataSource.checkStatus();
      return GmailStatus(
        connected: dto.connected,
        email: dto.email,
        name: dto.name,
      );
    } catch (e) {
      CommonLogger.error(
        'Repository: Failed to check Gmail status',
        tag: 'GmailRepository',
        error: e,
      );
      // Return disconnected status on error for UI resilience, or rethrow based on strategy
      // For now we rethrow to let UI handle the error state
      rethrow;
    }
  }

  @override
  Future<String> getConnectUrl() async {
    try {
      return await _remoteDataSource.getConnectUrl();
    } catch (e) {
      CommonLogger.error(
        'Repository: Failed to get auth URL',
        tag: 'GmailRepository',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<int> syncPortfolio(String broker, String? pan) async {
    try {
      final responseDto = await _remoteDataSource.syncPortfolio(broker, pan);
      return responseDto.count;
    } catch (e) {
      CommonLogger.error(
        'Repository: Failed to sync portfolio',
        tag: 'GmailRepository',
        error: e,
      );
      rethrow;
    }
  }
}
