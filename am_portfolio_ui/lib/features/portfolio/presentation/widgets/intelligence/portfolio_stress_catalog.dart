import 'package:flutter/material.dart';

import '../../../internal/domain/entities/portfolio_intelligence.dart';

const kStressChipNifty = 'NIFTY 50';
const kStressChipSensex = 'SENSEX';
const kStressChipBanking = 'Banking';
const kStressChipIt = 'IT';

const kStressViewAllIds = <String>[
  'NIFTY_DOWN_10',
  'SENSEX_DOWN_10',
  'GFC_2008',
  'COVID_2020',
  'CHINA_2015',
  'INFLATION_2022',
  'ELECTION_2024',
];

/// View-all catalog plus sector presets used only for chip Apply scale.
const kStressLoadIds = <String>[
  'NIFTY_DOWN_10',
  'SENSEX_DOWN_10',
  'GFC_2008',
  'COVID_2020',
  'CHINA_2015',
  'INFLATION_2022',
  'ELECTION_2024',
  'BANKING_DOWN_20',
  'IT_DOWN_15',
];

enum StressApplyRoute { nifty, sensex, banking, it, custom }

StressApplyRoute stressApplyRoute(String raw) {
  final n = raw.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');
  if (n.isEmpty) return StressApplyRoute.nifty;
  if (n == 'nifty' || n == 'nifty50' || n == 'niftyfifty') {
    return StressApplyRoute.nifty;
  }
  if (n == 'sensex' || n == 'bsesensex') return StressApplyRoute.sensex;
  if (n == 'banking' || n == 'bank' || n == 'banks') {
    return StressApplyRoute.banking;
  }
  if (n == 'it' || n == 'informationtechnology') return StressApplyRoute.it;
  return StressApplyRoute.custom;
}

/// Chip that should be highlighted for the current search text.
/// Empty query keeps [current]; unmatched custom text deselects chips.
String stressChipForQuery(String raw, {required String current}) {
  final t = raw.trim();
  if (t.isEmpty) return current;
  switch (stressApplyRoute(t)) {
    case StressApplyRoute.nifty:
      return kStressChipNifty;
    case StressApplyRoute.sensex:
      return kStressChipSensex;
    case StressApplyRoute.banking:
      return kStressChipBanking;
    case StressApplyRoute.it:
      return kStressChipIt;
    case StressApplyRoute.custom:
      return '';
  }
}

/// Linear scale of a loaded preset: newPct = basePct × (shock / catalogShock).
StressScenario? scaleStressScenario({
  required StressScenario? base,
  required double shockPct,
  required double catalogDefault,
}) {
  if (base == null) return null;
  final catalog = (base.appliedShockPct != null && base.appliedShockPct != 0)
      ? base.appliedShockPct!
      : catalogDefault;
  if (catalog == 0) return null;
  final factor = shockPct / catalog;
  return StressScenario(
    id: base.id,
    pctImpact: base.pctImpact * factor,
    absImpact: base.absImpact == null ? null : base.absImpact! * factor,
    matchedWeightPct: base.matchedWeightPct,
    matchedHoldings: base.matchedHoldings,
    appliedShockPct: shockPct,
    note: base.note,
  );
}

class StressViewRow {
  const StressViewRow({
    required this.id,
    required this.name,
    this.date,
    required this.isEvent,
  });

  final String id;
  final String name;
  final String? date;
  final bool isEvent;
}

const kStressViewRows = <StressViewRow>[
  StressViewRow(id: 'NIFTY_DOWN_10', name: 'NIFTY 50', isEvent: false),
  StressViewRow(id: 'SENSEX_DOWN_10', name: 'SENSEX', isEvent: false),
  StressViewRow(
    id: 'GFC_2008',
    name: 'Global Financial Crisis',
    date: 'Oct 2008',
    isEvent: true,
  ),
  StressViewRow(
    id: 'COVID_2020',
    name: 'COVID-19 Crash',
    date: 'Mar 2020',
    isEvent: true,
  ),
  StressViewRow(
    id: 'CHINA_2015',
    name: 'China Market Sell-off',
    date: 'Aug 2015',
    isEvent: true,
  ),
  StressViewRow(
    id: 'INFLATION_2022',
    name: 'Inflation & Rate Hikes',
    date: 'Jan 2022',
    isEvent: true,
  ),
  StressViewRow(
    id: 'ELECTION_2024',
    name: 'Election Volatility',
    date: 'Jun 2024',
    isEvent: true,
  ),
];

bool stressIsIndexLabel(String raw) {
  final route = stressApplyRoute(raw);
  return route == StressApplyRoute.nifty || route == StressApplyRoute.sensex;
}

IconData stressPresetIcon(String presetId, {bool isEvent = false}) {
  if (isEvent ||
      presetId.startsWith('GFC') ||
      presetId.startsWith('COVID') ||
      presetId.startsWith('CHINA') ||
      presetId.startsWith('INFLATION') ||
      presetId.startsWith('ELECTION')) {
    return Icons.calendar_today_rounded;
  }
  if (presetId.startsWith('NIFTY') || presetId.startsWith('SENSEX')) {
    return Icons.trending_down_rounded;
  }
  if (presetId.startsWith('BANKING')) return Icons.account_balance_rounded;
  if (presetId.startsWith('IT')) return Icons.laptop_mac_rounded;
  if (presetId.startsWith('CRASH')) return Icons.thunderstorm_rounded;
  if (presetId.startsWith('CUSTOM')) return Icons.tune_rounded;
  return Icons.bolt_rounded;
}
