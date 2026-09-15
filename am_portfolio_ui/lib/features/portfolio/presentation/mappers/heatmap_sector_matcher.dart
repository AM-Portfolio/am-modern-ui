import 'package:am_common/am_common.dart';

/// Strict matching: whole-word / compacted equality.
bool matchesStrictly(String source, String target) {
  final s = source.toLowerCase().trim();
  final t = target.toLowerCase().trim();
  if (s == t) return true;
  if (s.replaceAll(' ', '') == t.replaceAll(' ', '')) return true;
  try {
    if (RegExp('\\b${RegExp.escape(t)}', caseSensitive: false).hasMatch(s)) {
      return true;
    }
    if (RegExp('\\b${RegExp.escape(s)}', caseSensitive: false).hasMatch(t)) {
      return true;
    }
  } catch (_) {}
  return false;
}

/// Domain-aware sector matching for heatmap filters (cubit + layout).
bool matchesHeatmapSector(String tileName, SectorType targetSector) {
  final s = tileName.toLowerCase().trim();
  switch (targetSector) {
    case SectorType.all:
      return true;
    case SectorType.technology:
    case SectorType.it:
      return s.contains('information technology') ||
          s == 'it' ||
          (s.contains('tech') && !s.contains('health') && !s.contains('bio'));
    case SectorType.healthcare:
    case SectorType.pharma:
      return s.contains('health') ||
          s.contains('pharma') ||
          s.contains('biotech') ||
          s.contains('medical');
    case SectorType.finance:
    case SectorType.banking:
      return s.contains('finance') ||
          s.contains('financial') ||
          s.contains('bank') ||
          s.contains('insurance');
    case SectorType.consumer:
    case SectorType.fmcg:
    case SectorType.consumerServices:
    case SectorType.automobiles:
      return s.contains('consumer') ||
          s.contains('fmcg') ||
          s.contains('automobile') ||
          s.contains('auto ') ||
          s == 'auto' ||
          s.contains('retail');
    case SectorType.energy:
    case SectorType.utilities:
      return s.contains('energy') ||
          s.contains('oil') ||
          s.contains('gas') ||
          s.contains('power') ||
          s.contains('utilit');
    case SectorType.industrials:
    case SectorType.manufacturing:
    case SectorType.infrastructure:
      return s.contains('industrial') ||
          s.contains('manufactur') ||
          s.contains('infrastruct') ||
          (s.contains('process') && !s.contains('food')) ||
          s.contains('transport');
    case SectorType.materials:
    case SectorType.metals:
      return s.contains('material') ||
          s.contains('metal') ||
          s.contains('mining') ||
          s.contains('mineral') ||
          s.contains('chemical');
    default:
      return s == targetSector.displayName.toLowerCase().trim();
  }
}
