import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_state.dart';
import '../../internal/domain/entities/portfolio_list.dart';
import '../widgets/family_filtered_portfolio_items.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final VoidCallback onLogout;

  const AppShell({
    required this.child,
    required this.onLogout,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Current route location for highlighting sidebar items
    final String location = GoRouterState.of(context).uri.toString();

    return BlocBuilder<PortfolioCubit, PortfolioState>(
      buildWhen: (previous, current) =>
          previous.portfolioList != current.portfolioList,
      builder: (context, state) {
        final portfolios = state.portfolioList?.portfolios;

        return UnifiedSidebarScaffold(
          module: ModuleType.portfolio,
          // Empty header/title as requested ("Institute" style is minimal)
          title: null,
          subtitle: null,

          onThemeToggle: () {
            context.read<ThemeCubit>().toggleTheme();
          },
          onProfileTap: () {
            // Profile logic
          },
          onLogout: onLogout,

          footer: SidebarPrimaryAction(
            title: 'New Trade',
            icon: Icons.add,
            accentColor: ModuleColors.portfolio,
            onTap: () {
              // Navigate to Basket Creator or Trade
              context.go('/portfolio/basket/creator');
            },
          ),

          sections: [
            // 1. Portfolio Selector
            if (portfolios != null && portfolios.isNotEmpty)
              SecondarySidebarSection(
                title: '',
                customWidget: _DefaultAwarePortfolioSelector(
                  portfolios: portfolios,
                ),
              ),

            // 2. Navigation Items
            SecondarySidebarSection(
              title: '',
              items: [
                SecondarySidebarItem(
                  title: 'Overview',
                  icon: Icons.dashboard_outlined,
                  isSelected:
                      location == '/portfolio/overview' ||
                      location == '/portfolio',
                  onTap: () => context.go('/portfolio/overview'),
                  accentColor: ModuleColors.portfolio,
                ),
                SecondarySidebarItem(
                  title: 'Holdings',
                  icon: Icons.pie_chart,
                  isSelected: location == '/portfolio/holdings',
                  onTap: () => context.go('/portfolio/holdings'),
                  accentColor: ModuleColors.portfolio,
                ),

                SecondarySidebarItem(
                  title: 'Heatmap',
                  icon: Icons.grid_on_outlined,
                  isSelected: location == '/portfolio/heatmap',
                  onTap: () => context.go('/portfolio/heatmap'),
                  accentColor: ModuleColors.portfolio,
                ),
                // Added manual link for debugging/access if needed,
                // though usually accessed via "New Trade" or flow
                SecondarySidebarItem(
                  title: 'Baskets',
                  icon: Icons.shopping_basket_outlined,
                  isSelected:
                      location.contains('/portfolio/basket') &&
                      !location.contains('/creator'),
                  onTap: () => context.go('/portfolio/baskets'),
                  accentColor: ModuleColors.portfolio,
                ),
              ],
            ),
          ],

          body: child, // Render specific page content here
        );
      },
    );
  }
}

class _DefaultAwarePortfolioSelector extends ConsumerStatefulWidget {
  const _DefaultAwarePortfolioSelector({required this.portfolios});

  final List<PortfolioItem> portfolios;

  @override
  ConsumerState<_DefaultAwarePortfolioSelector> createState() =>
      _DefaultAwarePortfolioSelectorState();
}

class _DefaultAwarePortfolioSelectorState
    extends ConsumerState<_DefaultAwarePortfolioSelector> {
  String? _defaultPortfolioId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDefault());
  }

  String _userId() {
    try {
      final auth = context.read<AuthCubit>().state;
      if (auth is Authenticated) return auth.user.id;
    } catch (_) {}
    return '';
  }

  Future<void> _loadDefault() async {
    final userId = _userId();
    if (userId.isEmpty) return;
    final saved = await DefaultPortfolioStore.instance.load(userId);
    if (!mounted) return;
    setState(() => _defaultPortfolioId = saved?.id);
  }

  Future<void> _toggleDefault(String id, String name) async {
    final userId = _userId();
    if (userId.isEmpty || id == 'all') return;
    if (_defaultPortfolioId == id) {
      await DefaultPortfolioStore.instance.clear(userId);
      if (!mounted) return;
      setState(() => _defaultPortfolioId = null);
      return;
    }
    await DefaultPortfolioStore.instance.save(userId, id: id, name: name);
    if (!mounted) return;
    setState(() => _defaultPortfolioId = id);
  }

  Map<String, String> _externalIdsFor(String userId) {
    if (userId.isEmpty) return const {};
    final hub = ref.watch(accountsHubProvider(userId)).asData?.value;
    if (hub == null) return const {};
    final byId = <String, String>{};
    for (final d in hub.dematAccounts) {
      final pid = d.portfolioId;
      final label = d.externalIdLabel;
      if (pid == null || pid.isEmpty || label == null) continue;
      byId.putIfAbsent(pid, () => label);
    }
    final byBroker = <String, String>{};
    for (final d in hub.dematAccounts) {
      final broker = (d.mappedBroker ?? '').toUpperCase();
      final label = d.externalIdLabel;
      if (broker.isEmpty || label == null) continue;
      byBroker.putIfAbsent(broker, () => label);
    }
    final pran = hub.identity?.pran ?? hub.nps?.pran;
    for (final p in widget.portfolios) {
      if (byId.containsKey(p.portfolioId)) continue;
      final broker = (p.brokerType ?? p.portfolioName).toUpperCase();
      if (broker.contains('NPS') && pran != null && pran.isNotEmpty) {
        byId[p.portfolioId] = pran;
      } else if (byBroker.containsKey(broker)) {
        byId[p.portfolioId] = byBroker[broker]!;
      }
    }
    return byId;
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = context.selectedPortfolioId;
    final selectedName = context.selectedPortfolioName;
    final userId = _userId();
    final externalIds = _externalIdsFor(userId);
    final hub = userId.isEmpty
        ? null
        : ref.watch(accountsHubProvider(userId)).asData?.value;
    final members = familyMembersForFilter(hub);
    final showFamily = showFamilyPortfolioFilter(
      members.map((m) => (id: m.id, name: m.name)),
    );
    final filterKey = ref.watch(familyPortfolioFilterProvider);
    final filtered = familyFilteredPortfolioItems(
      portfolios: widget.portfolios,
      filterKey: filterKey,
      showFamilyUi: showFamily,
      hub: hub,
    );
    final portfolios = <PortfolioItem>[
      const PortfolioItem(
        portfolioId: 'all',
        portfolioName: 'All Portfolios',
      ),
      ...filtered,
    ];

    var currentId = selectedId;
    if (currentId != null &&
        currentId != 'all' &&
        !portfolios.any((p) => p.portfolioId == currentId)) {
      Future.microtask(() {
        if (!context.mounted) return;
        context.selectPortfolio('all', 'All Portfolios');
      });
      currentId = 'all';
    }

    final currentName = portfolios
            .where((p) => p.portfolioId == (currentId ?? 'all'))
            .map((p) => p.portfolioName)
            .firstOrNull ??
        selectedName;

    return FamilyAwarePortfolioPicker<PortfolioItem>(
      showFamilyFilter: showFamily,
      familyFilterKey: filterKey,
      primaryLabel: primaryFamilyLabel(hub),
      members: members,
      onFamilySelected: (key) {
        ref.read(familyPortfolioFilterProvider.notifier).select(key);
        final next = familyFilteredPortfolioItems(
          portfolios: widget.portfolios,
          filterKey: key,
          showFamilyUi: showFamily,
          hub: hub,
        );
        final id = selectedId;
        final stillValid =
            id == null || id == 'all' || next.any((p) => p.portfolioId == id);
        if (!stillValid) {
          context.selectPortfolio('all', 'All Portfolios');
        }
      },
      layout: FamilyAwarePortfolioPickerLayout.stack,
      currentPortfolioId: currentId,
      currentPortfolioName: currentName,
      portfolios: portfolios,
      onPortfolioSelected: (id, name) {
        context.selectPortfolio(id, name);
      },
      idExtractor: (p) => p.portfolioId,
      nameExtractor: (p) => p.portfolioName,
      subtitleExtractor: (p) {
        final id = externalIds[p.portfolioId];
        if (id == null || id.isEmpty) return null;
        final broker = (p.brokerType ?? p.portfolioName).toUpperCase();
        if (broker.contains('NPS')) return 'PRAN $id';
        return id;
      },
      accentColor: ModuleColors.portfolio,
      defaultPortfolioId: _defaultPortfolioId,
      onToggleDefault: _toggleDefault,
      isSelectableExtractor: (p) =>
          p.portfolioId == 'all' || p.isDummy || p.hasHoldings,
      showNoHoldingsBadgeExtractor: (p) =>
          p.portfolioId != 'all' && !p.isDummy && !p.hasHoldings,
    );
  }
}
