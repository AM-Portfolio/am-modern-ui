// Asrax MF BFF DTOs — mirrors `mf_service/app/api/schemas.py` (no NSE wire fields).

class MfMeta {
  const MfMeta({
    required this.onboardingStrict,
    this.activeDistributor = '',
    this.persistence = 'memory',
  });

  final bool onboardingStrict;
  final String activeDistributor;
  final String persistence;

  factory MfMeta.fromJson(Map<String, dynamic> json) {
    return MfMeta(
      onboardingStrict: json['onboarding_strict'] == true,
      activeDistributor: json['active_distributor']?.toString() ?? '',
      persistence: json['persistence']?.toString() ?? 'memory',
    );
  }
}

/// Persisted onboarding bind from BFF `GET /v1/mf/onboarding/status`.
class MfOnboardingStatus {
  const MfOnboardingStatus({
    this.bound = false,
    this.pan = '',
    this.clientCode = '',
    this.name = '',
    this.dob = '',
    this.email = '',
    this.mobile = '',
    this.bankAccountNo = '',
    this.bankIfsc = '',
    this.accountType = '',
    this.countryOfBirth = '',
    this.citizenship = '',
    this.taxStatus = '',
    this.uccOk = false,
    this.fatcaOk = false,
    this.bankOk = false,
    this.complete = false,
  });

  final bool bound;
  final String pan;
  final String clientCode;
  final String name;
  final String dob;
  final String email;
  final String mobile;
  final String bankAccountNo;
  final String bankIfsc;
  final String accountType;
  final String countryOfBirth;
  final String citizenship;
  final String taxStatus;
  final bool uccOk;
  final bool fatcaOk;
  final bool bankOk;
  final bool complete;

  factory MfOnboardingStatus.fromJson(Map<String, dynamic> json) {
    String s(Object? v) => v?.toString().trim() ?? '';
    return MfOnboardingStatus(
      bound: json['bound'] == true,
      pan: s(json['pan']).toUpperCase(),
      clientCode: s(json['client_code']),
      name: s(json['name']),
      dob: s(json['dob']),
      email: s(json['email']),
      mobile: s(json['mobile']),
      bankAccountNo: s(json['bank_account_no']),
      bankIfsc: s(json['bank_ifsc']).toUpperCase(),
      accountType: s(json['account_type']),
      countryOfBirth: s(json['country_of_birth']).toUpperCase(),
      citizenship: s(json['citizenship']).toUpperCase(),
      taxStatus: s(json['tax_status']),
      uccOk: json['ucc_ok'] == true,
      fatcaOk: json['fatca_ok'] == true,
      bankOk: json['bank_ok'] == true,
      complete: json['complete'] == true,
    );
  }
}

class MfDistributorOp {
  const MfDistributorOp({
    required this.ok,
    this.dryRun = false,
    this.message,
    this.ref,
    this.details = const {},
  });

  final bool ok;
  final bool dryRun;
  final String? message;
  final String? ref;
  final Map<String, dynamic> details;

  factory MfDistributorOp.fromJson(Map<String, dynamic> json) {
    return MfDistributorOp(
      ok: json['ok'] == true,
      dryRun: json['dry_run'] == true,
      message: json['message'] as String?,
      ref: json['ref']?.toString(),
      details: (json['details'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}

class MfSchemeSummary {
  const MfSchemeSummary({
    required this.isin,
    this.name,
    this.amc,
    this.category,
    this.purchaseAllowed,
    this.raw = const {},
  });

  final String isin;
  final String? name;
  final String? amc;
  final String? category;
  final bool? purchaseAllowed;
  final Map<String, dynamic> raw;

  String get displayName => name?.trim().isNotEmpty == true ? name! : isin;

  factory MfSchemeSummary.fromJson(Map<String, dynamic> json) {
    final isin = (json['isin'] ??
            json['scheme_id'] ??
            json['schemeId'] ??
            json['id'] ??
            '')
        .toString()
        .trim()
        .toUpperCase();
    return MfSchemeSummary(
      isin: isin,
      name: (json['name'] ?? json['scheme_name'] ?? json['schemeName'])
          ?.toString(),
      amc: (json['amc'] ??
              json['amc_name'] ??
              json['amcName'] ??
              json['amcCode'])
          ?.toString(),
      category: (json['category'] ?? json['scheme_category'])?.toString(),
      purchaseAllowed: _asBool(
        json['purchase_allowed'] ?? json['purchaseAllowed'],
      ),
      raw: json,
    );
  }
}

/// Seed fallback uses `"Y"`/`"N"`; market-data may send bool.
bool? _asBool(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  final s = value.toString().trim().toLowerCase();
  if (s == 'y' || s == 'yes' || s == 'true' || s == '1') return true;
  if (s == 'n' || s == 'no' || s == 'false' || s == '0') return false;
  return null;
}

class MfCatalogResult {
  const MfCatalogResult({
    required this.items,
    this.source,
    this.message,
    this.unavailable = false,
  });

  final List<MfSchemeSummary> items;
  final String? source;
  final String? message;
  final bool unavailable;

  bool get isSeedFallback =>
      (source ?? '').toLowerCase().contains('seed') ||
      (message ?? '').toUpperCase().contains('CATALOG_UNAVAILABLE');
}

class MfNavPoint {
  const MfNavPoint({required this.date, required this.nav});

  final String date;
  final double nav;
}

class MfPerformance {
  const MfPerformance({
    this.isin,
    this.latestNav,
    this.latestNavDate,
    this.returnsPct = const {},
    this.source,
    this.note,
    this.unavailable = false,
  });

  final String? isin;
  final double? latestNav;
  final String? latestNavDate;
  final Map<String, double?> returnsPct;
  final String? source;
  final String? note;
  final bool unavailable;

  factory MfPerformance.fromJson(Map<String, dynamic> json) {
    final raw = json['returnsPct'] ?? json['returns_pct'] ?? json['returns'];
    final returns = <String, double?>{};
    if (raw is Map) {
      for (final e in raw.entries) {
        returns[e.key.toString()] = _asDouble(e.value);
      }
    }
    final source = json['source']?.toString();
    return MfPerformance(
      isin: (json['isin'] ?? json['schemeCode'])?.toString(),
      latestNav: _asDouble(json['latestNav'] ?? json['latest_nav'] ?? json['nav']),
      latestNavDate:
          (json['latestNavDate'] ?? json['latest_nav_date'] ?? json['navDate'])
              ?.toString(),
      returnsPct: returns,
      source: source,
      note: json['note']?.toString(),
      unavailable: json['unavailable'] == true ||
          (source ?? '').toLowerCase().contains('seed') ||
          json.containsKey('error'),
    );
  }
}

class MfOrder {
  const MfOrder({
    required this.id,
    required this.userId,
    required this.distributor,
    required this.side,
    required this.status,
    required this.isin,
    required this.createdAt,
    required this.updatedAt,
    this.toIsin,
    this.amount,
    this.units,
    this.distributorOrderRef,
    this.dryRun = false,
    this.idempotencyKey,
    this.failureCode,
    this.failureMessage,
  });

  final String id;
  final String userId;
  final String distributor;
  final String side;
  final String status;
  final String isin;
  final String? toIsin;
  final double? amount;
  final double? units;
  final String? distributorOrderRef;
  final bool dryRun;
  final String? idempotencyKey;
  final String? failureCode;
  final String? failureMessage;
  final String createdAt;
  final String updatedAt;

  bool get isTerminal =>
      status == 'paid' ||
      status == 'allotted' ||
      status == 'failed' ||
      status == 'cancelled' ||
      status == 'dry_run';

  bool get canPay =>
      side == 'purchase' &&
      (status == 'submitted' ||
          status == 'payment_pending' ||
          status == 'dry_run');

  bool get canCancel =>
      status != 'paid' && status != 'allotted' && status != 'cancelled';

  /// BFF may append `Use payment link: https://…` on non-trusted pay failures.
  String? get paymentLink {
    final msg = failureMessage;
    if (msg == null || msg.isEmpty) return null;
    final match = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    ).firstMatch(msg);
    return match?.group(0);
  }

  bool get isNonTrustedPayFailure {
    final msg = (failureMessage ?? '').toLowerCase();
    return msg.contains('non-trusted') || msg.contains('non trusted');
  }

  factory MfOrder.fromJson(Map<String, dynamic> json) {
    return MfOrder(
      id: json['id'].toString(),
      userId: json['user_id']?.toString() ?? '',
      distributor: json['distributor']?.toString() ?? 'nse',
      side: json['side']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isin: json['isin']?.toString() ?? '',
      toIsin: json['to_isin']?.toString(),
      amount: _asDouble(json['amount']),
      units: _asDouble(json['units']),
      distributorOrderRef: json['distributor_order_ref']?.toString(),
      dryRun: json['dry_run'] == true,
      idempotencyKey: json['idempotency_key']?.toString(),
      failureCode: json['failure_code']?.toString(),
      failureMessage: json['failure_message']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

class MfMandate {
  const MfMandate({
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    required this.distributor,
    required this.createdAt,
    this.distributorMandateRef,
    this.dryRun = false,
    this.failureMessage,
  });

  final String id;
  final String userId;
  final double amount;
  final String status;
  final String distributor;
  final String? distributorMandateRef;
  final bool dryRun;
  final String? failureMessage;
  final String createdAt;

  factory MfMandate.fromJson(Map<String, dynamic> json) {
    return MfMandate(
      id: json['id'].toString(),
      userId: json['user_id']?.toString() ?? '',
      amount: _asDouble(json['amount']) ?? 0,
      status: json['status']?.toString() ?? '',
      distributor: json['distributor']?.toString() ?? 'nse',
      distributorMandateRef: json['distributor_mandate_ref']?.toString(),
      dryRun: json['dry_run'] == true,
      failureMessage: json['failure_message']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class MfSip {
  const MfSip({
    required this.id,
    required this.userId,
    required this.isin,
    required this.installmentAmount,
    required this.frequency,
    required this.status,
    required this.distributor,
    required this.createdAt,
    this.distributorSipRef,
    this.xsip = false,
    this.dryRun = false,
    this.failureMessage,
  });

  final String id;
  final String userId;
  final String isin;
  final double installmentAmount;
  final String frequency;
  final String status;
  final String distributor;
  final String? distributorSipRef;
  final bool xsip;
  final bool dryRun;
  final String? failureMessage;
  final String createdAt;

  bool get canPause {
    final s = status.toLowerCase();
    return s == 'active' || s == 'dry_run';
  }

  bool get canResume => status.toLowerCase() == 'paused';

  bool get canCancel {
    final s = status.toLowerCase();
    return s != 'cancelled' && s != 'failed';
  }

  MfSip copyWith({
    String? status,
    String? failureMessage,
  }) {
    return MfSip(
      id: id,
      userId: userId,
      isin: isin,
      installmentAmount: installmentAmount,
      frequency: frequency,
      status: status ?? this.status,
      distributor: distributor,
      createdAt: createdAt,
      distributorSipRef: distributorSipRef,
      xsip: xsip,
      dryRun: dryRun,
      failureMessage: failureMessage ?? this.failureMessage,
    );
  }

  factory MfSip.fromJson(Map<String, dynamic> json) {
    return MfSip(
      id: json['id'].toString(),
      userId: json['user_id']?.toString() ?? '',
      isin: json['isin']?.toString() ?? '',
      installmentAmount: _asDouble(json['installment_amount']) ?? 0,
      frequency: json['frequency']?.toString() ?? 'MONTHLY',
      status: json['status']?.toString() ?? '',
      distributor: json['distributor']?.toString() ?? 'nse',
      distributorSipRef: json['distributor_sip_ref']?.toString(),
      xsip: json['xsip'] == true,
      dryRun: json['dry_run'] == true,
      failureMessage: json['failure_message']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class MfHoldingLot {
  const MfHoldingLot({
    required this.userId,
    required this.isin,
    required this.units,
    required this.distributor,
    this.schemeCode,
    this.schemeName,
    this.avgNav,
    this.folio,
    this.allottedAt,
  });

  final String userId;
  final String isin;
  final double units;
  final String distributor;
  final String? schemeCode;
  final String? schemeName;
  final double? avgNav;
  final String? folio;
  final String? allottedAt;

  factory MfHoldingLot.fromJson(Map<String, dynamic> json) {
    return MfHoldingLot(
      userId: json['user_id']?.toString() ?? '',
      isin: json['isin']?.toString() ?? '',
      units: _asDouble(json['units']) ?? 0,
      distributor: json['distributor']?.toString() ?? 'nse',
      schemeCode: json['scheme_code']?.toString(),
      schemeName: json['scheme_name']?.toString(),
      avgNav: _asDouble(json['avg_nav']),
      folio: json['folio']?.toString(),
      allottedAt: json['allotted_at']?.toString(),
    );
  }
}

double? _asDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
