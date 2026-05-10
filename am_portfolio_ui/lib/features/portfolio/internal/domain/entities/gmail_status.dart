import 'package:equatable/equatable.dart';

/// Domain entity representing Gmail connection status
class GmailStatus extends Equatable {
  const GmailStatus({required this.connected, this.email, this.name});

  /// Whether Gmail is connected
  final bool connected;

  /// Connected email address (if any)
  final String? email;

  /// Connected user name (if any)
  final String? name;

  /// Empty state
  static const empty = GmailStatus(connected: false);

  @override
  List<Object?> get props => [connected, email, name];
}
