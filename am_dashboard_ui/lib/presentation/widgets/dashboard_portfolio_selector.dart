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
  });

  final String id;
  final String name;
  final bool hasHoldings;
  final int? assetCount;
  final bool isPaper;
  final String? brokerType;

  /// Broker client/BOID or NPS PRAN shown under the name when present.
  final String? externalId;

  bool get isSelectable => id == 'all' || isPaper || hasHoldings;

  DashboardPortfolioChoice copyWith({String? externalId}) {
    return DashboardPortfolioChoice(
      id: id,
      name: name,
      hasHoldings: hasHoldings,
      assetCount: assetCount,
      isPaper: isPaper,
      brokerType: brokerType,
      externalId: externalId ?? this.externalId,
    );
  }
}

bool _isCdslChoice({
  required String name,
  String? brokerType,
  String? kind,
}) {
  final broker = (brokerType ?? '').toUpperCase();
  if (broker == 'CDSL') return true;
  final n = name.toLowerCase();
  if (n.contains('cdsl') || n == 'cas' || n.contains('cas aggregator')) {
    return true;
  }
  final k = (kind ?? '').toUpperCase();
  return k.contains('CAS');
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
  final choices = <DashboardPortfolioChoice>[];
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
    if (_isCdslChoice(name: name, brokerType: brokerType, kind: kind)) {
      continue;
    }
    final isDemo = isDemoPortfolioEntry(
      kind: kind,
      name: name,
      isDummy: map['isDummy'] == true || map['dummy'] == true,
    );
    final isPaper = map['isDummy'] == true ||
        map['dummy'] == true ||
        kind == 'PAPER' ||
        name.toLowerCase() == 'paper';
    if (!isDemo && !isPaper && (kind == null || kind == 'BROKER' || kind == 'LIVE')) {
      hasRealBroker = true;
    }
    final assetCount = (map['assetCount'] as num?)?.toInt();
    final invested = (map['invested'] as num?)?.toDouble();
    final current = (map['current'] as num?)?.toDouble();
    final bool hasHoldings;
    if (assetCount != null) {
      hasHoldings = assetCount > 0;
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
    final displayName = (name.isEmpty || name == id) && brokerType != null && brokerType.isNotEmpty
        ? brokerType
        : name;
    choices.add(
      DashboardPortfolioChoice(
        id: id,
        name: displayName,
        hasHoldings: isPaper ? true : hasHoldings,
        assetCount: assetCount,
        isPaper: isPaper,
        brokerType: brokerType,
        externalId: externalId,
      ),
    );
  }
  // Once any real broker book is present, Demo must leave the dropdown.
  if (hasRealBroker) {
    choices.removeWhere((c) => isDemoPortfolioEntry(name: c.name));
  }
  return choices;
}

/// Join list rows with accounts-hub demat / NPS PRAN for selector subtitles.
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
  final pran = hub.identity?.pran ?? hub.nps?.pran;

  return [
    for (final c in choices)
      c.copyWith(
        externalId: c.externalId ??
            byPortfolio[c.id] ??
            byBroker[(c.brokerType ?? '').toUpperCase()] ??
            (((c.brokerType ?? c.name).toUpperCase().contains('NPS'))
                ? pran
                : null),
      ),
  ];
}

/// Top-of-dashboard portfolio picker. Same shell selection the portfolio
/// sidebar uses. `All` keeps the aggregate dashboard.
class DashboardPortfolioSelector extends ConsumerWidget {
  const DashboardPortfolioSelector({required this.userId, super.key});

  final String userId;

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
    final enriched = enrichChoicesWithHubIds(
      choices.asData?.value ?? const [],
      hubAsync.asData?.value,
    );
    final portfolios = <DashboardPortfolioChoice>[
      const DashboardPortfolioChoice(id: 'all', name: 'All Portfolios'),
      ...enriched,
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

    final currentName = portfolios
            .where((choice) => choice.id == currentId)
            .map((choice) => choice.name)
            .firstOrNull ??
        'All Portfolios';

    return SharedPortfolioSelector<DashboardPortfolioChoice>(
      currentPortfolioId: currentId,
      currentPortfolioName: currentName,
      portfolios: portfolios,
      idExtractor: (choice) => choice.id,
      nameExtractor: (choice) => choice.name,
      subtitleExtractor: (choice) {
        final id = choice.externalId?.trim();
        if (id == null || id.isEmpty) return null;
        final broker = (choice.brokerType ?? choice.name).toUpperCase();
        if (broker.contains('NPS')) return 'PRAN $id';
        return id;
      },
      accentColor: ModuleColors.portfolio,
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
