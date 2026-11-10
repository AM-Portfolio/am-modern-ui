/// Result of Gmail discover (pre-password) for Import holdings.
class EmailDiscoverHit {
  const EmailDiscoverHit({
    required this.brokerId,
    required this.needsPassword,
    this.subject,
    this.date,
    this.filename,
    this.from,
  });

  final String brokerId;
  final bool needsPassword;
  final String? subject;
  final String? date;
  final String? filename;
  final String? from;
}

class EmailDiscoverMiss {
  const EmailDiscoverMiss({
    required this.brokerId,
    required this.message,
  });

  final String brokerId;
  final String message;
}

class EmailDiscoverSnapshot {
  const EmailDiscoverSnapshot({
    this.discovering = false,
    this.found = const [],
    this.missing = const [],
  });

  final bool discovering;
  final List<EmailDiscoverHit> found;
  final List<EmailDiscoverMiss> missing;

  bool get showPasswordFields =>
      found.any((h) => h.needsPassword);

  bool get hasAnyFound => found.isNotEmpty;

  Set<String> get foundBrokerIds => found.map((h) => h.brokerId).toSet();
}
