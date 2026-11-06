import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_widget_id.dart';
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
          final mfRows = casMf.isNotEmpty ? casMf : directoryMf;
          final dematOnly = casDemat.isNotEmpty ? casDemat : directoryDemat;
          final portfolios = _filteredPortfolios(hub, familyMemberId);
          final valueBooks =
              personaBooks.where((p) => !p.isNps).toList();
          final isFamily = _primary == _UsersPrimaryTab.family;
          final isOverview = _primary == _UsersPrimaryTab.overview;
          final familyMembers = hub.familyMembers;
          final showCasCta = isOverview && !hasCas;

          final scopeTotal = _scopeTotalValue(
            demat: const [],
            brokers: valueBooks,
            nps: personaNps,
            allNps: familyMemberId == FavoritePersonaStore.kAll
                ? hub.npsAccounts
                : null,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CompactHeader(
                identity: hub.identity,
                nps: personaNps,
                onOpenUsers: widget.onOpenUsers,
              ),
              const SizedBox(height: 8),
              _CompactFilterRow(
                selected: _primary,
                onTabSelected: (tab) => setState(() {
                  _primary = tab;
                  _brokerFilter = 'all';
                }),
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
                householdTotalValue: hub.stats?.householdTotalValue,
                householdXirrPct: hub.stats?.householdXirrPct,
                primaryTotalValue: hub.stats?.primaryTotalValue,
                primaryXirrPct: hub.stats?.overallXirrPct,
                onSelected: (id) => _onFamilyMemberSelected(hub, id),
                onFavorite: _setFavorite,
                onDelete: (m) => _deleteFamilyMember(context, m),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isFamily) ...[
                        _FamilyTab(
                          members: familyMembers,
                          onAdd: () => _addFamilyMember(context),
                          onEdit: (m) => _editFamilyMember(context, m),
                          onDelete: (m) => _deleteFamilyMember(context, m),
                          onSelect: (id) => _onFamilyMemberSelected(hub, id),
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
                        if (hasNps && personaNps != null) ...[
                          _NpsStrip(
                            nps: personaNps,
                            currency: currency,
                            pctOfScope: _pctOfScope(
                              personaNps.totalValue,
                              scopeTotal,
                            ),
                          ),
                        ],
                        if (dematOnly.isNotEmpty) ...[
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
                                pctOfScope: _pctOfScope(
                                  a.holdingValue,
                                  scopeTotal,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (mfRows.isNotEmpty) ...[
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
                                pctOfScope: _pctOfScope(
                                  a.holdingValue,
                                  scopeTotal,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (portfolios.isNotEmpty) ...[
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
                                pctOfScope: _pctOfScope(p.current, scopeTotal),
                                onTap: () => _selectPortfolio(p),
                              ),
                            ),
                          ),
                        ],
                        if (dematOnly.isNotEmpty ||
                            mfRows.isNotEmpty ||
                            hasNps) ...[
                          const SizedBox(height: 8),
                          _NomineeSection(
                            accounts: [...dematOnly, ...mfRows],
                            nps: personaNps,
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
    this.identity,
    this.nps,
  });

  final AccountsIdentity? identity;
  final NpsMetaRow? nps;
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
  });

  final _UsersPrimaryTab selected;
  final ValueChanged<_UsersPrimaryTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final tabs = <(_UsersPrimaryTab, String)>[
      (_UsersPrimaryTab.overview, 'Overview'),
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
      ],
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
              child: FilledButton.tonal(
                onPressed: members.length >= 5 ? null : onAdd,
                child: Text(
                  members.length >= 5
                      ? 'Family limit reached (5)'
                      : 'Add family member',
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
            icon: const Icon(Icons.person_add_alt_1, size: 16),
            label: Text(
              members.length >= 5 ? 'Limit 5' : 'Add',
            ),
          ),
        ),
        for (final m in members)
          Material(
            type: MaterialType.transparency,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(m.name?.trim().isNotEmpty == true
                  ? m.name!.trim()
                  : 'Family member'),
              subtitle: Text(
                [
                  if (m.email != null && m.email!.isNotEmpty) m.email,
                  if (m.portfolioCount != null) '${m.portfolioCount} demat',
                  if (m.source != null) m.source,
                ].whereType<String>().join(' · '),
              ),
              trailing: Wrap(
                spacing: 0,
                children: [
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
              onTap: () => onSelect(m.id),
            ),
          ),
      ],
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({
    required this.row,
    required this.currency,
    required this.onTap,
    this.pctOfScope,
  });

  final AccountsPortfolioRow row;
  final NumberFormat currency;
  final VoidCallback onTap;
  final String? pctOfScope;

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
                if (pctOfScope != null) pctOfScope!,
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

class _NpsStrip extends StatelessWidget {
  const _NpsStrip({
    required this.nps,
    required this.currency,
    this.pctOfScope,
  });

  final NpsMetaRow nps;
  final NumberFormat currency;
  final String? pctOfScope;

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currency.format(total),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                      if (pctOfScope != null)
                        Text(
                          pctOfScope!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: muted,
                          ),
                        ),
                    ],
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
  const _DematDetailCard({
    required this.account,
    required this.currency,
    this.pctOfScope,
  });

  final DematAccountRow account;
  final NumberFormat currency;
  final String? pctOfScope;

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
                  [
                    currency.format(account.holdingValue),
                    if (pctOfScope != null) pctOfScope!,
                  ].join(' · '),
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
  const _FolioDetailCard({
    required this.account,
    required this.currency,
    this.pctOfScope,
  });

  final DematAccountRow account;
  final NumberFormat currency;
  final String? pctOfScope;

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
                  [
                    currency.format(account.holdingValue),
                    if (pctOfScope != null) pctOfScope!,
                  ].join(' · '),
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
