import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_widget_id.dart';
import 'package:am_dashboard_ui/presentation/mappers/advanced_account_row_mapper.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_overlay_provider.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_portfolio_scope.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/glass_card.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/persona_card_strip.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Users peer panel: identity, Overview|Family tabs, persona cards synced with toolbar.
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

enum _UsersPrimaryTab { overview, family }

class _DashboardUsersHubWidgetState
    extends ConsumerState<DashboardUsersHubWidget> {
  _UsersPrimaryTab _primary = _UsersPrimaryTab.overview;

  /// Secondary broker filter inside Overview (`all` or broker key).
  String _brokerFilter = 'all';

  String? _favoriteKey;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final key = await FavoritePersonaStore.instance.load(widget.userId);
    if (!mounted) return;
    setState(() => _favoriteKey = key);
  }

  Future<void> _setFavorite(String personaKey) async {
    await FavoritePersonaStore.instance.save(widget.userId, personaKey);
    if (!mounted) return;
    setState(() => _favoriteKey = personaKey);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(accountsHubProvider(widget.userId));
    final filterKey = ref.watch(familyPortfolioFilterProvider);
    final familyMemberId = FavoritePersonaStore.selectionFromKey(filterKey);
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
          final personaDemat =
              _filteredDematByFamily(hub.dematAccounts, familyMemberId);
          final personaBooks = hub.portfolios
              .where((p) => _matchesPersona(p.familyMemberId, familyMemberId))
              .toList();
          final casDemat = personaBooks
              .where((p) => p.isDematBook)
              .map(_bookAsAccount)
              .toList();
          final casMf = personaBooks
              .where((p) => p.isMutualFundBook)
              .map(_bookAsAccount)
              .toList();
          final hasCas = personaDemat.isNotEmpty ||
              casDemat.isNotEmpty ||
              casMf.isNotEmpty;
          final personaNps = _npsForFamily(hub, familyMemberId);
          final hasNps =
              personaNps?.pran != null && personaNps!.pran!.isNotEmpty;
          final demat = _filteredByBroker(personaDemat);
          final directoryMf = demat
              .where((a) => (a.accountType ?? '').toLowerCase() == 'mf')
              .toList();
          final directoryDemat = demat
              .where((a) => (a.accountType ?? '').toLowerCase() != 'mf')
              .toList();
          // Prefer CAS directory for Demat/MF lists (full account rows).
          final mfRows = directoryMf.isNotEmpty ? directoryMf : casMf;
          final dematOnly =
              directoryDemat.isNotEmpty ? directoryDemat : casDemat;
          final portfolios = _filteredPortfolios(hub, familyMemberId);
          final valueBooks =
              personaBooks.where((p) => !p.isNps).toList();
          final isFamily = _primary == _UsersPrimaryTab.family;
          final isOverview = _primary == _UsersPrimaryTab.overview;
          final familyMembers = hub.familyMembers;
          final showCasCta = isOverview && !hasCas;

          final scopeTotal = _scopeTotalValue(
            demat: [...dematOnly, ...mfRows],
            brokers: valueBooks,
            nps: personaNps,
            allNps: familyMemberId == FavoritePersonaStore.kAll
                ? hub.npsAccounts
                : null,
          );

          final householdAccountCount = valuedAccountCountForPersona(
            hub: hub,
            familyMemberId: FavoritePersonaStore.kAll,
          );
          final primaryAccountCount = valuedAccountCountForPersona(
            hub: hub,
            familyMemberId: null,
          );
          final memberAccountCounts = <String, int>{
            for (final m in familyMembers)
              if (m.id != null && m.id!.trim().isNotEmpty)
                m.id!: valuedAccountCountForPersona(
                  hub: hub,
                  familyMemberId: m.id,
                ),
          };

          final mappedItems = _buildMappedItems(
            dematOnly: dematOnly,
            mfRows: mfRows,
            portfolios: portfolios,
            personaNps: hasNps ? personaNps : null,
            currency: currency,
            scopeTotal: scopeTotal,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CompactHeader(
                identity: hub.identity,
                nps: personaNps,
                onOpenUsers: widget.onOpenUsers,
                tabs: _CompactFilterRow(
                  selected: _primary,
                  onTabSelected: (tab) => setState(() {
                    _primary = tab;
                    _brokerFilter = 'all';
                  }),
                ),
              ),
              const SizedBox(height: 8),
              PersonaCardStrip(
                members: familyMembers,
                selectedId: familyMemberId,
                primaryLabel: hub.identity?.name?.trim().isNotEmpty == true
                    ? hub.identity!.name!.trim()
                    : 'You',
                favoriteKey: _favoriteKey,
                compact: true,
                showRoleIcon: false,
                sizeToContent: true,
                householdTotalValue: hub.stats?.householdTotalValue,
                householdXirrPct: hub.stats?.householdXirrPct,
                householdAccountCount: householdAccountCount,
                primaryTotalValue: hub.stats?.primaryTotalValue,
                primaryXirrPct: hub.stats?.overallXirrPct,
                primaryAccountCount: primaryAccountCount,
                memberAccountCounts: memberAccountCounts,
                onSelected: (id) => _onFamilyMemberSelected(hub, id),
                onFavorite: _setFavorite,
                onDelete: (m) => _deleteFamilyMember(context, m),
                onAddFamily: () => _addFamilyMember(context),
              ),
              const SizedBox(height: 8),
              if (isFamily)
                Expanded(
                  child: SingleChildScrollView(
                    child: _FamilyTab(
                      members: familyMembers,
                      onAdd: () => _addFamilyMember(context),
                      onEdit: (m) => _editFamilyMember(context, m),
                      onDelete: (m) => _deleteFamilyMember(context, m),
                      onSelect: (id) {
                        _onFamilyMemberSelected(hub, id);
                        setState(() => _primary = _UsersPrimaryTab.overview);
                      },
                    ),
                  ),
                )
              else ...[
                if (showCasCta && widget.onOpenDocIntel != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: widget.onOpenDocIntel,
                      child: const Text('Import CDSL CAS via Doc Intel'),
                    ),
                  ),
                _MappedAccountsHeader(count: mappedItems.length),
                const SizedBox(height: 8),
                Expanded(
                  child: mappedItems.isEmpty
                      ? Center(
                          child: Text(
                            'No mapped accounts',
                            style: context.text.caption().copyWith(
                                  color: context.colors.textSecondary,
                                ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: mappedItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final item = mappedItems[i];
                            return _MappedAccountCard(
                              item: item,
                              onTap: () {
                                if (item.kind == _MappedKind.broker &&
                                    item.portfolio != null) {
                                  _selectPortfolio(item.portfolio!);
                                } else {
                                  widget.onOpenUsers?.call();
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  List<_MappedItem> _buildMappedItems({
    required List<DematAccountRow> dematOnly,
    required List<DematAccountRow> mfRows,
    required List<AccountsPortfolioRow> portfolios,
    required NpsMetaRow? personaNps,
    required NumberFormat currency,
    required double scopeTotal,
  }) {
    final items = <_MappedItem>[
      if (personaNps != null)
        _MappedItem(
          kind: _MappedKind.nps,
          title: 'NPS',
          typeLabel: 'NPS',
          meta: [
            if (personaNps.pran != null && personaNps.pran!.isNotEmpty)
              'PRAN ${personaNps.pran}',
          ].join(' · '),
          status: 'Active',
          valueLabel: personaNps.totalValue != null
              ? currency.format(personaNps.totalValue)
              : '—',
          weightLabel: _pctOfScope(personaNps.totalValue, scopeTotal),
          letter: 'N',
          tintSeed: 'nps',
          searchBlob: 'nps ${personaNps.pran ?? ''}',
        ),
      for (final a in dematOnly)
        _MappedItem(
          kind: _MappedKind.demat,
          title: a.dpName ?? a.boid ?? a.accountNo,
          typeLabel: 'Demat',
          meta: [
            if (a.boid != null && a.boid!.isNotEmpty) 'BOID ${a.boid}',
            if (a.clientId != null && a.clientId!.isNotEmpty)
              'Client ${a.clientId}',
            if (a.dpId != null && a.dpId!.isNotEmpty) 'DP ${a.dpId}',
          ].join(' · '),
          status: a.status?.trim().isNotEmpty == true ? a.status!.trim() : 'Active',
          valueLabel: a.holdingValue != null
              ? currency.format(a.holdingValue)
              : '—',
          weightLabel: _pctOfScope(a.holdingValue, scopeTotal),
          letter: _letterOf(a.dpName ?? a.mappedBroker ?? a.accountNo),
          tintSeed: a.mappedBroker ?? a.dpName ?? a.accountNo,
          searchBlob:
              '${a.dpName} ${a.boid} ${a.clientId} ${a.dpId} ${a.mappedBroker} demat',
        ),
      for (final a in mfRows)
        _MappedItem(
          kind: _MappedKind.mf,
          title: a.folio?.trim().isNotEmpty == true
              ? 'Folio ${a.folio}'
              : (a.amcName ?? a.accountNo),
          typeLabel: 'Mutual Fund',
          meta: [
            if (a.amcName != null && a.amcName!.isNotEmpty) a.amcName!,
            if (a.mappedBroker != null) a.mappedBroker!,
          ].join(' · '),
          status: a.status?.trim().isNotEmpty == true ? a.status!.trim() : 'Active',
          valueLabel: a.holdingValue != null
              ? currency.format(a.holdingValue)
              : '—',
          weightLabel: _pctOfScope(a.holdingValue, scopeTotal),
          letter: _letterOf(a.amcName ?? a.folio ?? 'M'),
          tintSeed: a.amcName ?? a.folio ?? 'mf',
          searchBlob: '${a.folio} ${a.amcName} ${a.mappedBroker} mf mutual',
        ),
      for (final p in portfolios)
        _MappedItem(
          kind: _MappedKind.broker,
          title: p.displayName?.trim().isNotEmpty == true
              ? p.displayName!.trim()
              : (p.brokerType ?? p.portfolioId ?? 'Broker'),
          typeLabel: 'Broker',
          meta: [
            if (p.brokerType != null && p.brokerType!.isNotEmpty) p.brokerType!,
            if (p.dematBoid != null && p.dematBoid!.isNotEmpty)
              'BOID ${p.dematBoid}',
          ].join(' · '),
          status: 'Active',
          valueLabel: p.current != null ? currency.format(p.current) : '—',
          weightLabel: _pctOfScope(p.current, scopeTotal),
          letter: _letterOf(p.displayName ?? p.brokerType ?? 'B'),
          tintSeed: p.brokerType ?? p.displayName ?? 'broker',
          searchBlob:
              '${p.displayName} ${p.brokerType} ${p.dematBoid} ${p.portfolioId} broker',
          portfolio: p,
        ),
    ];
    return items;
  }

  String _letterOf(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '?';
    return t[0].toUpperCase();
  }

  Future<(String, String?)?> _promptFamilyFields(
    BuildContext context, {
    String title = 'Add family member',
    String? initialName,
    String? initialEmail,
  }) async {
    final nameCtrl = TextEditingController(text: initialName ?? '');
    final emailCtrl = TextEditingController(text: initialEmail ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
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
              decoration: const InputDecoration(labelText: 'Email (optional)'),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    nameCtrl.dispose();
    emailCtrl.dispose();
    if (saved != true || name.isEmpty) return null;
    return (name, email.isEmpty ? null : email);
  }

  Future<void> _addFamilyMember(BuildContext context) async {
    final hub = ref.read(accountsHubProvider(widget.userId)).asData?.value;
    if (hub != null && hub.familyMembers.length >= 5) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum of 5 family members allowed')),
        );
      }
      return;
    }
    final result = await _promptFamilyFields(context);
    if (result == null || !context.mounted) return;
    try {
      final client = await ref.read(portfolioApiClientProvider.future);
      await createFamilyMember(
        client: client,
        displayName: result.$1,
        email: result.$2,
      );
      ref.invalidate(accountsHubProvider(widget.userId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Family member added')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add: $e')),
        );
      }
    }
  }

  Future<void> _editFamilyMember(
    BuildContext context,
    FamilyMemberRow member,
  ) async {
    final id = member.id?.trim();
    if (id == null || id.isEmpty) return;
    final result = await _promptFamilyFields(
      context,
      title: 'Edit family member',
      initialName: member.name,
      initialEmail: member.email,
    );
    if (result == null || !context.mounted) return;
    try {
      final client = await ref.read(portfolioApiClientProvider.future);
      await updateFamilyMember(
        client: client,
        familyMemberId: id,
        displayName: result.$1,
        email: result.$2 ?? '',
      );
      ref.invalidate(accountsHubProvider(widget.userId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Family member updated')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update: $e')),
        );
      }
    }
  }

  Future<void> _deleteFamilyMember(
    BuildContext context,
    FamilyMemberRow member,
  ) async {
    final id = member.id?.trim();
    if (id == null || id.isEmpty) return;
    final name = member.name?.trim().isNotEmpty == true
        ? member.name!.trim()
        : 'this family member';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete family member?'),
        content: Text(
          'Removes $name, their linked broker portfolios, and CAS/NPS imports for that persona.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final client = await ref.read(portfolioApiClientProvider.future);
      await deleteFamilyMember(client: client, familyMemberId: id);
      if (FavoritePersonaStore.selectionFromKey(
            ref.read(familyPortfolioFilterProvider),
          ) ==
          id) {
        ref
            .read(familyPortfolioFilterProvider.notifier)
            .select(FavoritePersonaStore.kYou);
      }
      if (_favoriteKey == id) {
        await FavoritePersonaStore.instance.clear(widget.userId);
        if (mounted) setState(() => _favoriteKey = null);
      }
      ref.invalidate(accountsHubProvider(widget.userId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Family member deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete: $e')),
        );
      }
    }
  }

  DematAccountRow _bookAsAccount(AccountsPortfolioRow p) {
    return DematAccountRow(
      accountNo: p.portfolioId ?? p.displayName ?? 'cas',
      accountType: p.isMutualFundBook ? 'mf' : 'demat',
      dpName: p.displayName,
      holdingValue: p.current,
      boid: p.dematBoid,
      familyMemberId: p.familyMemberId,
      portfolioId: p.portfolioId,
      status: 'Active',
    );
  }

  bool _matchesPersona(String? rowFamilyId, String? familyMemberId) {
    if (familyMemberId == FavoritePersonaStore.kAll) return true;
    final primary = rowFamilyId == null || rowFamilyId.trim().isEmpty;
    if (familyMemberId == null) return primary;
    return rowFamilyId == familyMemberId;
  }

  List<DematAccountRow> _filteredDematByFamily(
    List<DematAccountRow> all,
    String? familyMemberId,
  ) {
    return all
        .where((a) => _matchesPersona(a.familyMemberId, familyMemberId))
        .toList();
  }

  NpsMetaRow? _npsForFamily(AccountsHub hub, String? familyMemberId) {
    final list = hub.npsAccounts;
    if (familyMemberId == FavoritePersonaStore.kAll) {
      // Prefer primary strip; household % uses allNps sum separately.
      for (final n in list) {
        if (n.familyMemberId == null || n.familyMemberId!.trim().isEmpty) {
          return n;
        }
      }
      return hub.nps ?? (list.isNotEmpty ? list.first : null);
    }
    if (familyMemberId == null) {
      for (final n in list) {
        if (n.familyMemberId == null || n.familyMemberId!.trim().isEmpty) {
          return n;
        }
      }
      return hub.nps;
    }
    for (final n in list) {
      if (n.familyMemberId == familyMemberId) return n;
    }
    return null;
  }

  List<DematAccountRow> _filteredByBroker(List<DematAccountRow> all) {
    if (_brokerFilter == 'all') return all;
    return all.where((a) {
      final mapped = (a.mappedBroker ?? '').toUpperCase();
      return mapped == _brokerFilter;
    }).toList();
  }

  List<AccountsPortfolioRow> _filteredPortfolios(
    AccountsHub hub,
    String? familyMemberId,
  ) {
    var rows = hub.portfolios
        .where(
          (p) =>
              p.isRunningBroker &&
              _matchesPersona(p.familyMemberId, familyMemberId),
        )
        .toList();
    if (_brokerFilter == 'all') return rows;
    return rows.where((p) {
      final key = (p.brokerType ?? p.displayName ?? '').trim().toUpperCase();
      return key == _brokerFilter;
    }).toList();
  }

  double _scopeTotalValue({
    required List<DematAccountRow> demat,
    required List<AccountsPortfolioRow> brokers,
    NpsMetaRow? nps,
    List<NpsMetaRow>? allNps,
  }) {
    var sum = 0.0;
    for (final a in demat) {
      final v = a.holdingValue;
      if (v != null && v > 0) sum += v;
    }
    for (final p in brokers) {
      final v = p.current;
      if (v != null && v > 0) sum += v;
    }
    if (allNps != null) {
      for (final n in allNps) {
        final v = n.totalValue;
        if (v != null && v > 0) sum += v;
      }
    } else if (nps?.totalValue != null && nps!.totalValue! > 0) {
      sum += nps.totalValue!;
    }
    return sum;
  }

  String? _pctOfScope(double? value, double scopeTotal) {
    if (value == null || scopeTotal <= 0) return null;
    final pct = (value / scopeTotal) * 100.0;
    final label = pct >= 10 ? pct.toStringAsFixed(0) : pct.toStringAsFixed(1);
    return '$label%';
  }

  void _onFamilyMemberSelected(AccountsHub hub, String? memberId) {
    final key = FavoritePersonaStore.keyFromSelection(memberId);
    ref.read(familyPortfolioFilterProvider.notifier).select(key);
    setState(() => _brokerFilter = 'all');
    final rows = hub.portfolios.where((p) {
      if (!p.isRunningBroker) return false;
      if (memberId == FavoritePersonaStore.kAll) return true;
      if (memberId == null) {
        return p.familyMemberId == null || p.familyMemberId!.trim().isEmpty;
      }
      return p.familyMemberId == memberId;
    }).toList();
    if (rows.isEmpty) return;
    final first = rows.first;
    final id = first.portfolioId;
    if (id == null || id.isEmpty) return;
    final label = first.displayName?.trim().isNotEmpty == true
        ? first.displayName!.trim()
        : (first.brokerType ?? id);
    _scopePortfolio(id, label);
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
    required this.tabs,
    this.identity,
    this.nps,
  });

  final AccountsIdentity? identity;
  final NpsMetaRow? nps;
  final VoidCallback? onOpenUsers;
  final Widget tabs;

  @override
  Widget build(BuildContext context) {
    final rawName = identity?.name ?? nps?.subscriberName;
    final name = () {
      final n = rawName?.trim() ?? '';
      if (n.isEmpty) return '—';
      if (!n.contains(' ') && n.length <= 12) return n.toUpperCase();
      return n;
    }();
    final accent = ModuleColors.dashboard;

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
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.body().copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: tabs,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactFilterRow extends StatelessWidget {
  const _CompactFilterRow({
    required this.selected,
    required this.onTabSelected,
  });

  final _UsersPrimaryTab selected;
  final ValueChanged<_UsersPrimaryTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.dashboard;
    final tabs = <(_UsersPrimaryTab, String, IconData)>[
      (_UsersPrimaryTab.overview, 'Overview', Icons.bar_chart_rounded),
      (_UsersPrimaryTab.family, 'Family', Icons.groups_rounded),
    ];
    return Row(
      children: [
        for (final t in tabs) ...[
          if (t.$1 != tabs.first.$1) const SizedBox(width: 8),
          _TabPill(
            label: t.$2,
            icon: t.$3,
            selected: selected == t.$1,
            accent: accent,
            onTap: () => onTabSelected(t.$1),
          ),
        ],
      ],
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? const Color(0xFF1A1208) : Colors.white;
    return Material(
      color: selected ? accent : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? accent
                  : Colors.white.withValues(alpha: 0.7),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilyTab extends StatelessWidget {
  const _FamilyTab({
    required this.members,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onSelect,
  });

  final List<FamilyMemberRow> members;
  final VoidCallback onAdd;
  final ValueChanged<FamilyMemberRow> onEdit;
  final ValueChanged<FamilyMemberRow> onDelete;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.dashboard;
    if (members.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border:
              Border.all(color: context.colors.border.withValues(alpha: 0.4)),
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
              'Add manually or import a CDSL/NPS statement whose holder differs from your profile.',
              style: context.text.caption().copyWith(
                    color: context.colors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: accent),
                onPressed: members.length >= 5 ? null : onAdd,
                child: Text(
                  members.length >= 5
                      ? 'Family limit reached (5)'
                      : 'Add family member',
                  style: const TextStyle(
                    color: Color(0xFF1A1208),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: members.length >= 5 ? null : onAdd,
            icon: Icon(Icons.person_add_alt_1, size: 16, color: accent),
            label: Text(
              members.length >= 5 ? 'Limit 5' : 'Add',
              style: TextStyle(color: accent, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        for (final m in members)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: InkWell(
                onTap: () => onSelect(m.id),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(
                      color: context.colors.border.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name?.trim().isNotEmpty == true
                                  ? m.name!.trim()
                                  : 'Family member',
                              style: context.text.label().copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                            ),
                            Text(
                              [
                                if (m.email != null && m.email!.isNotEmpty)
                                  m.email,
                                if (m.portfolioCount != null)
                                  '${m.portfolioCount} demat',
                                if (m.source != null) m.source,
                              ].whereType<String>().join(' · '),
                              style: context.text.caption().copyWith(
                                    fontSize: 10,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => onEdit(m),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => onDelete(m),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

enum _MappedKind { broker, demat, mf, nps }

class _MappedItem {
  const _MappedItem({
    required this.kind,
    required this.title,
    required this.typeLabel,
    required this.meta,
    required this.status,
    required this.valueLabel,
    required this.letter,
    required this.tintSeed,
    required this.searchBlob,
    this.weightLabel,
    this.portfolio,
  });

  final _MappedKind kind;
  final String title;
  final String typeLabel;
  final String meta;
  final String status;
  final String valueLabel;
  final String? weightLabel;
  final String letter;
  final String tintSeed;
  final String searchBlob;
  final AccountsPortfolioRow? portfolio;
}

class _MappedAccountsHeader extends StatelessWidget {
  const _MappedAccountsHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.dashboard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 16, color: accent.withValues(alpha: 0.45)),
        Row(
          children: [
            Icon(Icons.layers_rounded, size: 14, color: accent),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Mapped Accounts ($count)',
                style: context.text.label().copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: accent,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MappedAccountCard extends StatelessWidget {
  const _MappedAccountCard({
    required this.item,
    required this.onTap,
  });

  final _MappedItem item;
  final VoidCallback onTap;

  Color _tint(BuildContext context) {
    final seed = item.tintSeed.toUpperCase();
    if (seed.contains('GROWW')) return context.colors.statusSuccess;
    if (seed.contains('ZERODHA')) return context.colors.statusError;
    if (seed.contains('ANGEL')) return ModuleColors.dashboard;
    if (item.kind == _MappedKind.nps) return ModuleColors.dashboard;
    final hash = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    final palette = [
      context.colors.statusSuccess,
      context.colors.statusError,
      ModuleColors.dashboard,
      context.colors.statusWarning,
    ];
    return palette[hash % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.dashboard;
    final tint = _tint(context);
    final muted = context.colors.textSecondary;
    final active = item.status.toLowerCase().contains('active');

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(
              color: context.colors.border.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: tint.withValues(alpha: 0.14),
                blurRadius: 12,
                offset: const Offset(6, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: tint.withValues(alpha: 0.25),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  item.letter,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: tint,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.55),
                        ),
                        color: accent.withValues(alpha: 0.1),
                      ),
                      child: Text(
                        item.typeLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.label().copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                    ),
                    if (item.meta.isNotEmpty)
                      Text(
                        item.meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.caption().copyWith(
                              fontSize: 10,
                              color: muted,
                            ),
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active
                                ? context.colors.statusSuccess
                                : muted,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          item.status,
                          style: context.text.caption().copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? context.colors.statusSuccess
                                    : muted,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 42,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: context.colors.border.withValues(alpha: 0.55),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.valueLabel,
                    style: context.text.label().copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                  ),
                  if (item.weightLabel != null)
                    Text(
                      item.weightLabel!,
                      style: context.text.caption().copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: context.colors.statusSuccess,
                          ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
