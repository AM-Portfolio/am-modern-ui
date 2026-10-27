import 'search_context.dart';
import 'search_context_registry.dart';

/// Command-palette ranking. Never uses A–Z as the primary key.
class SearchRelevance {
  SearchRelevance._();

  static const int fetchLimit = 16;
  static const int resultCap = 8;
  static const int minHoldingsQueryLength = 2;

  static int matchScore({
    required String query,
    required String title,
    required String subtitle,
    required SearchContext context,
  }) {
    final q = query.trim().toUpperCase();
    if (q.isEmpty) return 0;
    final t = title.trim().toUpperCase();
    final s = subtitle.trim().toUpperCase();

    int score;
    if (t == q) {
      score = 500;
    } else if (t.startsWith(q)) {
      final extra = (t.length - q.length).clamp(0, 80);
      score = 400 - extra;
    } else if (s.startsWith(q) || _hasTokenPrefix(s, q)) {
      score = 200;
    } else if (t.contains(q) || s.contains(q)) {
      score = 80;
    } else {
      return 0;
    }

    if (_isDigitHeavy(t) &&
        context != SearchContext.fo &&
        context != SearchContext.chart) {
      score -= 80;
    }
    return score;
  }

  static int rankKey({
    required SearchContext context,
    required String query,
    required String category,
    required String title,
    required String subtitle,
  }) {
    final boost = SearchContextRegistry.boost(context, category);
    final match = matchScore(
      query: query,
      title: title,
      subtitle: subtitle,
      context: context,
    );
    return boost * 10000 + match;
  }

  static int compare({
    required SearchContext context,
    required String query,
    required String aCategory,
    required String aTitle,
    required String aSubtitle,
    required int aIndex,
    required String bCategory,
    required String bTitle,
    required String bSubtitle,
    required int bIndex,
    List<String> recents = const [],
  }) {
    final ka = rankKey(
      context: context,
      query: query,
      category: aCategory,
      title: aTitle,
      subtitle: aSubtitle,
    );
    final kb = rankKey(
      context: context,
      query: query,
      category: bCategory,
      title: bTitle,
      subtitle: bSubtitle,
    );
    if (ka != kb) return kb.compareTo(ka);

    final ra = _recentRank(recents, aTitle);
    final rb = _recentRank(recents, bTitle);
    if (ra != rb) return ra.compareTo(rb);

    return aIndex.compareTo(bIndex);
  }

  static int _recentRank(List<String> recents, String title) {
    final t = title.trim().toUpperCase();
    final i = recents.indexWhere((s) => s.trim().toUpperCase() == t);
    return i < 0 ? recents.length + 1 : i;
  }

  static bool _hasTokenPrefix(String haystack, String query) {
    for (final token in haystack.split(RegExp(r'[^A-Z0-9]+'))) {
      if (token.startsWith(query)) return true;
    }
    return false;
  }

  static bool _isDigitHeavy(String title) {
    if (title.isEmpty) return false;
    final digits = title.replaceAll(RegExp(r'[^0-9]'), '').length;
    final startsDigit = title.codeUnitAt(0) >= 48 && title.codeUnitAt(0) <= 57;
    return startsDigit || digits >= 2;
  }
}
