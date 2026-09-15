/// Referral summary from `GET /subscriptions/referrals/me`.
class ReferralSummary {
  const ReferralSummary({
    required this.code,
    required this.shareUrl,
    required this.status,
    required this.qualifiedCount,
    required this.activeCount,
    required this.remaining,
    required this.lifetimeCap,
    required this.dailyUsed,
    required this.dailyCap,
    required this.dailyRemaining,
    this.joined,
  });

  final String code;
  final String shareUrl;
  final String status;
  final int qualifiedCount;
  final int activeCount;
  final int remaining;
  final int lifetimeCap;
  final int dailyUsed;
  final int dailyCap;
  final int dailyRemaining;
  final ReferralJoined? joined;

  factory ReferralSummary.fromJson(Map<String, dynamic> json) {
    final joinedRaw = json['joined'];
    return ReferralSummary(
      code: (json['code'] as String? ?? '').toUpperCase(),
      shareUrl: json['share_url'] as String? ?? '',
      status: json['status'] as String? ?? '',
      qualifiedCount: _asInt(json['qualified_count']),
      activeCount: _asInt(json['active_count']),
      remaining: _asInt(json['remaining']),
      lifetimeCap: _asInt(json['lifetime_cap'], fallback: 12),
      dailyUsed: _asInt(json['daily_used']),
      dailyCap: _asInt(json['daily_cap'], fallback: 3),
      dailyRemaining: _asInt(json['daily_remaining']),
      joined: joinedRaw is Map<String, dynamic>
          ? ReferralJoined.fromJson(joinedRaw)
          : null,
    );
  }
}

/// Referee view — invite code this user joined with (first-run sheet).
class ReferralJoined {
  const ReferralJoined({
    required this.code,
    required this.status,
    this.rejectReason,
  });

  final String code;
  final String status;
  final String? rejectReason;

  factory ReferralJoined.fromJson(Map<String, dynamic> json) {
    return ReferralJoined(
      code: (json['code'] as String? ?? '').toUpperCase(),
      status: json['status'] as String? ?? '',
      rejectReason: json['reject_reason'] as String?,
    );
  }
}

/// Referrer history row — date + status only (no invitee email).
class ReferralHistoryItem {
  const ReferralHistoryItem({
    required this.id,
    required this.status,
    this.rejectReason,
    this.createdAt,
    this.qualifiedAt,
    this.codeHint,
  });

  final String id;
  final String status;
  final String? rejectReason;
  final DateTime? createdAt;
  final DateTime? qualifiedAt;
  final String? codeHint;

  factory ReferralHistoryItem.fromJson(Map<String, dynamic> json) {
    return ReferralHistoryItem(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      rejectReason: json['reject_reason'] as String?,
      createdAt: _asDate(json['created_at']),
      qualifiedAt: _asDate(json['qualified_at']),
      codeHint: json['code_hint'] as String?,
    );
  }
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

DateTime? _asDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
