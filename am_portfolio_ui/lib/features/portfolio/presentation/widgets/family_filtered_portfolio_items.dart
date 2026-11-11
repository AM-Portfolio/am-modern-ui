import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_list.dart';

/// Enrich blank family member names from accounts hub, then filter + label.
List<PortfolioItem> familyFilteredPortfolioItems({
  required List<PortfolioItem> portfolios,
  required String filterKey,
  required bool showFamilyUi,
  AccountsHub? hub,
}) {
  final memberNameById = <String, String>{};
  for (final m in hub?.familyMembers ?? const <FamilyMemberRow>[]) {
    final mid = m.id?.trim();
    final n = m.name?.trim();
    if (mid == null || mid.isEmpty || n == null || n.isEmpty) continue;
    memberNameById.putIfAbsent(mid, () => n);
  }

  final enriched = <PortfolioItem>[];
  for (final p in portfolios) {
    final famId = p.familyMemberId?.trim();
    final needsName = famId != null &&
        famId.isNotEmpty &&
        (p.familyMemberName == null || p.familyMemberName!.trim().isEmpty);
    enriched.add(
      needsName
          ? p.copyWith(familyMemberName: memberNameById[famId])
          : p,
    );
  }

  return applyFamilyPortfolioFilter<PortfolioItem>(
    items: enriched,
    filterKey: filterKey,
    showFamilyUi: showFamilyUi,
    familyMemberIdOf: (p) => p.familyMemberId,
    familyMemberNameOf: (p) => p.familyMemberName,
    baseNameOf: (p) => p.portfolioName,
    copyWithName: (p, labeled) => p.copyWith(portfolioName: labeled),
    alwaysKeep: (p) => p.portfolioId == 'all',
  );
}

List<({String id, String name})> familyMembersForFilter(AccountsHub? hub) {
  return [
    for (final m in hub?.familyMembers ?? const <FamilyMemberRow>[])
      if ((m.id?.trim().isNotEmpty ?? false))
        (
          id: m.id!.trim(),
          name: (m.name?.trim().isNotEmpty ?? false)
              ? m.name!.trim()
              : m.id!.trim(),
        ),
  ];
}

String primaryFamilyLabel(AccountsHub? hub) {
  final name = hub?.identity?.name?.trim();
  if (name == null || name.isEmpty) return 'You';
  return name.split(RegExp(r'\s+')).first;
}
