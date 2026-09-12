/// Shared sector/label hygiene for Stress + What-If typeahead.
bool isUsableIntelligenceSectorLabel(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return false;
  final lower = s.toLowerCase();
  if (lower == 'unknown' || lower == 'n/a' || lower == 'na' || lower == 'null') {
    return false;
  }
  if (RegExp(r'^[\-–—_/\\.|]+$').hasMatch(s)) return false;
  return true;
}
