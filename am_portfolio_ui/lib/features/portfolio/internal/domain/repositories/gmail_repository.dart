import '../entities/gmail_status.dart';

/// Repository interface for Gmail sync operations
abstract class GmailRepository {
  /// Check connection status
  Future<GmailStatus> checkStatus();

  /// Get connection URL
  Future<String> getConnectUrl();

  /// Sync portfolio for broker
  /// Returns number of stocks found/synced
  Future<int> syncPortfolio(String broker, String? pan);
}
