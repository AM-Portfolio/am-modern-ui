import 'package:am_design_system/am_design_system.dart';
import 'package:am_library/am_library.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/config/app_config.dart';
import 'package:am_common/am_common.dart';
import '../dtos/gmail_status_dto.dart';
import '../dtos/gmail_sync_response_dto.dart';

/// Abstract data source for Gmail sync operations
abstract class GmailRemoteDataSource {
  /// Check Gmail connection status
  Future<GmailStatusDto> checkStatus();

  /// Get Gmail OAuth connection URL
  Future<String> getConnectUrl();

  /// Sync portfolio from Gmail for a specific broker
  Future<GmailSyncResponseDto> syncPortfolio(String broker, String? pan);
}

/// Concrete implementation of Gmail remote data source
class GmailRemoteDataSourceImpl implements GmailRemoteDataSource {
  const GmailRemoteDataSourceImpl({
    required ApiClient apiClient,
    required GmailApiConfig config,
  }) : _apiClient = apiClient,
       _config = config;

  final ApiClient _apiClient;
  final GmailApiConfig _config;

  @override
  Future<GmailStatusDto> checkStatus() async {
    CommonLogger.methodEntry('checkStatus', tag: 'GmailRemoteDataSource');

    try {
      final fullUri = '${_config.baseUrl}${_config.statusEndpoint}';

      final response = await _apiClient.get<GmailStatusDto>(
        fullUri,
        parser: (data) =>
            GmailStatusDto.fromJson(data! as Map<String, dynamic>),
      );

      CommonLogger.info(
        'Gmail status checked successfully',
        tag: 'GmailRemoteDataSource',
      );

      return response;
    } catch (e) {
      CommonLogger.error(
        'Failed to check Gmail status',
        tag: 'GmailRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<String> getConnectUrl() async {
    CommonLogger.methodEntry('getConnectUrl', tag: 'GmailRemoteDataSource');

    try {
      final fullUri = '${_config.baseUrl}${_config.connectEndpoint}';

      final response = await _apiClient.get<Map<String, dynamic>>(
        fullUri,
        parser: (data) => data! as Map<String, dynamic>,
      );

      final authUrl = response['auth_url'] as String;

      CommonLogger.info(
        'Gmail auth URL fetched successfully',
        tag: 'GmailRemoteDataSource',
      );

      return authUrl;
    } catch (e) {
      CommonLogger.error(
        'Failed to get Gmail auth URL',
        tag: 'GmailRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<GmailSyncResponseDto> syncPortfolio(String broker, String? pan) async {
    CommonLogger.methodEntry(
      'syncPortfolio',
      tag: 'GmailRemoteDataSource',
      metadata: {'broker': broker},
    );

    try {
      final baseUri = '${_config.baseUrl}${_config.extractEndpoint}/$broker';

      // Append PAN query param if provided
      final fullUri = pan != null ? '$baseUri?pan=$pan' : baseUri;

      final response = await _apiClient.get<GmailSyncResponseDto>(
        fullUri,
        parser: (data) =>
            GmailSyncResponseDto.fromJson(data! as Map<String, dynamic>),
      );

      CommonLogger.info(
        'Portfolio synced successfully from Gmail: $broker',
        tag: 'GmailRemoteDataSource',
      );

      return response;
    } catch (e) {
      CommonLogger.error(
        'Failed to sync portfolio from Gmail',
        tag: 'GmailRemoteDataSource',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }
}
