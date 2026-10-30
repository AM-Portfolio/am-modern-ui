import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_overlay_provider.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_portfolio_scope.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardPortfolioChoice {
  const DashboardPortfolioChoice({required this.id, required this.name});

  final String id;
  final String name;
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
  for (final raw in items) {
    if (raw is! Map) continue;
    final map = Map<String, dynamic>.from(raw);
    final kind = (map['kind'] as String?)?.toUpperCase();
    if (kind == 'DELETED') continue;
    final id = (map['portfolioId'] ?? map['id'])?.toString() ?? '';
    if (id.isEmpty) continue;
    final name = (map['portfolioName'] ?? map['name'])?.toString() ?? id;
    choices.add(DashboardPortfolioChoice(id: id, name: name));
  }
  return choices;
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
    final portfolios = <DashboardPortfolioChoice>[
      const DashboardPortfolioChoice(id: 'all', name: 'All Portfolios'),
      ...?choices.asData?.value,
    ];
    final currentId = normalized ?? 'all';
    final currentName = portfolios
            .where((choice) => choice.id == currentId)
            .map((choice) => choice.name)
            .firstOrNull ??
        'All Portfolios';

    return SizedBox(
      width: 240,
      child: SharedPortfolioSelector<DashboardPortfolioChoice>(
        currentPortfolioId: currentId,
        currentPortfolioName: currentName,
        portfolios: portfolios,
        idExtractor: (choice) => choice.id,
        nameExtractor: (choice) => choice.name,
        accentColor: ModuleColors.portfolio,
        onPortfolioSelected: (id, name) {
          context.selectPortfolio(id, name);
          ref.read(dashboardPortfolioScopeProvider.notifier).select(id);
          ref
              .read(dashboardOverlayProvider(userId).notifier)
              .setPreferredPortfolioId(id);
        },
      ),
    );
  }
}
