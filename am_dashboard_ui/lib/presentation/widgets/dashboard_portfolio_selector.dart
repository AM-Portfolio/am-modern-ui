import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_overlay_provider.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_portfolio_scope.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_dashboard_ui/presentation/providers/has_demo_portfolio_provider.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardPortfolioChoice {
  const DashboardPortfolioChoice({
    required this.id,
    required this.name,
    this.hasHoldings = true,
    this.assetCount,
    this.isPaper = false,
    this.brokerType,
    this.externalId,
    this.familyMemberId,
    this.familyMemberName,
  });

  final String id;
  final String name;
  final bool hasHoldings;
  final int? assetCount;
  final bool isPaper;
  final String? brokerType;

  /// Broker client/BOID or NPS PRAN shown under the name when present.
  final String? externalId;

  final String? familyMemberId;
  final String? familyMemberName;

  bool get isSelectable => id == 'all' || isPaper || hasHoldings;

  DashboardPortfolioChoice copyWith({
    String? name,
    String? externalId,
    String? familyMemberName,
  }) {
    return DashboardPortfolioChoice(
      id: id,
      name: name ?? this.name,
      hasHoldings: hasHoldings,
      assetCount: assetCount,
      isPaper: isPaper,
      brokerType: brokerType,
      externalId: externalId ?? this.externalId,
      familyMemberId: familyMemberId,
      familyMemberName: familyMemberName ?? this.familyMemberName,
    );
  }
}

bool _isCdslChoice({
  required String name,
  String? brokerType,
  String? kind,
}) {
  final broker = (brokerType ?? '').toUpperCase();
  if (broker == 'CAS_DEMAT') return false;
  if (broker == 'CDSL') return true;
  final n = name.toLowerCase().trim();
  if (n == 'cdsl'
      || n == 'cas'
      || n == 'cdsl cas'
      || n == 'cas aggregator'
      || n.contains('cdsl')) {
    return true;
  }
  final k = (kind ?? '').toUpperCase();
  // Kind CAS_DEMAT is a named demat book — never soft-hide as aggregator.
  return k == 'CDSL' || k == 'CAS' || k == 'CAS_AGGREGATOR';
}

final dashboardPortfolioChoicesProvider =
    FutureProvider<List<DashboardPortfolioChoice>>((ref) async {
  final client = await ref.watch(portfolioApiClientProvider.future);
  final data = await client.get<dynamic>(
    '/v1/portfolios/list',
    parser: (raw) => raw,
  );
  return parseDashboardPortfolioChoices(data);
});

List<DashboardPortfolioChoice> parseDashboardPortfolioChoices(dynamic data) {
  final List<dynamic> items;
  if (data is List) {
    items = data;
  } else if (data is Map && data['portfolios'] is List) {
    items = data['portfolios'] as List;
  } else {
    return const [];
  }
  final pending = <_PendingDashboardChoice>[];
  var hasRealBroker = false;
  for (final raw in items) {
    if (raw is! Map) continue;
    final map = Map<String, dynamic>.from(raw);
    final kind = (map['kind'] as String?)?.toUpperCase();
    if (kind == 'DELETED') continue;
    final id = (map['portfolioId'] ?? map['id'])?.toString() ?? '';
    if (id.isEmpty) continue;
    final name = (map['portfolioName'] ?? map['name'])?.toString() ?? id;
    final brokerType =
        (map['brokerType'] ?? map['broker'])?.toString();
    final isCdsl =
        _isCdslChoice(name: name, brokerType: brokerType, kind: kind);
    final isDemo = isDemoPortfolioEntry(
      kind: kind,
      name: name,
      isDummy: map['isDummy'] == true || map['dummy'] == true,
    );
    final isPaper = map['isDummy'] == true ||
        map['dummy'] == true ||
        kind == 'PAPER' ||
        name.toLowerCase() == 'paper';
    if (!isCdsl &&
        !isDemo &&
        !isPaper &&
        (kind == null || kind == 'BROKER' || kind == 'LIVE')) {
      hasRealBroker = true;
    }
    final assetCount = (map['assetCount'] as num?)?.toInt();
    final invested = (map['invested'] as num?)?.toDouble();
    final current = (map['current'] as num?)?.toDouble();
    final totalValue = (map['totalValue'] as num?)?.toDouble() ?? current;
    final serverHasHoldings = map['hasHoldings'] as bool?;
    final bool hasHoldings;
    if (serverHasHoldings != null) {
      hasHoldings = serverHasHoldings;
    } else if (assetCount != null || totalValue != null) {
      hasHoldings = (assetCount != null && assetCount > 0) ||
          (totalValue != null && totalValue > 0) ||
          (invested != null && invested > 0);
    } else if (invested != null || current != null) {
      hasHoldings = (invested ?? 0) > 0 || (current ?? 0) > 0;
    } else {
      hasHoldings = true;
    }
    final externalId = (map['clientId'] ??
            map['boid'] ??
            map['externalId'] ??
            map['pran'])
        ?.toString();
    final familyMemberId = (map['familyMemberId'] as String?)?.trim();
    final familyMemberName = (map['familyMemberName'] as String?)?.trim();
    final baseName = (name.isEmpty || name == id) &&
            brokerType != null &&
            brokerType.isNotEmpty
        ? brokerType
        : name;
    pending.add(
      _PendingDashboardChoice(
        isCdsl: isCdsl,
        isDemo: isDemo,
        choice: DashboardPortfolioChoice(
          id: id,
          name: stripPortfolioFamilySuffix(baseName),
          hasHoldings: isPaper ? true : hasHoldings,
          assetCount: assetCount,
          isPaper: isPaper,
          brokerType: brokerType,
          externalId: externalId,
          familyMemberId:
              familyMemberId?.isEmpty == true ? null : familyMemberId,
          familyMemberName:
              familyMemberName?.isEmpty == true ? null : familyMemberName,
        ),
      ),
    );
  }
  final choices = <DashboardPortfolioChoice>[
    for (final p in pending)
      if (!hasRealBroker || !p.isCdsl) p.choice,
  ];
  // Once any real (non-CDSL) broker book is present, Demo must leave the dropdown.
  if (hasRealBroker) {
    choices.removeWhere((c) => isDemoPortfolioEntry(name: c.name));
  }
  return choices;
}

class _PendingDashboardChoice {
  const _PendingDashboardChoice({
    required this.isCdsl,
    required this.isDemo,
    required this.choice,
  });

  final bool isCdsl;
  final bool isDemo;
  final DashboardPortfolioChoice choice;
}

/// Join list rows with accounts-hub demat / NPS PRAN for selector subtitles,
/// and fill blank family member names from hub members when id is known.
List<DashboardPortfolioChoice> enrichChoicesWithHubIds(
  List<DashboardPortfolioChoice> choices,
  AccountsHub? hub,
) {
  if (hub == null) return choices;
  final byPortfolio = <String, String>{};
  for (final d in hub.dematAccounts) {
    final pid = d.portfolioId;
    final label = d.externalIdLabel;
    if (pid == null || pid.isEmpty || label == null) continue;
    byPortfolio.putIfAbsent(pid, () => label);
  }
  final byBroker = <String, String>{};
  for (final d in hub.dematAccounts) {
    final broker = (d.mappedBroker ?? '').toUpperCase();
    final label = d.externalIdLabel;
    if (broker.isEmpty || label == null) continue;
    byBroker.putIfAbsent(broker, () => label);
  }
  final memberNameById = <String, String>{};
  for (final m in hub.familyMembers) {
    final mid = m.id?.trim();
    final n = m.name?.trim();
    if (mid == null || mid.isEmpty || n == null || n.isEmpty) continue;
    memberNameById.putIfAbsent(mid, () => n);
  }
  final pran = hub.identity?.pran ?? hub.nps?.pran;

  return [
    for (final c in choices)
      _enrichOneChoice(
        c,
        byPortfolio: byPortfolio,
        byBroker: byBroker,
        memberNameById: memberNameById,
        pran: pran,
      ),
  ];
}

DashboardPortfolioChoice _enrichOneChoice(
  DashboardPortfolioChoice c, {
  required Map<String, String> byPortfolio,
  required Map<String, String> byBroker,
  required Map<String, String> memberNameById,
  required String? pran,
}) {
  final famId = c.familyMemberId?.trim();
  final needsName = famId != null &&
      famId.isNotEmpty &&
      (c.familyMemberName == null || c.familyMemberName!.trim().isEmpty);
  final resolvedName = needsName ? memberNameById[famId] : c.familyMemberName;
  return c.copyWith(
    name: stripPortfolioFamilySuffix(c.name),
    familyMemberName: resolvedName,
    externalId: c.externalId ??
        byPortfolio[c.id] ??
        byBroker[(c.brokerType ?? '').toUpperCase()] ??
        (((c.brokerType ?? c.name).toUpperCase().contains('NPS'))
            ? pran
            : null),
  );
}

List<DashboardPortfolioChoice> filterDashboardChoicesByFamily({
  required List<DashboardPortfolioChoice> choices,
  required String filterKey,
  required bool showFamilyUi,
}) {
  return applyFamilyPortfolioFilter<DashboardPortfolioChoice>(
    items: choices,
    filterKey: filterKey,
    showFamilyUi: showFamilyUi,
    familyMemberIdOf: (c) => c.familyMemberId,
    familyMemberNameOf: (c) => c.familyMemberName,
    baseNameOf: (c) => c.name,
    copyWithName: (c, labeled) => c.copyWith(name: labeled),
    alwaysKeep: (c) => c.id == 'all',
  );
}

/// Top-of-dashboard portfolio picker. Same shell selection the portfolio
/// sidebar uses. `All` keeps the aggregate dashboard.
class DashboardPortfolioSelector extends ConsumerWidget {
  const DashboardPortfolioSelector({
    required this.userId,
    this.compact = false,
    this.layout = FamilyAwarePortfolioPickerLayout.row,
    super.key,
  });

  final String userId;
  final bool compact;
  final FamilyAwarePortfolioPickerLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inherited = context.selectedPortfolioId;
    final scoped = ref.watch(dashboardPortfolioScopeProvider);
    final normalized = (inherited == null ||
            inherited.isEmpty ||
            inherited == 'all')
        ? null
        : inherited;
    if (normalized != scoped) {
      Future.microtask(() {
        ref.read(dashboardPortfolioScopeProvider.notifier).select(inherited);
        ref
            .read(dashboardOverlayProvider(userId).notifier)
            .setPreferredPortfolioId(inherited);
      });
    }

    final choices = ref.watch(dashboardPortfolioChoicesProvider);
    final hubAsync = ref.watch(accountsHubProvider(userId));
    final hub = hubAsync.asData?.value;
    final enriched = enrichChoicesWithHubIds(
      choices.asData?.value ?? const [],
      hub,
    );

    final members = <({String id, String name})>[
      for (final m in hub?.familyMembers ?? const <FamilyMemberRow>[])
        if ((m.id?.trim().isNotEmpty ?? false))
          (id: m.id!.trim(), name: (m.name?.trim().isNotEmpty ?? false)
              ? m.name!.trim()
              : m.id!.trim()),
    ];
    final showFamily = showFamilyPortfolioFilter(
      members.map((m) => (id: m.id, name: m.name)),
    );
    final filterKey = ref.watch(familyPortfolioFilterProvider);
    final filteredBooks = filterDashboardChoicesByFamily(
      choices: enriched,
      filterKey: filterKey,
      showFamilyUi: showFamily,
    );
    final portfolios = <DashboardPortfolioChoice>[
      const DashboardPortfolioChoice(id: 'all', name: 'All Portfolios'),
      ...filteredBooks,
    ];

    var currentId = normalized ?? 'all';
    final known = portfolios.any((c) => c.id == currentId);
    if (!known && currentId != 'all') {
      currentId = 'all';
      final selectPortfolio = context.selectPortfolio;
      Future.microtask(() {
        selectPortfolio('all', 'All Portfolios');
        ref.read(dashboardPortfolioScopeProvider.notifier).select(null);
        ref
            .read(dashboardOverlayProvider(userId).notifier)
            .setPreferredPortfolioId(null);
      });
    }

    final primaryLabel = hub?.identity?.name?.trim().isNotEmpty == true
        ? hub!.identity!.name!.trim().split(RegExp(r'\s+')).first
        : 'You';

    String bookLabel(DashboardPortfolioChoice choice) {
      if (choice.id == 'all') return choice.name;
      return labelForFamilyPortfolioFilter(
        baseName: choice.name,
        familyMemberId: choice.familyMemberId,
        familyMemberName: choice.familyMemberName,
        filterKey: filterKey,
        showFamilyUi: showFamily,
      );
    }

    final currentName = portfolios
            .where((choice) => choice.id == currentId)
            .map(bookLabel)
            .firstOrNull ??
        'All Portfolios';

    return FamilyAwarePortfolioPicker<DashboardPortfolioChoice>(
      showFamilyFilter: showFamily,
      familyFilterKey: filterKey,
      primaryLabel: primaryLabel,
      members: members,
      onFamilySelected: (key) {
        ref.read(familyPortfolioFilterProvider.notifier).select(key);
        final nextBooks = filterDashboardChoicesByFamily(
          choices: enriched,
          filterKey: key,
          showFamilyUi: showFamily,
        );
        final stillValid =
            currentId == 'all' || nextBooks.any((c) => c.id == currentId);
        if (!stillValid) {
          context.selectPortfolio('all', 'All Portfolios');
          ref.read(dashboardPortfolioScopeProvider.notifier).select(null);
          ref
              .read(dashboardOverlayProvider(userId).notifier)
              .setPreferredPortfolioId(null);
        }
      },
      layout: layout,
      compact: compact,
      currentPortfolioId: currentId,
      currentPortfolioName: currentName,
      portfolios: portfolios,
      idExtractor: (choice) => choice.id,
      nameExtractor: bookLabel,
      subtitleExtractor: (choice) {
        final id = choice.externalId?.trim();
        if (id == null || id.isEmpty) return null;
        final broker = (choice.brokerType ?? choice.name).toUpperCase();
        if (broker.contains('NPS')) return 'PRAN $id';
        return id;
      },
      accentColor: ModuleColors.dashboard,
      isSelectableExtractor: (choice) => choice.isSelectable,
      showNoHoldingsBadgeExtractor: (choice) =>
          choice.id != 'all' && !choice.isPaper && !choice.hasHoldings,
      onPortfolioSelected: (id, name) {
        context.selectPortfolio(id, name);
        ref.read(dashboardPortfolioScopeProvider.notifier).select(id);
        ref
            .read(dashboardOverlayProvider(userId).notifier)
            .setPreferredPortfolioId(id);
      },
    );
  }
}
