import 'package:am_common/core/session/favorite_persona_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared Family filter for portfolio dropdowns (dashboard + trade/portfolio sidebars).
///
/// Values use [FavoritePersonaStore] keys:
/// - [FavoritePersonaStore.kAll] — all books; family books show `(Name)` suffix
/// - [FavoritePersonaStore.kYou] — primary books only; bare labels
/// - `<memberId>` — that member's books only; bare labels
final familyPortfolioFilterProvider =
    NotifierProvider<FamilyPortfolioFilterNotifier, String>(
  FamilyPortfolioFilterNotifier.new,
);

class FamilyPortfolioFilterNotifier extends Notifier<String> {
  @override
  String build() => FavoritePersonaStore.kAll;

  void select(String key) {
    if (key.isEmpty) return;
    state = key;
  }

  void resetToAll() => state = FavoritePersonaStore.kAll;
}

/// True when the Family dropdown should be shown.
bool showFamilyPortfolioFilter(Iterable<({String? id, String? name})> members) {
  return members.any((m) {
    final id = m.id?.trim();
    return id != null && id.isNotEmpty;
  });
}

/// Whether a book with [familyMemberId] belongs under [filterKey].
bool matchesFamilyPortfolioFilter({
  required String? familyMemberId,
  required String filterKey,
}) {
  if (filterKey == FavoritePersonaStore.kAll) return true;
  final id = familyMemberId?.trim();
  final isPrimary = id == null || id.isEmpty;
  if (filterKey == FavoritePersonaStore.kYou) return isPrimary;
  return !isPrimary && id == filterKey;
}

/// Strip a trailing ` (Name)` suffix from a dropdown label.
String stripPortfolioFamilySuffix(String name) {
  final n = name.trim();
  final open = n.lastIndexOf(' (');
  if (open > 0 && n.endsWith(')')) return n.substring(0, open);
  return n;
}

/// Primary books: bare [baseName]. Family: `Dhan (Priyanshu)`.
String formatPortfolioDropdownLabel({
  required String displayName,
  String? familyMemberId,
  String? familyMemberName,
}) {
  final id = familyMemberId?.trim();
  if (id == null || id.isEmpty) return displayName;
  final member = familyMemberName?.trim();
  if (member == null || member.isEmpty) return displayName;
  final short = member.split(RegExp(r'\s+')).first;
  return '$displayName ($short)';
}

/// Label for the portfolio dropdown under the active Family filter.
///
/// When Family UI is hidden, or filter is You/member, return bare [baseName].
/// When filter is All, apply the family suffix.
String labelForFamilyPortfolioFilter({
  required String baseName,
  String? familyMemberId,
  String? familyMemberName,
  required String filterKey,
  required bool showFamilyUi,
}) {
  final bare = stripPortfolioFamilySuffix(baseName);
  if (!showFamilyUi || filterKey != FavoritePersonaStore.kAll) {
    return bare;
  }
  return formatPortfolioDropdownLabel(
    displayName: bare,
    familyMemberId: familyMemberId,
    familyMemberName: familyMemberName,
  );
}

/// Filter + relabel a list of portfolio rows for the Family dropdown.
List<T> applyFamilyPortfolioFilter<T>({
  required List<T> items,
  required String filterKey,
  required bool showFamilyUi,
  required String? Function(T) familyMemberIdOf,
  required String? Function(T) familyMemberNameOf,
  required String Function(T) baseNameOf,
  required T Function(T item, String labeledName) copyWithName,
  bool Function(T)? alwaysKeep,
}) {
  final out = <T>[];
  for (final item in items) {
    if (alwaysKeep != null && alwaysKeep(item)) {
      out.add(item);
      continue;
    }
    if (!matchesFamilyPortfolioFilter(
      familyMemberId: familyMemberIdOf(item),
      filterKey: filterKey,
    )) {
      continue;
    }
    final labeled = labelForFamilyPortfolioFilter(
      baseName: baseNameOf(item),
      familyMemberId: familyMemberIdOf(item),
      familyMemberName: familyMemberNameOf(item),
      filterKey: filterKey,
      showFamilyUi: showFamilyUi,
    );
    out.add(copyWithName(item, labeled));
  }
  return out;
}
