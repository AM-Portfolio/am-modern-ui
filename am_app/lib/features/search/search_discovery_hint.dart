import 'search_context.dart';

/// Session-scoped “subtle glow” for Global Search on discovery pages.
class SearchDiscoveryHint {
  SearchDiscoveryHint._();

  static final Set<SearchContext> _dismissed = <SearchContext>{};

  static bool shouldHighlight(SearchContext ctx, {required bool searchOpen}) {
    if (searchOpen) return false;
    if (!SearchContextResolver.isDiscoveryContext(ctx)) return false;
    if (_dismissed.contains(ctx)) return false;
    return true;
  }

  static void dismiss(SearchContext ctx) => _dismissed.add(ctx);

  /// Test / debug only.
  static void resetForTest() => _dismissed.clear();
}
