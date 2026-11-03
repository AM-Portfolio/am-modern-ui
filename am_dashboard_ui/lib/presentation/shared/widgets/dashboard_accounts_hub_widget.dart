import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_widget_id.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_overlay_provider.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_portfolio_scope.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/glass_card.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Users peer panel: identity, count chips, Overview|Brokers|MF|Demat|NPS|Family.
class DashboardUsersHubWidget extends ConsumerStatefulWidget {
  const DashboardUsersHubWidget({
    super.key,
    required this.userId,
    this.onOpenDocIntel,
    this.onOpenUsers,
  });

  final String userId;
  final VoidCallback? onOpenDocIntel;
  final VoidCallback? onOpenUsers;

  @override
  ConsumerState<DashboardUsersHubWidget> createState() =>
      _DashboardUsersHubWidgetState();
}

/// Kept for catalog / older imports.
@Deprecated('Use DashboardUsersHubWidget')
typedef DashboardAccountsHubWidget = DashboardUsersHubWidget;

enum _UsersPrimaryTab { overview, brokers, mf, demat, nps, family }

class _DashboardUsersHubWidgetState
    extends ConsumerState<DashboardUsersHubWidget> {
  _UsersPrimaryTab _primary = _UsersPrimaryTab.overview;

  /// Secondary broker chip under Brokers / Demat / MF (`all` or broker key).
  String _brokerFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(accountsHubProvider(widget.userId));
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return AmGlassCard(
      padding: const EdgeInsets.all(14),
      child: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (err, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DashboardWidgetId.accountsHub.label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: ModuleColors.dashboard,
              ),
            ),
            const SizedBox(height: 8),
            Text('Could not load users.', style: context.text.caption()),
            TextButton(
              onPressed: () =>
                  ref.invalidate(accountsHubProvider(widget.userId)),
              child: const Text('Retry'),
            ),
          ],
        ),
        data: (hub) {
          final hasCas = hub.dematAccounts.isNotEmpty;
          final hasNps = hub.nps?.pran != null && hub.nps!.pran!.isNotEmpty;
          final showNps = hasNps &&
              (_primary == _UsersPrimaryTab.overview ||
                  _primary == _UsersPrimaryTab.nps);
          final brokerChips = _secondaryBrokerChips(hub);
          final demat = _filteredByBroker(hub.dematAccounts);
          final mfRows = demat
              .where((a) => (a.accountType ?? '').toLowerCase() == 'mf')
              .toList();
          final dematOnly = demat
              .where((a) => (a.accountType ?? '').toLowerCase() != 'mf')
              .toList();
          final portfolios = _filteredPortfolios(hub);
          final showDematSection = _primary == _UsersPrimaryTab.demat ||
              _primary == _UsersPrimaryTab.overview;
          final showMfSection = _primary == _UsersPrimaryTab.mf ||
              _primary == _UsersPrimaryTab.overview;
          final showBrokersSection = _primary == _UsersPrimaryTab.brokers ||
              _primary == _UsersPrimaryTab.overview;
          final showCasCta = !hasCas &&
              (_primary == _UsersPrimaryTab.overview ||
                  _primary == _UsersPrimaryTab.demat ||
                  _primary == _UsersPrimaryTab.mf);
          final isFamily = _primary == _UsersPrimaryTab.family;
          final isOverview = _primary == _UsersPrimaryTab.overview;

          final brokerCount =
              hub.portfolios.where((p) => p.isRunningBroker).length;
          final mfCount = hub.dematAccounts
              .where((a) => (a.accountType ?? '').toLowerCase() == 'mf')
              .length;
          final dematCount = hub.dematAccounts
              .where((a) => (a.accountType ?? '').toLowerCase() != 'mf')
              .length;
          final showBrokerSwitcher = !isFamily &&
              (_primary == _UsersPrimaryTab.brokers ||
                  _primary == _UsersPrimaryTab.demat ||
                  _primary == _UsersPrimaryTab.mf ||
                  _primary == _UsersPrimaryTab.overview) &&
              brokerChips.length > 1;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CompactHeader(
                identity: hub.identity,
                nps: hub.nps,
                xirrPct: hub.stats?.overallXirrPct,
                onOpenUsers: widget.onOpenUsers,
              ),
              const SizedBox(height: 8),
              _StatsChips(
                stats: hub.stats,
                highlightNps: _primary == _UsersPrimaryTab.nps,
              ),
              const SizedBox(height: 8),
              _CompactFilterRow(
                selected: _primary,
                brokerCount: brokerCount,
                mfCount: mfCount,
                dematCount: dematCount,
                hasNps: hasNps,
                onTabSelected: (tab) => setState(() {
                  _primary = tab;
                  _brokerFilter = 'all';
                }),
                brokerOptions: showBrokerSwitcher ? brokerChips : const [],
                brokerSelected: _brokerFilter,
                onBrokerSelected: _onSecondaryBrokerSelected,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isFamily) ...[
                        _FamilyTab(
                          onAdd: () => _showAddFamilyStub(context),
                        ),
                      ] else ...[
                        if (showCasCta && widget.onOpenDocIntel != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: widget.onOpenDocIntel,
                              child: const Text(
                                'Import CDSL CAS via Doc Intel',
                              ),
                            ),
                          ),
                        if (showNps) ...[
                          _NpsStrip(nps: hub.nps!, currency: currency),
                        ],
                        if (showDematSection &&
                            !isOverview &&
                            dematOnly.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Demat accounts',
                            style: context.text.label().copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                          ),
                          const SizedBox(height: 6),
                          ...dematOnly.map(
                            (a) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _DematDetailCard(
                                account: a,
                                currency: currency,
                              ),
                            ),
                          ),
                        ],
                        if (showMfSection &&
                            !isOverview &&
                            mfRows.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'MF folios',
                            style: context.text.label().copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                          ),
                          const SizedBox(height: 6),
                          ...mfRows.map(
                            (a) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _FolioDetailCard(
                                account: a,
                                currency: currency,
                              ),
                            ),
                          ),
                        ],
                        if (showBrokersSection &&
                            !isOverview &&
                            portfolios.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Brokers',
                            style: context.text.label().copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                          ),
                          const SizedBox(height: 6),
                          ...portfolios.map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _PortfolioCard(
                                row: p,
                                currency: currency,
                                onTap: () => _selectPortfolio(p),
                              ),
                            ),
                          ),
                        ],
                        if ((_primary == _UsersPrimaryTab.demat &&
                                dematOnly.isNotEmpty) ||
                            (_primary == _UsersPrimaryTab.mf &&
                                mfRows.isNotEmpty) ||
                            (_primary == _UsersPrimaryTab.nps && showNps)) ...[
                          const SizedBox(height: 8),
                          _NomineeSection(
                            accounts: [
                              if (_primary == _UsersPrimaryTab.demat)
                                ...dematOnly,
                              if (_primary == _UsersPrimaryTab.mf) ...mfRows,
                            ],
                            nps: _primary == _UsersPrimaryTab.nps
                                ? hub.nps
                                : null,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddFamilyStub(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add family member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    emailCtrl.dispose();
    if (!context.mounted || added != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Family linking coming soon')),
    );
  }

  List<({String key, String label, String? portfolioId})> _secondaryBrokerChips(
    AccountsHub hub,
  ) {
    final out = <({String key, String label, String? portfolioId})>[
      (key: 'all', label: 'All', portfolioId: null),
    ];
    final seen = <String>{'all'};
    for (final p in hub.portfolios) {
      if (!p.isRunningBroker) continue;
      final broker = (p.brokerType ?? p.displayName ?? '').trim();
      if (broker.isEmpty) continue;
      final key = broker.toUpperCase();
      if (!seen.add(key)) continue;
      out.add((
        key: key,
        label: p.displayName?.trim().isNotEmpty == true
            ? p.displayName!.trim()
            : broker,
        portfolioId: p.portfolioId,
      ));
    }
    return out;
  }

  List<DematAccountRow> _filteredByBroker(List<DematAccountRow> all) {
    if (_brokerFilter == 'all') return all;
    return all.where((a) {
      final mapped = (a.mappedBroker ?? '').toUpperCase();
      return mapped == _brokerFilter;
    }).toList();
  }

  List<AccountsPortfolioRow> _filteredPortfolios(AccountsHub hub) {
    final rows = hub.portfolios.where((p) => p.isRunningBroker).toList();
    if (_brokerFilter == 'all') return rows;
    return rows.where((p) {
      final key = (p.brokerType ?? p.displayName ?? '').trim().toUpperCase();
      return key == _brokerFilter;
    }).toList();
  }

  void _onSecondaryBrokerSelected(
    String key,
    String label,
    String? portfolioId,
  ) {
    setState(() => _brokerFilter = key);
    if (_primary != _UsersPrimaryTab.brokers) return;
    if (key == 'all' || portfolioId == null || portfolioId.isEmpty) return;
    _scopePortfolio(portfolioId, label);
  }

  void _selectPortfolio(AccountsPortfolioRow p) {
    final id = p.portfolioId;
    if (id == null || id.isEmpty) return;
    final label = p.displayName?.trim().isNotEmpty == true
        ? p.displayName!.trim()
        : (p.brokerType ?? id);
    _scopePortfolio(id, label);
  }

  void _scopePortfolio(String portfolioId, String label) {
    context.selectPortfolio(portfolioId, label);
    ref.read(dashboardPortfolioScopeProvider.notifier).select(portfolioId);
    ref
        .read(dashboardOverlayProvider(widget.userId).notifier)
        .setPreferredPortfolioId(portfolioId);
  }
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({
    required this.onOpenUsers,
    this.identity,
    this.nps,
    this.xirrPct,
  });

  final AccountsIdentity? identity;
  final NpsMetaRow? nps;
  final double? xirrPct;
  final VoidCallback? onOpenUsers;

  @override
  Widget build(BuildContext context) {
    final rawName = identity?.name ?? nps?.subscriberName;
    final name = () {
      final n = rawName?.trim() ?? '';
      if (n.isEmpty) return '—';
      if (!n.contains(' ') && n.length <= 12) return n.toUpperCase();
      return n;
    }();
    final pran = identity?.pran ?? nps?.pran;
    final accent = ModuleColors.dashboard;
    final muted = context.colors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: context.statusSuccess,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: onOpenUsers,
              borderRadius: BorderRadius.circular(AppRadii.xs),
              child: Text(
                DashboardWidgetId.accountsHub.label.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.6,
                  color: accent,
                ),
              ),
            ),
            const Spacer(),
            if (onOpenUsers != null)
              IconButton(
                tooltip: 'Open Users',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onOpenUsers,
                icon: Icon(Icons.open_in_new_rounded, size: 16, color: accent),
              ),
            if (xirrPct != null) ...[
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      xirrPct! >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 12,
                      color: accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'XIRR ${xirrPct!.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: context.text.body().copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
        ),
        if (pran != null && pran.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: context.colors.border.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PRAN $pran',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: muted,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.copy_rounded, size: 12, color: muted),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CompactFilterRow extends StatelessWidget {
  const _CompactFilterRow({
    required this.selected,
    required this.onTabSelected,
    required this.brokerCount,
    required this.mfCount,
    required this.dematCount,
    required this.hasNps,
    required this.brokerOptions,
    required this.brokerSelected,
    required this.onBrokerSelected,
  });

  final _UsersPrimaryTab selected;
  final ValueChanged<_UsersPrimaryTab> onTabSelected;
  final int brokerCount;
  final int mfCount;
  final int dematCount;
  final bool hasNps;
  final List<({String key, String label, String? portfolioId})> brokerOptions;
  final String brokerSelected;
  final void Function(String key, String label, String? portfolioId)
      onBrokerSelected;

  @override
  Widget build(BuildContext context) {
    final tabs = <(_UsersPrimaryTab, String)>[
      (_UsersPrimaryTab.overview, 'Overview'),
      (_UsersPrimaryTab.brokers, 'Broker ($brokerCount)'),
      (_UsersPrimaryTab.mf, 'MF ($mfCount)'),
      (_UsersPrimaryTab.demat, 'Demat ($dematCount)'),
      (_UsersPrimaryTab.nps, hasNps ? 'NPS (1)' : 'NPS (0)'),
      (_UsersPrimaryTab.family, 'Family'),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final t in tabs)
          ChoiceChip(
            label: Text(t.$2, style: const TextStyle(fontSize: 11)),
            selected: selected == t.$1,
            onSelected: (_) => onTabSelected(t.$1),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        if (brokerOptions.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              '·',
              style: TextStyle(color: context.colors.textTertiary),
            ),
          ),
          for (final o in brokerOptions)
            ChoiceChip(
              label: Text(o.label, style: const TextStyle(fontSize: 11)),
              selected: brokerSelected == o.key,
              onSelected: (_) => onBrokerSelected(o.key, o.label, o.portfolioId),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
        ],
      ],
    );
  }
}

class _FamilyTab extends StatelessWidget {
  const _FamilyTab({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.border.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'No family members yet',
            style: context.text.label().copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Link household members when family sharing is available.',
            style: context.text.caption().copyWith(
                  color: context.colors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonal(
              onPressed: onAdd,
              child: const Text('Add family member'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({
    required this.row,
    required this.currency,
    required this.onTap,
  });

  final AccountsPortfolioRow row;
  final NumberFormat currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = row.displayName?.trim().isNotEmpty == true
        ? row.displayName!.trim()
        : (row.brokerType ?? row.portfolioId ?? 'Portfolio');
    final broker = row.brokerType?.trim();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border:
              Border.all(color: context.colors.border.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: context.text.label().copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
            ),
            if (broker != null &&
                broker.isNotEmpty &&
                broker.toUpperCase() != title.toUpperCase())
              Text(broker, style: context.text.caption()),
            const SizedBox(height: 4),
            Text(
              [
                if (row.current != null) currency.format(row.current),
                if (row.assetCount != null) '${row.assetCount} assets',
                if (row.returnPct != null)
                  '${row.returnPct!.toStringAsFixed(1)}%',
              ].join(' · '),
              style: context.text.caption().copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.dashboard;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: emphasized ? accent : accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Text(
        label,
        style: context.text.caption().copyWith(
              fontWeight: FontWeight.w700,
              color: emphasized ? const Color(0xFF1A1208) : accent,
              fontSize: 10,
            ),
      ),
    );
  }
}

class _StatsChips extends StatelessWidget {
  const _StatsChips({this.stats, this.highlightNps = false});

  final AccountsStats? stats;
  final bool highlightNps;

  @override
  Widget build(BuildContext context) {
    if (stats == null) return const SizedBox.shrink();
    final items = <(String, bool)>[
      if (stats!.activeDematCount != null)
        ('Demat ${stats!.activeDematCount}', false),
      if (stats!.mfFolioCount != null) ('MF ${stats!.mfFolioCount}', false),
      if (stats!.brokerPortfolioCount != null)
        ('Brokers ${stats!.brokerPortfolioCount}', false),
      if (stats!.npsLinked == true) ('NPS', highlightNps),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final item in items)
          _Chip(label: item.$1, emphasized: item.$2),
      ],
    );
  }
}

class _NpsStrip extends StatelessWidget {
  const _NpsStrip({required this.nps, required this.currency});

  final NpsMetaRow nps;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.dashboard;
    final muted = context.colors.textSecondary;
    final t1 = nps.tier1Value;
    final t2 = nps.tier2Value;
    final total = nps.totalValue ??
        ((t1 ?? 0) + (t2 ?? 0) > 0 ? (t1 ?? 0) + (t2 ?? 0) : null);
    final t1Pct = (total != null && total > 0 && t1 != null)
        ? (t1 / total).clamp(0.0, 1.0)
        : null;
    final nomineeRaw = nps.nomineeDetails?.trim();
    String? nomineeName;
    String? nomineePct;
    if (nomineeRaw != null && nomineeRaw.isNotEmpty) {
      final m = RegExp(r'^(.*?)\s*\(?(\d+(?:\.\d+)?%)\)?\s*$')
          .firstMatch(nomineeRaw);
      if (m != null) {
        nomineeName = m.group(1)?.trim();
        nomineePct = m.group(2);
      } else {
        nomineeName = nomineeRaw;
      }
    }

    return Container(
      key: const Key('users_nps_strip'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.border.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'NPS (National Pension System)',
                  style: context.text.label().copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.statusSuccess.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: context.statusSuccess.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'REGULAR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: context.statusSuccess,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              if (nps.pran != null)
                Text(
                  'PRAN ${nps.pran}',
                  style: TextStyle(
                    fontSize: 11,
                    color: muted,
                    fontFamily: 'monospace',
                  ),
                ),
              if (nps.registrationDate != null &&
                  nps.registrationDate!.trim().isNotEmpty)
                Text(
                  'Reg ${nps.registrationDate}',
                  style: TextStyle(fontSize: 11, color: muted),
                ),
              if (nps.asOfDate != null)
                Text(
                  'As of ${nps.asOfDate}',
                  style: TextStyle(fontSize: 11, color: muted),
                ),
            ],
          ),
          if (t1 != null || t2 != null || total != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (t1 != null)
                        Text(
                          'T-I ${currency.format(t1)}'
                          '${t1Pct != null ? ' (${(t1Pct * 100).toStringAsFixed(1)}%)' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (t2 != null)
                        Text(
                          'T-II ${currency.format(t2)}'
                          '${t1Pct != null ? ' (${((1 - t1Pct) * 100).toStringAsFixed(1)}%)' : ''}',
                          style: TextStyle(fontSize: 12, color: muted),
                        ),
                    ],
                  ),
                ),
                if (total != null)
                  Text(
                    currency.format(total),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
              ],
            ),
            if (t1Pct != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 6,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (t1Pct * 1000).round().clamp(1, 999),
                        child: ColoredBox(color: accent),
                      ),
                      Expanded(
                        flex: ((1 - t1Pct) * 1000).round().clamp(1, 999),
                        child: ColoredBox(
                          color: accent.withValues(alpha: 0.25),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
          if (nomineeName != null && nomineeName.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Nominee: $nomineeName',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (nomineePct != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      nomineePct,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Consolidated NPS Folio',
                style: TextStyle(fontSize: 10, color: muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DematDetailCard extends StatelessWidget {
  const _DematDetailCard({required this.account, required this.currency});

  final DematAccountRow account;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final title = account.dpName ?? account.boid ?? account.accountNo;
    final ids = [
      if (account.boid != null && account.boid!.isNotEmpty)
        'BOID ${account.boid}',
      if (account.clientId != null && account.clientId!.isNotEmpty)
        'Client ${account.clientId}',
      if (account.dpId != null && account.dpId!.isNotEmpty) 'DP ${account.dpId}',
      if (account.accountNo.isNotEmpty && account.accountNo != account.boid)
        'A/c ${account.accountNo}',
    ].join(' · ');
    final meta = [
      if (account.accountType != null) account.accountType!.toUpperCase(),
      if (account.status != null) account.status,
      if (account.mappedBroker != null) account.mappedBroker,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.border.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: context.text.label().copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                ),
              ),
              if (account.holdingValue != null)
                Text(
                  currency.format(account.holdingValue),
                  style: context.text.label().copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                ),
            ],
          ),
          if (ids.isNotEmpty)
            Text(ids, style: context.text.caption().copyWith(fontSize: 10)),
          if (meta.isNotEmpty)
            Text(meta, style: context.text.caption().copyWith(fontSize: 10)),
          if (_dematAccountDetailLine(account).isNotEmpty)
            Text(
              _dematAccountDetailLine(account),
              style: context.text.caption().copyWith(fontSize: 10),
            ),
        ],
      ),
    );
  }
}

String _dematAccountDetailLine(DematAccountRow a) {
  final nominee = a.nominee?.trim();
  final nomineeLabel = (nominee != null &&
          nominee.isNotEmpty &&
          !nominee.toLowerCase().contains('not registered') &&
          nominee.toLowerCase() != 'please nominate')
      ? 'Nominee $nominee'
      : (a.nomineeRegistered == false ? 'No nominee' : null);
  final frozen = a.frozenStatus?.trim();
  final frozenLabel = (frozen != null &&
          frozen.isNotEmpty &&
          !frozen.toLowerCase().contains('not frozen'))
      ? frozen
      : null;
  return [
    if (nomineeLabel != null) nomineeLabel,
    if (frozenLabel != null) frozenLabel,
  ].join(' · ');
}

class _FolioDetailCard extends StatelessWidget {
  const _FolioDetailCard({required this.account, required this.currency});

  final DematAccountRow account;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final folio = account.folio?.trim().isNotEmpty == true
        ? account.folio!
        : account.accountNo;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.border.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Folio $folio',
                  style: context.text.label().copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                ),
              ),
              if (account.holdingValue != null)
                Text(
                  currency.format(account.holdingValue),
                  style: context.text.label().copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                ),
            ],
          ),
          if (account.amcName != null && account.amcName!.isNotEmpty)
            Text(account.amcName!, style: context.text.caption()),
          Text(
            [
              if (account.mappedBroker != null) account.mappedBroker,
              if (account.status != null) account.status,
            ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
            style: context.text.caption().copyWith(fontSize: 10),
          ),
          if (_dematAccountDetailLine(account).isNotEmpty)
            Text(
              _dematAccountDetailLine(account),
              style: context.text.caption().copyWith(fontSize: 10),
            ),
        ],
      ),
    );
  }
}

class _NomineeSection extends StatelessWidget {
  const _NomineeSection({required this.accounts, this.nps});

  final List<DematAccountRow> accounts;
  final NpsMetaRow? nps;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (final a in accounts) {
      final accountLabel = a.accountType == 'mf'
          ? 'Folio ${a.folio ?? a.accountNo}'
          : (a.dpName ?? a.boid ?? a.accountNo);
      final name = a.nominee?.trim();
      final status = a.nomineeRegistered == true
          ? 'Registered'
          : (a.nomineeRegistered == false
              ? 'Not registered'
              : (name != null && name.isNotEmpty ? 'Listed' : 'Unknown'));
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  accountLabel,
                  style: context.text.caption().copyWith(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  name != null && name.isNotEmpty ? name : '—',
                  style: context.text.caption().copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                ),
              ),
              Text(
                status,
                style: context.text.caption().copyWith(
                      fontSize: 10,
                      color: a.nomineeRegistered == false
                          ? context.colors.statusError
                          : context.colors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }
    final npsNominee = nps?.nomineeDetails?.trim();
    if (npsNominee != null && npsNominee.isNotEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('NPS', style: context.text.caption()),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  npsNominee,
                  style: context.text.caption().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (rows.isEmpty) {
      rows.add(
        Text(
          'No nominee details on file.',
          style: context.text.caption().copyWith(
                color: context.colors.textSecondary,
              ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.colors.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nominee details',
            style: context.text.label().copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }
}
