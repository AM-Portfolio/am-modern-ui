import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';
import 'package:am_dashboard_ui/presentation/mappers/advanced_account_row_mapper.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/glass_card.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Full Users detail page — holdings-style accounts table + live hub APIs.
class DashboardUsersPage extends ConsumerStatefulWidget {
  const DashboardUsersPage({
    super.key,
    required this.userId,
    this.onOpenDocIntel,
    this.onBack,
  });

  final String userId;
  final VoidCallback? onOpenDocIntel;
  final VoidCallback? onBack;

  @override
  ConsumerState<DashboardUsersPage> createState() => _DashboardUsersPageState();
}

enum _UsersPageTab { overview, brokers, mf, demat, nps, family }

class _DashboardUsersPageState extends ConsumerState<DashboardUsersPage> {
  _UsersPageTab _tab = _UsersPageTab.overview;
  String _brokerFilter = 'all';

  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(accountsHubProvider(widget.userId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load users.', style: context.text.body()),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(accountsHubProvider(widget.userId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (hub) => _body(context, hub),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AccountsHub hub) {
    final name = hub.identity?.name ?? hub.nps?.subscriberName;
    final pran = hub.identity?.pran ?? hub.nps?.pran;
    final hasLinked = (hub.portfolios.isNotEmpty) ||
        hub.dematAccounts.isNotEmpty ||
        (hub.nps?.pran?.isNotEmpty == true);

    final runningBrokers =
        hub.portfolios.where((p) => p.isRunningBroker).toList();
    final demat = hub.dematAccounts
        .where((a) => (a.accountType ?? '').toLowerCase() != 'mf')
        .toList();
    final mf = hub.dematAccounts
        .where((a) => (a.accountType ?? '').toLowerCase() == 'mf')
        .toList();
    final hasNps = hub.nps?.pran != null && hub.nps!.pran!.isNotEmpty;
    String? npsPortfolioId;
    for (final p in hub.portfolios) {
      final id = p.portfolioId;
      if (p.isNps && id != null && id.isNotEmpty) {
        npsPortfolioId = id;
        break;
      }
    }

    final allRows = mapAccountsHubToAdvancedRows(
      brokers: runningBrokers,
      mf: mf,
      demat: demat,
      hub: hub,
      hasNps: hasNps,
    );
    final tabKey = switch (_tab) {
      _UsersPageTab.overview => 'overview',
      _UsersPageTab.brokers => 'brokers',
      _UsersPageTab.mf => 'mf',
      _UsersPageTab.demat => 'demat',
      _UsersPageTab.nps => 'nps',
      _UsersPageTab.family => 'family',
    };
    var rows = filterAdvancedAccountRowsByTab(rows: allRows, tab: tabKey);
    final showBrokerSwitcher = (_tab == _UsersPageTab.brokers ||
            _tab == _UsersPageTab.mf ||
            _tab == _UsersPageTab.demat ||
            _tab == _UsersPageTab.overview) &&
        (runningBrokers.isNotEmpty || demat.isNotEmpty || mf.isNotEmpty);
    if (showBrokerSwitcher) {
      rows = filterAdvancedAccountRowsByBroker(
        rows: rows,
        brokerFilter: _brokerFilter,
      );
    }

    final swatchOptions = buildBrokerSwatchOptions(
      runningBrokers: runningBrokers,
      demat: demat,
      mf: mf,
      tab: tabKey,
    );

    final schemesAsync = (_tab == _UsersPageTab.nps &&
            npsPortfolioId != null &&
            npsPortfolioId.isNotEmpty)
        ? ref.watch(npsSchemesProvider(npsPortfolioId))
        : null;

    final hasCasDirectory = demat.isNotEmpty || mf.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (widget.onBack != null)
                    IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Back',
                    ),
                  Expanded(
                    child: Text(
                      'Users',
                      style: context.text.pageTitle().copyWith(
                            fontWeight: FontWeight.w700,
                            color: ModuleColors.dashboard,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ProfileHeader(
                name: name,
                pran: pran,
                registrationDate: hub.nps?.registrationDate,
                nomineeDetails: hub.nps?.nomineeDetails,
                hasLinked: hasLinked,
                hasCas: hasCasDirectory,
                showKpis: _tab != _UsersPageTab.family,
                kpis: _tabKpis(
                  tab: _tab,
                  brokers: runningBrokers,
                  demat: demat,
                  mf: mf,
                  hub: hub,
                  hasNps: hasNps,
                ),
                brokerSwatches: showBrokerSwitcher
                    ? _BrokerSwatches(
                        options: swatchOptions,
                        selected: _brokerFilter,
                        displayingCount: rows.length,
                        onSelected: (key) =>
                            setState(() => _brokerFilter = key),
                      )
                    : null,
              ),
              if ((_tab == _UsersPageTab.demat || _tab == _UsersPageTab.mf) &&
                  hub.dematAccounts.isEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'No CDSL CAS demat/MF directory yet.',
                  style: context.text.caption(),
                ),
                if (widget.onOpenDocIntel != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: widget.onOpenDocIntel,
                      child: const Text('Import CDSL CAS via Doc Intel'),
                    ),
                  ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
        if (_tab == _UsersPageTab.family)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                        color: context.colors.border.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: _CategoryTabs(
                        selected: _tab,
                        labelFor: (t) =>
                            _tabLabel(t, runningBrokers, mf, demat, hasNps),
                        onSelected: (t) => setState(() {
                          _tab = t;
                          _brokerFilter = 'all';
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: AmGlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Family linking is not available yet.',
                        style: context.text.body().copyWith(
                              color: context.colors.textSecondary,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: context.colors.border.withValues(alpha: 0.4),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: AdvancedAccountsTemplate(
                    accounts: rows,
                    isLoading: false,
                    accentColor: ModuleColors.dashboard,
                    toolbarLeading: _CategoryTabs(
                      selected: _tab,
                      labelFor: (t) =>
                          _tabLabel(t, runningBrokers, mf, demat, hasNps),
                      onSelected: (t) => setState(() {
                        _tab = t;
                        _brokerFilter = 'all';
                      }),
                    ),
                    footerNoun: _footerNoun(_tab),
                    footerCenterNote:
                        (_tab == _UsersPageTab.demat ||
                                    _tab == _UsersPageTab.mf) &&
                                hasCasDirectory
                            ? 'All CDSL accounts verified via OTP'
                            : null,
                    onRefresh: () =>
                        ref.invalidate(accountsHubProvider(widget.userId)),
                    emptyTitle: 'No rows for this view',
                    emptySubtitle: 'Switch filters or import CDSL CAS',
                  ),
                ),
              ),
            ),
          ),
        if (_tab == _UsersPageTab.nps && schemesAsync != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: schemesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
                error: (_, __) => Text(
                  'Could not load NPS schemes.',
                  style: context.text.caption(),
                ),
                data: (schemes) {
                  if (schemes.isEmpty) {
                    return Text(
                      'No NPS schemes on the linked portfolio yet.',
                      style: context.text.caption().copyWith(
                            color: context.colors.textSecondary,
                          ),
                    );
                  }
                  return ListView(
                    children: [
                      Text(
                        'Schemes (${schemes.length})',
                        style: context.text.label().copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                      ),
                      const SizedBox(height: 8),
                      for (final s in schemes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AmGlassCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.name?.trim().isNotEmpty == true
                                            ? s.name!.trim()
                                            : (s.schemeCode ??
                                                s.isin ??
                                                'Scheme'),
                                        style: context.text.label().copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      Text(
                                        [
                                          if (s.tier != null) 'Tier ${s.tier}',
                                          if (s.schemeClass != null)
                                            'Class ${s.schemeClass}',
                                          if (s.isin != null) s.isin!,
                                        ].join(' · '),
                                        style: context.text.caption(),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _inr.format(
                                    s.liveValue ?? s.statementValue ?? 0,
                                  ),
                                  style: context.text.label().copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  List<_KpiSpec> _tabKpis({
    required _UsersPageTab tab,
    required List<AccountsPortfolioRow> brokers,
    required List<DematAccountRow> demat,
    required List<DematAccountRow> mf,
    required AccountsHub hub,
    required bool hasNps,
  }) {
    final dematStats = dematNomineeStats(demat);
    final mfStats = dematNomineeStats(mf);
    final brokerValue =
        brokers.fold<double>(0, (s, p) => s + (p.current ?? 0));
    final brokerAssets =
        brokers.fold<int>(0, (s, p) => s + (p.assetCount ?? 0));
    final combined = brokerValue +
        dematStats.totalValue +
        mfStats.totalValue +
        (hub.nps?.totalValue ?? 0);

    ({String value, String? sub, bool warn}) nomineeAudit({
      required int ok,
      required int missing,
      required int total,
    }) {
      if (total == 0) {
        return (value: '—', sub: null, warn: false);
      }
      final pct = ((ok / total) * 100).round();
      return (
        value: '$pct%',
        sub: missing > 0 ? '$missing action needed' : null,
        warn: missing > 0,
      );
    }

    switch (tab) {
      case _UsersPageTab.demat:
        final audit = nomineeAudit(
          ok: dematStats.nomineeOk,
          missing: dematStats.nomineeMissing,
          total: demat.length,
        );
        return [
          _KpiSpec(
            label: 'Total Demat Value',
            value: _inr.format(dematStats.totalValue),
          ),
          _KpiSpec(
            label: 'Linked Demats',
            value: '${dematStats.linkedCount} Accounts',
            sub: '${dematStats.brokersActive} Brokers active',
          ),
          _KpiSpec(
            label: 'Nominee Audits',
            value: audit.value,
            sub: audit.sub,
            warn: audit.warn,
          ),
        ];
      case _UsersPageTab.brokers:
        return [
          _KpiSpec(
            label: 'Total Broker Value',
            value: _inr.format(brokerValue),
          ),
          _KpiSpec(
            label: 'Active Brokers',
            value: '${brokers.length}',
          ),
          _KpiSpec(
            label: 'Assets',
            value: '$brokerAssets',
          ),
        ];
      case _UsersPageTab.mf:
        final audit = nomineeAudit(
          ok: mfStats.nomineeOk,
          missing: mfStats.nomineeMissing,
          total: mf.length,
        );
        return [
          _KpiSpec(
            label: 'Total MF Value',
            value: _inr.format(mfStats.totalValue),
          ),
          _KpiSpec(
            label: 'MF folios',
            value: '${mf.length}',
          ),
          _KpiSpec(
            label: 'Nominee Audits',
            value: audit.value,
            sub: audit.sub,
            warn: audit.warn,
          ),
        ];
      case _UsersPageTab.nps:
        final n = hub.nps;
        return [
          _KpiSpec(
            label: 'NPS Total',
            value: n?.totalValue != null ? _inr.format(n!.totalValue!) : '—',
          ),
          _KpiSpec(
            label: 'PRAN linked',
            value: hasNps ? 'Yes' : 'No',
          ),
          _KpiSpec(
            label: 'Tiers',
            value: [
              if (n?.tier1Value != null) 'T-I',
              if (n?.tier2Value != null) 'T-II',
            ].join(' / ').ifEmpty('—'),
          ),
        ];
      case _UsersPageTab.overview:
        final ok = dematStats.nomineeOk + mfStats.nomineeOk;
        final missing = dematStats.nomineeMissing + mfStats.nomineeMissing;
        final total = demat.length + mf.length;
        final audit =
            nomineeAudit(ok: ok, missing: missing, total: total);
        return [
          _KpiSpec(
            label: 'Combined Value',
            value: _inr.format(combined),
          ),
          _KpiSpec(
            label: 'Accounts',
            value:
                '${brokers.length} Brokers / ${demat.length} Demats / ${mf.length} MF',
          ),
          _KpiSpec(
            label: 'Nominee Audits',
            value: audit.value,
            sub: audit.sub,
            warn: audit.warn,
          ),
        ];
      case _UsersPageTab.family:
        return const [];
    }
  }

  String _tabLabel(
    _UsersPageTab t,
    List<AccountsPortfolioRow> brokers,
    List<DematAccountRow> mf,
    List<DematAccountRow> demat,
    bool hasNps,
  ) {
    return switch (t) {
      _UsersPageTab.overview => 'Overview',
      _UsersPageTab.brokers => 'Broker (${brokers.length})',
      _UsersPageTab.mf => 'Mutual Fund (${mf.length})',
      _UsersPageTab.demat => 'Demat (${demat.length})',
      _UsersPageTab.nps => hasNps ? 'NPS (1)' : 'NPS (0)',
      _UsersPageTab.family => 'Family',
    };
  }

  String _footerNoun(_UsersPageTab t) => switch (t) {
        _UsersPageTab.demat => 'Demat accounts',
        _UsersPageTab.mf => 'MF folios',
        _UsersPageTab.brokers => 'broker accounts',
        _UsersPageTab.nps => 'NPS accounts',
        _ => 'accounts',
      };
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}

class _KpiSpec {
  const _KpiSpec({
    required this.label,
    required this.value,
    this.sub,
    this.warn = false,
  });

  final String label;
  final String value;
  final String? sub;
  final bool warn;
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.hasLinked,
    required this.hasCas,
    required this.showKpis,
    required this.kpis,
    this.pran,
    this.registrationDate,
    this.nomineeDetails,
    this.brokerSwatches,
  });

  final String? name;
  final String? pran;
  final String? registrationDate;
  final String? nomineeDetails;
  final bool hasLinked;
  final bool hasCas;
  final bool showKpis;
  final List<_KpiSpec> kpis;
  final Widget? brokerSwatches;

  String get _displayName {
    final n = name?.trim() ?? '';
    if (n.isEmpty) return '—';
    if (!n.contains(' ') && n.length <= 12) return n.toUpperCase();
    return n;
  }

  String get _initials {
    final n = name?.trim() ?? '';
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return (parts.first.length >= 2
            ? parts.first.substring(0, 2)
            : parts.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.dashboard;
    final muted = context.colors.textSecondary;
    final success = context.statusSuccess;

    return AmGlassCard(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final left = _leftStack(context, accent, muted, success);
          final right = showKpis && kpis.isNotEmpty
              ? _kpiRow(context, accent)
              : const SizedBox.shrink();
          final top = wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: left),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: right),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    left,
                    if (showKpis && kpis.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      right,
                    ],
                  ],
                );
          if (brokerSwatches == null) return top;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              top,
              const SizedBox(height: 12),
              brokerSwatches!,
            ],
          );
        },
      ),
    );
  }

  Widget _leftStack(
    BuildContext context,
    Color accent,
    Color muted,
    Color success,
  ) {
    final subtitle = hasCas
        ? 'Primary Investor Profile • CDSL & NSDL Registered'
        : 'Primary Investor Profile';
    final nominee = nomineeDetails?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.18),
                border: Border.all(color: accent.withValues(alpha: 0.45)),
              ),
              child: Text(
                _initials,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _displayName,
                        style: context.text.sectionTitle().copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                      ),
                      if (hasLinked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: success.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: success.withValues(alpha: 0.55),
                            ),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: success,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (pran != null && pran!.isNotEmpty)
              _MetaPill(icon: Icons.badge_outlined, text: 'PRAN $pran'),
            if (registrationDate != null &&
                registrationDate!.trim().isNotEmpty)
              _MetaPill(
                icon: Icons.event_outlined,
                text: 'Reg $registrationDate',
              ),
            if (nominee != null && nominee.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withValues(alpha: 0.65)),
                  color: accent.withValues(alpha: 0.06),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline, size: 14, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      nominee,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _kpiRow(BuildContext context, Color accent) {
    return Row(
      children: [
        for (var i = 0; i < kpis.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _KpiTile(spec: kpis[i], accent: accent)),
        ],
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.spec, required this.accent});

  final _KpiSpec spec;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final muted = context.colors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.colors.border.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            spec.label,
            style: TextStyle(fontSize: 11, color: muted),
          ),
          const SizedBox(height: 4),
          Text(
            spec.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          if (spec.sub != null && spec.sub!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              spec.sub!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: spec.warn ? accent : muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = context.colors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.4),
        border: Border.all(
          color: context.colors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: muted),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(fontSize: 11, color: muted)),
        ],
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.selected,
    required this.labelFor,
    required this.onSelected,
  });

  final _UsersPageTab selected;
  final String Function(_UsersPageTab) labelFor;
  final ValueChanged<_UsersPageTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.dashboard;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in _UsersPageTab.values)
          InkWell(
            onTap: () => onSelected(t),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected == t ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected == t
                      ? accent
                      : context.colors.border.withValues(alpha: 0.7),
                ),
              ),
              child: Text(
                labelFor(t),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected == t
                      ? const Color(0xFF1A1208)
                      : context.colors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BrokerSwatches extends StatelessWidget {
  const _BrokerSwatches({
    required this.options,
    required this.selected,
    required this.displayingCount,
    required this.onSelected,
  });

  final List<({String key, String label, int count})> options;
  final String selected;
  final int displayingCount;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.dashboard;
    final muted = context.colors.textSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in options)
                InkWell(
                  onTap: () => onSelected(o.key),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: selected == o.key
                          ? accent
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected == o.key
                            ? accent
                            : context.colors.border.withValues(alpha: 0.65),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (o.key != 'all') ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AdvancedAccountRow.brokerTint(
                                o.label,
                                accent,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          '${o.label} (${o.count})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected == o.key
                                ? const Color(0xFF1A1208)
                                : muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Displaying $displayingCount active accounts mapped',
          style: TextStyle(fontSize: 11, color: muted),
        ),
      ],
    );
  }
}
