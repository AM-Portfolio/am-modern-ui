import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Status presentation for account rows.
enum AccountStatusKind { active, inactive, frozen, unknown }

/// Domain-neutral row for [AdvancedAccountsTemplate].
class AdvancedAccountRow {
  const AdvancedAccountRow({
    required this.id,
    required this.type,
    required this.title,
    this.accountId,
    this.broker,
    this.nominee,
    this.email,
    this.mobile,
    this.status,
    this.subtitle,
    this.frozen,
    this.value = 0,
    this.hasValue = false,
    this.nomineeMissing = false,
    this.statusKind = AccountStatusKind.unknown,
    this.weightPct,
  });

  final String id;

  /// `broker` | `mf` | `demat` | `nps`
  final String type;
  final String title;
  final String? accountId;
  final String? broker;
  final String? nominee;
  final String? email;
  final String? mobile;
  final String? status;
  final String? subtitle;
  final String? frozen;
  final double value;
  final bool hasValue;
  final bool nomineeMissing;
  final AccountStatusKind statusKind;
  /// Share of selected persona / household scope total (0–100).
  final double? weightPct;

  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  String get displayType {
    switch (type.toLowerCase()) {
      case 'broker':
        return 'Broker';
      case 'mf':
        return 'Mutual Fund';
      case 'demat':
        return 'Demat';
      case 'nps':
        return 'NPS';
      default:
        final t = type.trim();
        if (t.isEmpty) return '—';
        return '${t[0].toUpperCase()}${t.substring(1).toLowerCase()}';
    }
  }

  String get displayTitle => title.trim().isEmpty ? '—' : title.trim();

  String get displayAccountId {
    final id = accountId?.trim();
    return (id == null || id.isEmpty) ? '—' : id;
  }

  String get displayBroker {
    final b = broker?.trim();
    if (b != null && b.isNotEmpty) return b;
    final first = firstWordOfTitle(title);
    return first ?? '—';
  }

  /// First whitespace token of [title] for broker display fallback.
  static String? firstWordOfTitle(String? title) {
    final t = title?.trim() ?? '';
    if (t.isEmpty) return null;
    final token = t.split(RegExp(r'\s+')).firstWhere(
          (p) => p.isNotEmpty,
          orElse: () => '',
        );
    if (token.isEmpty) return null;
    return token.toUpperCase();
  }

  String get displayNominee {
    if (nomineeMissing) return 'No nominee';
    final n = nominee?.trim();
    if (n == null || n.isEmpty) return '—';
    final lower = n.toLowerCase();
    if (lower.contains('not registered') ||
        lower == 'please nominate' ||
        lower == 'no nominee') {
      return 'No nominee';
    }
    return n;
  }

  bool get showNomineeBadge =>
      nomineeMissing || (nominee != null && nominee!.trim().isNotEmpty);

  String get displayEmail {
    final e = email?.trim();
    return (e == null || e.isEmpty) ? '—' : e;
  }

  String get displayMobile {
    final m = mobile?.trim();
    return (m == null || m.isEmpty) ? '—' : m;
  }

  String get displayStatus {
    final f = frozen?.trim();
    if (f != null &&
        f.isNotEmpty &&
        !f.toLowerCase().contains('not frozen')) {
      return f;
    }
    final s = status?.trim();
    if (s == null || s.isEmpty) {
      return switch (statusKind) {
        AccountStatusKind.active => 'Active',
        AccountStatusKind.inactive => 'Inactive',
        AccountStatusKind.frozen => 'Frozen',
        AccountStatusKind.unknown => '—',
      };
    }
    return s;
  }

  String get displaySubtitle {
    final s = subtitle?.trim();
    return (s == null || s.isEmpty) ? '' : s;
  }

  String get displayValue => hasValue ? _inr.format(value) : '—';

  String get displayWeightPct {
    final p = weightPct;
    if (p == null || p <= 0) return '';
    final label = p >= 10 ? p.toStringAsFixed(0) : p.toStringAsFixed(1);
    return '$label%';
  }

  bool get isInactive => statusKind == AccountStatusKind.inactive;

  /// Brand tint for known Indian brokers.
  static Color brokerTint(String? broker, Color fallback) {
    final k = (broker ?? '').trim().toUpperCase();
    if (k.contains('FYERS')) return const Color(0xFF3B82F6);
    if (k.contains('GROWW')) return const Color(0xFF22C55E);
    if (k.contains('DHAN')) return const Color(0xFFA855F7);
    if (k.contains('UPSTOX')) return const Color(0xFFF97316);
    if (k.contains('ZERODHA') || k.contains('KITE')) {
      return const Color(0xFF387ED1);
    }
    if (k.contains('ANGEL')) return const Color(0xFFEF4444);
    return fallback;
  }

  static AccountStatusKind resolveStatusKind({
    String? status,
    String? frozen,
    bool? active,
  }) {
    final f = frozen?.trim().toLowerCase() ?? '';
    if (f.isNotEmpty && !f.contains('not frozen')) {
      return AccountStatusKind.frozen;
    }
    if (active == false) return AccountStatusKind.inactive;
    final s = status?.trim().toLowerCase() ?? '';
    if (s.contains('inactive') || s.contains('closed') || s.contains('dormant')) {
      return AccountStatusKind.inactive;
    }
    if (s.contains('frozen') || s.contains('debit')) {
      return AccountStatusKind.frozen;
    }
    if (s.contains('active') || active == true || s.isEmpty) {
      return AccountStatusKind.active;
    }
    return AccountStatusKind.unknown;
  }

  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    bool hit(String? v) => v != null && v.toLowerCase().contains(q);
    return hit(displayType) ||
        hit(displayTitle) ||
        hit(accountId) ||
        hit(broker) ||
        hit(nominee) ||
        hit(email) ||
        hit(mobile) ||
        hit(status) ||
        hit(subtitle) ||
        hit(frozen);
  }
}
