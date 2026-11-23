import 'mf_dto.dart';

/// Presentation model for Explore / recommendation cards.
class MfSchemeView {
  const MfSchemeView({
    required this.summary,
    required this.shortName,
    required this.category,
    required this.subCategory,
    required this.planType,
    required this.option,
    required this.riskLevel,
    this.amcName,
    this.nav,
    this.navDate,
    this.navChange,
    this.navChangePercent,
    this.returns = const {},
    this.minLumpsum,
    this.minSip,
    this.aum,
    this.expenseRatio,
    this.metricsIllustrative = false,
  });

  final MfSchemeSummary summary;
  final String shortName;
  final String category;
  final String subCategory;
  final String planType;
  final String option;
  final String riskLevel;
  final String? amcName;
  final double? nav;
  final String? navDate;
  final double? navChange;
  final double? navChangePercent;
  final Map<String, double?> returns;
  final double? minLumpsum;
  final double? minSip;
  final double? aum;
  final double? expenseRatio;
  final bool metricsIllustrative;

  String get isin => summary.isin;

  double? returnFor(String period) => returns[period];

  String get schemeCode =>
      (summary.raw['schemeCode'] ?? summary.raw['scheme_code'] ?? '')
          .toString()
          .trim();

  /// Upstox-style meta under the title: Category · SubCategory · Plan Option.
  String get metaLine {
    final plan = _displayPlanType(planType);
    final opt = _displayOption(option);
    final planOpt = [plan, opt].where((s) => s.isNotEmpty).join(' ');
    return [
      if (category.isNotEmpty) category,
      if (subCategory.isNotEmpty &&
          subCategory.toLowerCase() != category.toLowerCase())
        subCategory,
      if (planOpt.isNotEmpty) planOpt,
    ].join(' · ');
  }

  /// Prefer human AMC label over raw NSE amcCode (e.g. IIFLMUTUALFUND_MF / 112121).
  String get amcLabel {
    final raw = (amcName ?? '').trim();
    final code = (summary.raw['amcCode'] ?? summary.raw['amc_code'] ?? raw)
        .toString()
        .trim()
        .toUpperCase();
    final mapped = knownAmcDisplayNames[code];
    if (mapped != null) return mapped;
    if (_looksLikeAmcCode(raw) || _looksLikeAmcCode(code)) {
      final fromName = _amcFromSchemeName(summary.displayName);
      if (fromName.isNotEmpty) return fromName;
    }
    if (raw.isEmpty) return _amcFromSchemeName(summary.displayName);
    return raw;
  }

  /// True when AUM/TER came from a trusted enrichment source (not sample/fixture).
  bool get enrichmentTrusted {
    final src = (summary.raw['enrichmentSource'] ??
            summary.raw['enrichment_source'] ??
            summary.raw['metricsSource'] ??
            '')
        .toString()
        .toLowerCase()
        .trim();
    if (src.isEmpty) return false;
    if (src.contains('sample') || src.contains('fixture') || src.contains('seed')) {
      return false;
    }
    return src == 'amfi' || src.contains('amfi') || src.contains('vendor');
  }

  double? get displayAum => enrichmentTrusted ? aum : null;

  double? get displayExpenseRatio => enrichmentTrusted ? expenseRatio : null;

  /// SCH exit-load text when present (never invent).
  String? get exitLoad {
    final raw = (summary.raw['exitLoad'] ?? summary.raw['exit_load'] ?? '')
        .toString()
        .trim();
    return raw.isEmpty ? null : raw;
  }

  String? get faceValue {
    final raw = (summary.raw['faceValue'] ?? summary.raw['face_value'] ?? '')
        .toString()
        .trim();
    return raw.isEmpty ? null : raw;
  }

  String? get purchaseCutoffTime {
    final raw = (summary.raw['purchaseCutoffTime'] ??
            summary.raw['purchase_cutoff_time'] ??
            '')
        .toString()
        .trim();
    return raw.isEmpty ? null : raw;
  }

  String? get lockInPeriod {
    final flag = (summary.raw['lockInPeriodFlag'] ??
            summary.raw['lock_in_period_flag'] ??
            '')
        .toString()
        .trim()
        .toUpperCase();
    final period = (summary.raw['lockInPeriod'] ??
            summary.raw['lock_in_period'] ??
            '')
        .toString()
        .trim();
    if (period.isEmpty) return null;
    if (flag == 'N' || flag == 'NO' || flag == '0') return null;
    return period;
  }

  /// Vendor analytics only when enrichment is trusted.
  String? get benchmarkName {
    if (!enrichmentTrusted) return null;
    final raw =
        (summary.raw['benchmarkName'] ?? summary.raw['benchmark_name'] ?? '')
            .toString()
            .trim();
    return raw.isEmpty ? null : raw;
  }

  /// EOD NAV only — never treat as equity LTP. True when navDate is >1 calendar day old.
  bool get navStale {
    if (metricsIllustrative || navDate == null || navDate!.isEmpty) return false;
    final raw = navDate!.trim();
    final parsed = DateTime.tryParse(raw.length >= 10 ? raw.substring(0, 10) : raw);
    if (parsed == null) return false;
    final today = DateTime.now();
    final asOf = DateTime(parsed.year, parsed.month, parsed.day);
    final nowDay = DateTime(today.year, today.month, today.day);
    return nowDay.difference(asOf).inDays > 1;
  }

  /// Caption for cards/detail: EOD + date, or seed, or stale warning.
  String get navCaption {
    if (metricsIllustrative) {
      return 'Catalog seed only · no EOD NAV';
    }
    if (nav == null) return '';
    final asOf = navDate != null ? ' as of $navDate' : '';
    if (navStale) {
      return 'EOD NAV$asOf · stale (not live LTP)';
    }
    return 'EOD NAV$asOf';
  }

  /// Invest/SIP when purchase allowed. Seed-fallback identity rows are browse-only
  /// except the two UAT-mapped ISINs (BFF default SchemeIdMapper).
  bool get digPurchaseEnabled {
    if (summary.purchaseAllowed == false) return false;
    if (!metricsIllustrative) return true;
    return digInvestableIsins.contains(isin);
  }

  factory MfSchemeView.fromSummary(MfSchemeSummary s) {
    final raw = Map<String, dynamic>.from(s.raw);
    final source = (raw['source'] ?? raw['metricsSource'] ?? '')
        .toString()
        .toLowerCase();
    final isSeedPath = source.contains('seed');

    final name = s.displayName;
    final upper = name.toUpperCase();
    final category = (raw['sebiCategory'] ??
            raw['sebi_category'] ??
            raw['schemeType'] ??
            raw['category'] ??
            s.category)
        ?.toString()
        .trim();
    final sub = (raw['sebiSubCategory'] ??
            raw['sebi_sub_category'] ??
            raw['subCategory'] ??
            raw['scheme_subtype'] ??
            raw['schemeSubtype'])
        ?.toString()
        .trim();
    final plan = (raw['planType'] ?? raw['plan_type'])?.toString().trim();
    final optionRaw = raw['option']?.toString().trim();
    final risk = (raw['riskometer'] ?? raw['riskLevel'])?.toString().trim();
    final returnsRaw = raw['returns'] ?? raw['returnsPct'];
    final returns = <String, double?>{};
    // Live catalog only — never invent client-side NAV/returns.
    if (!isSeedPath && returnsRaw is Map) {
      for (final e in returnsRaw.entries) {
        returns[e.key.toString()] = _asDouble(e.value);
      }
    }

    // Prefer name-derived option so IDCW Payout vs Reinvest is visible on cards.
    final option = optionLabelFromSchemeName(name, hint: optionRaw);

    return MfSchemeView(
      summary: s,
      shortName: shortNameForDisplay(name, option: option),
      category: (category != null && category.isNotEmpty)
          ? _normalizeCategory(category)
          : _inferCategory(upper),
      subCategory: (sub != null && sub.isNotEmpty)
          ? sub
          : _inferSubCategory(upper),
      planType: (plan != null && plan.isNotEmpty)
          ? plan
          : (upper.contains('DIRECT') ? 'DIRECT' : 'REGULAR'),
      option: option,
      riskLevel: (risk != null && risk.isNotEmpty) ? risk : 'MODERATE',
      amcName: (raw['amcName'] ?? raw['amc'] ?? s.amc)?.toString(),
      nav: isSeedPath
          ? null
          : _asDouble(raw['nav'] ?? raw['latest_nav'] ?? raw['latestNav']),
      navDate: isSeedPath
          ? null
          : (raw['navDate'] ?? raw['nav_date'] ?? raw['asOf'])?.toString(),
      navChange: isSeedPath ? null : _asDouble(raw['navChange']),
      navChangePercent: isSeedPath ? null : _asDouble(raw['navChangePercent']),
      returns: returns,
      minLumpsum: _asDouble(
        raw['minLumpsum'] ??
            raw['min_lumpsum'] ??
            raw['min_investment'] ??
            raw['minInvestment'] ??
            raw['newPurchaseMinAmount'] ??
            raw['new_purchase_min_amount'],
      ),
      minSip: _asDouble(
        raw['minSip'] ??
            raw['min_sip'] ??
            raw['sipMinAmount'] ??
            raw['sip_min_amount'],
      ),
      aum: isSeedPath ? null : _asDouble(raw['aum']),
      expenseRatio: isSeedPath
          ? null
          : _asDouble(raw['expenseRatio'] ?? raw['expense_ratio']),
      metricsIllustrative: isSeedPath,
    );
  }
}

/// ISINs always present in MF BFF [SchemeIdMapper] dig defaults.
const digInvestableIsins = <String>{
  'INF579M01AV5',
  'INF579M01AW3',
};

/// Top NSE amc_code → retail display name (SIP master is preferred when present).
const knownAmcDisplayNames = <String, String>{
  'IIFLMUTUALFUND_MF': '360 ONE',
  // SIF master codes — distinct from retail 360 ONE MF (many SCH rows still lack EOD NAV).
  '360ONEMF_SIF': '360 ONE SIF',
  '112121': 'Old Bridge',
  'HDFC Mutual Fund': 'HDFC',
  'HDFCMUTUALFUND_MF': 'HDFC',
  'SBIMUTUALFUND_MF': 'SBI',
  'ICICIPRUMUTUALFUND_MF': 'ICICI Prudential',
  'NIPPONINDIAMUTUALFUND_MF': 'Nippon India',
  'AXISMUTUALFUND_MF': 'Axis',
  'UTIMUTUALFUND_MF': 'UTI',
};

/// Quick Explore search chips (prove multi-AMC catalog, break 360 wall).
const exploreAmcSearchChips = <String>[
  'HDFC',
  'SBI',
  'ICICI',
  'Nippon',
  'Axis',
  'UTI',
  '360 ONE',
];

/// One Explore card per ISIN — prefer buyable, Growth, non-`-L1` scheme codes.
List<MfSchemeView> dedupeSchemesByIsin(List<MfSchemeView> input) {
  final best = <String, MfSchemeView>{};
  var orphan = 0;
  for (final v in input) {
    var key = v.isin.trim().toUpperCase();
    if (key.isEmpty) {
      key = 'NOISIN-${v.schemeCode.isNotEmpty ? v.schemeCode : orphan++}';
    }
    final prev = best[key];
    if (prev == null || exploreRank(v) > exploreRank(prev)) {
      best[key] = v;
    } else if (exploreRank(v) == exploreRank(prev) &&
        v.schemeCode.compareTo(prev.schemeCode) < 0) {
      best[key] = v;
    }
  }
  return best.values.toList();
}

/// Higher = preferred Explore representative for a shared ISIN.
int exploreRank(MfSchemeView v) {
  var score = 0;
  if (v.summary.purchaseAllowed == true) score += 100;
  if (v.summary.purchaseAllowed != false) score += 10;
  final opt = v.option.toUpperCase();
  if (opt == 'GROWTH' || opt.contains('GROWTH')) score += 50;
  final code = v.schemeCode.toUpperCase();
  if (code.isNotEmpty && !code.contains('-L1')) score += 20;
  return score;
}

/// Clean fund title for cards (option lives in [MfSchemeView.metaLine]).
String shortNameForDisplay(String name, {String? option}) {
  // [option] kept for call-site clarity; metaLine owns Growth/IDCW.
  var s = name
      .replaceAll(RegExp(r'\s*-\s*REGULAR PLAN\s*', caseSensitive: false), ' - ')
      .replaceAll(RegExp(r'\s*-\s*DIRECT PLAN\s*', caseSensitive: false), ' - ')
      .replaceAll(RegExp(r'\s*-\s*GROWTH.*$', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s*-\s*IDCW.*$', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (s.isEmpty) s = name.trim();
  s = s.replaceAll(RegExp(r'\s*-\s*$'), '').trim();
  if (s.length > 48) return '${s.substring(0, 45)}…';
  return s;
}

/// Growth / IDCW Payout / IDCW Reinvest from NSE scheme name (and optional hint).
String optionLabelFromSchemeName(String name, {String? hint}) {
  final upper = name.toUpperCase();
  final hintU = (hint ?? '').toUpperCase();
  final isIdcw = upper.contains('IDCW') || hintU.contains('IDCW');
  if (isIdcw) {
    if (upper.contains('REINVEST') || hintU.contains('REINVEST')) {
      return 'IDCW Reinvest';
    }
    if (upper.contains('PAYOUT') || hintU.contains('PAYOUT')) {
      return 'IDCW Payout';
    }
    return 'IDCW';
  }
  if (upper.contains('GROWTH') ||
      hintU.contains('GROWTH') ||
      hintU.isEmpty) {
    return 'Growth';
  }
  return hint!.trim();
}

bool _looksLikeAmcCode(String value) {
  final v = value.trim();
  if (v.isEmpty) return true;
  final u = v.toUpperCase();
  if (u.contains('_') || u.endsWith('_MF')) return true;
  // NSE sometimes uses numeric member codes (e.g. Old Bridge 112121).
  if (RegExp(r'^\d+$').hasMatch(v)) return true;
  return false;
}

String _displayPlanType(String plan) {
  final u = plan.trim().toUpperCase();
  if (u.isEmpty || u == 'NORMAL') return 'Regular';
  if (u == 'DIRECT') return 'Direct';
  if (u == 'REGULAR') return 'Regular';
  return plan.trim();
}

String _displayOption(String option) {
  final u = option.trim().toUpperCase();
  if (u.contains('REINVEST')) return 'IDCW Reinvest';
  if (u.contains('PAYOUT')) return 'IDCW Payout';
  if (u.contains('IDCW')) return 'IDCW';
  if (u.contains('GROWTH') || u.isEmpty) return 'Growth';
  return option.trim();
}

/// First 1–3 tokens of scheme name as a readable AMC stand-in.
String _amcFromSchemeName(String name) {
  final cleaned = shortNameForDisplay(name);
  final parts = cleaned.split(RegExp(r'\s+'));
  if (parts.isEmpty) return '';
  if (parts.length >= 2 &&
      (parts[0].toUpperCase() == '360' ||
          parts[0].toUpperCase() == 'OLD' ||
          parts[0].length <= 4)) {
    return '${parts[0]} ${parts[1]}';
  }
  return parts.first;
}

String _normalizeCategory(String raw) {
  final u = raw.toUpperCase();
  if (u.contains('EQUITY') || u == 'EQ') return 'Equity';
  if (u.contains('DEBT') || u.contains('LIQUID') || u.contains('GILT')) {
    return 'Debt';
  }
  if (u.contains('HYBRID') || u.contains('BALANCED') || u.contains('ARBITRAGE')) {
    return 'Hybrid';
  }
  if (u.contains('INDEX') || u.contains('ETF')) return 'Index';
  if (raw.length <= 24) {
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }
  return _inferCategory(u);
}

String _inferCategory(String upper) {
  if (upper.contains('EQUITY') || upper.contains('ELSS')) return 'Equity';
  if (upper.contains('DEBT') ||
      upper.contains('LIQUID') ||
      upper.contains('GILT')) {
    return 'Debt';
  }
  if (upper.contains('HYBRID') ||
      upper.contains('BALANCED') ||
      upper.contains('ARBITRAGE')) {
    return 'Hybrid';
  }
  if (upper.contains('INDEX') || upper.contains('ETF')) return 'Index';
  return 'Other';
}

String _inferSubCategory(String upper) {
  const tokens = [
    'LARGE CAP',
    'MID CAP',
    'SMALL CAP',
    'FLEXI CAP',
    'MULTI CAP',
    'BALANCED HYBRID',
    'AGGRESSIVE HYBRID',
    'CONSERVATIVE HYBRID',
    'LIQUID',
    'ELSS',
  ];
  for (final t in tokens) {
    if (upper.contains(t)) {
      return t
          .split(' ')
          .map((w) =>
              '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
          .join(' ');
    }
  }
  return 'Open Ended';
}

double? _asDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim());
}

enum MfExploreCategoryFilter { all, equity, hybrid, debt, indexFunds }

/// Explore option chip: default Growth (retail-like).
enum MfExploreOptionFilter { growth, idcw, all }

extension MfExploreOptionFilterX on MfExploreOptionFilter {
  String get label => switch (this) {
        MfExploreOptionFilter.growth => 'Growth',
        MfExploreOptionFilter.idcw => 'IDCW',
        MfExploreOptionFilter.all => 'All options',
      };

  bool matches(MfSchemeView fund) {
    final u = fund.option.toUpperCase();
    return switch (this) {
      MfExploreOptionFilter.all => true,
      MfExploreOptionFilter.growth => !u.contains('IDCW'),
      MfExploreOptionFilter.idcw => u.contains('IDCW'),
    };
  }
}

enum MfReturnPeriod { d1, w1, m1, m3, m6, y1, y3, y5 }

extension MfReturnPeriodX on MfReturnPeriod {
  String get apiKey => switch (this) {
        MfReturnPeriod.d1 => '1D',
        MfReturnPeriod.w1 => '1W',
        MfReturnPeriod.m1 => '1M',
        MfReturnPeriod.m3 => '3M',
        MfReturnPeriod.m6 => '6M',
        MfReturnPeriod.y1 => '1Y',
        MfReturnPeriod.y3 => '3Y',
        MfReturnPeriod.y5 => '5Y',
      };

  String get label => apiKey;
}
