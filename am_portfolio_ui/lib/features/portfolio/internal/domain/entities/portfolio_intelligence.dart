// Domain models for Portfolio Intelligence APIs
// (`/intelligence`, `/stress`, `/what-if`).

class PortfolioIntelligence {
  const PortfolioIntelligence({
    required this.portfolioId,
    this.asOf,
    this.confidence,
    this.health,
    this.risk,
    this.xray,
  });

  final String portfolioId;
  final DateTime? asOf;
  final double? confidence;
  final PortfolioHealth? health;
  final PortfolioRisk? risk;
  final PortfolioXray? xray;

  factory PortfolioIntelligence.fromJson(Map<String, dynamic> json) {
    return PortfolioIntelligence(
      portfolioId: json['portfolioId']?.toString() ?? '',
      asOf: _parseDate(json['asOf']),
      confidence: _asDouble(json['confidence']),
      health: json['health'] is Map<String, dynamic>
          ? PortfolioHealth.fromJson(json['health'] as Map<String, dynamic>)
          : null,
      risk: json['risk'] is Map<String, dynamic>
          ? PortfolioRisk.fromJson(json['risk'] as Map<String, dynamic>)
          : null,
      xray: json['xray'] is Map<String, dynamic>
          ? PortfolioXray.fromJson(json['xray'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PortfolioHealth {
  const PortfolioHealth({
    required this.score,
    required this.band,
    this.components = const [],
  });

  final double score;
  final String band;
  final List<HealthComponent> components;

  factory PortfolioHealth.fromJson(Map<String, dynamic> json) {
    final raw = json['components'];
    return PortfolioHealth(
      score: _asDouble(json['score']) ?? 0,
      band: json['band']?.toString() ?? 'Watch',
      components: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => HealthComponent.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

class HealthComponent {
  const HealthComponent({
    required this.id,
    required this.score,
    this.severity,
    this.reason,
  });

  final String id;
  final double score;
  final String? severity;
  final String? reason;

  factory HealthComponent.fromJson(Map<String, dynamic> json) {
    return HealthComponent(
      id: json['id']?.toString() ?? '',
      score: _asDouble(json['score']) ?? 0,
      severity: json['severity']?.toString(),
      reason: json['reason']?.toString(),
    );
  }

  String get displayName {
    if (id.isEmpty) return 'Component';
    return id
        .toLowerCase()
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

class PortfolioRisk {
  const PortfolioRisk({
    this.axes = const [],
    this.findings = const [],
  });

  final List<RiskAxis> axes;
  final List<RiskFinding> findings;

  factory PortfolioRisk.fromJson(Map<String, dynamic> json) {
    final axesRaw = json['axes'];
    final findingsRaw = json['findings'];
    return PortfolioRisk(
      axes: axesRaw is List
          ? axesRaw
              .whereType<Map>()
              .map((e) => RiskAxis.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      findings: findingsRaw is List
          ? findingsRaw
              .whereType<Map>()
              .map((e) => RiskFinding.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

class RiskAxis {
  const RiskAxis({
    required this.id,
    required this.riskScore,
  });

  final String id;
  final double riskScore;

  factory RiskAxis.fromJson(Map<String, dynamic> json) {
    return RiskAxis(
      id: json['id']?.toString() ?? '',
      riskScore: _asDouble(json['riskScore']) ?? 0,
    );
  }

  String get displayName {
    if (id.isEmpty) return 'Risk';
    return id
        .toLowerCase()
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

class RiskFinding {
  const RiskFinding({
    required this.code,
    required this.label,
    this.severity,
  });

  final String code;
  final String label;
  final String? severity;

  factory RiskFinding.fromJson(Map<String, dynamic> json) {
    return RiskFinding(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      severity: json['severity']?.toString(),
    );
  }
}

class PortfolioXray {
  const PortfolioXray({
    this.sectorWeights = const [],
    this.industryWeights = const [],
    this.marketCapWeights = const [],
    this.totalValueInr,
  });

  final List<XrayWeight> sectorWeights;
  final List<XrayWeight> industryWeights;
  final List<XrayWeight> marketCapWeights;
  /// Book NAV denominator from intelligence API (`xray.totalValue`).
  final double? totalValueInr;

  factory PortfolioXray.fromJson(Map<String, dynamic> json) {
    return PortfolioXray(
      sectorWeights: _parseWeights(json['sectorWeights']),
      industryWeights: _parseWeights(json['industryWeights']),
      marketCapWeights: _parseWeights(json['marketCapWeights']),
      totalValueInr: _asDouble(json['totalValue']),
    );
  }

  static List<XrayWeight> _parseWeights(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => XrayWeight.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

class XrayWeight {
  const XrayWeight({
    required this.name,
    required this.weightPct,
    this.valueInr,
  });

  final String name;
  final double weightPct;
  /// Absolute INR exposure for this slice (`value` on API).
  final double? valueInr;

  factory XrayWeight.fromJson(Map<String, dynamic> json) {
    return XrayWeight(
      name: json['name']?.toString() ?? '',
      weightPct: _asDouble(json['weightPct']) ?? 0,
      valueInr: _asDouble(json['value']),
    );
  }
}

class StressResult {
  const StressResult({
    required this.portfolioId,
    this.estimateLabel = 'Scenario estimate',
    this.scenarios = const [],
  });

  final String portfolioId;
  final String estimateLabel;
  final List<StressScenario> scenarios;

  factory StressResult.fromJson(Map<String, dynamic> json) {
    final raw = json['scenarios'];
    return StressResult(
      portfolioId: json['portfolioId']?.toString() ?? '',
      estimateLabel:
          json['estimateLabel']?.toString() ?? 'Scenario estimate',
      scenarios: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => StressScenario.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

class StressScenario {
  const StressScenario({
    required this.id,
    required this.pctImpact,
    this.absImpact,
  });

  final String id;
  final double pctImpact;
  final double? absImpact;

  factory StressScenario.fromJson(Map<String, dynamic> json) {
    return StressScenario(
      id: json['id']?.toString() ?? '',
      pctImpact: _asDouble(json['pctImpact']) ?? 0,
      absImpact: _asDouble(json['absImpact']),
    );
  }
}

class WhatIfResult {
  const WhatIfResult({
    required this.mode,
    this.before,
    this.after,
  });

  final String mode;
  final WhatIfSnapshot? before;
  final WhatIfSnapshot? after;

  factory WhatIfResult.fromJson(Map<String, dynamic> json) {
    return WhatIfResult(
      mode: json['mode']?.toString() ?? '',
      before: json['before'] is Map<String, dynamic>
          ? WhatIfSnapshot.fromJson(json['before'] as Map<String, dynamic>)
          : null,
      after: json['after'] is Map<String, dynamic>
          ? WhatIfSnapshot.fromJson(json['after'] as Map<String, dynamic>)
          : null,
    );
  }
}

class WhatIfSnapshot {
  const WhatIfSnapshot({
    this.healthScore,
    this.weights = const {},
    this.sectorWeights = const {},
  });

  final double? healthScore;
  final Map<String, double> weights;
  final Map<String, double> sectorWeights;

  factory WhatIfSnapshot.fromJson(Map<String, dynamic> json) {
    return WhatIfSnapshot(
      healthScore: _asDouble(json['healthScore']),
      weights: _stringDoubleMap(json['weights']),
      sectorWeights: _stringDoubleMap(json['sectorWeights']),
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

Map<String, double> _stringDoubleMap(dynamic raw) {
  if (raw is! Map) return const {};
  final out = <String, double>{};
  raw.forEach((key, value) {
    final d = _asDouble(value);
    if (d != null) out[key.toString()] = d;
  });
  return out;
}
