import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';
import 'package:am_dashboard_ui/presentation/mappers/advanced_account_row_mapper.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/glass_card.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/persona_card_strip.dart';
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
  /// null = You; [FavoritePersonaStore.kAll] = household; otherwise soft family member id.
  String? _familyMemberId;
  String? _favoriteKey;
  bool _favoriteApplied = false;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final key = await FavoritePersonaStore.instance.load(widget.userId);
    if (!mounted) return;
    setState(() {
      _favoriteKey = key;
      if (!_favoriteApplied && key != null) {
        _familyMemberId = FavoritePersonaStore.selectionFromKey(key);
        _favoriteApplied = true;
        ref.read(familyPortfolioFilterProvider.notifier).state =
            FavoritePersonaStore.keyFromSelection(_familyMemberId);
      }
    });
  }

  double? _selectedXirrPct(AccountsHub hub) {
    if (_familyMemberId == FavoritePersonaStore.kAll) {
      return hub.stats?.householdXirrPct;
    }
    if (_familyMemberId == null) return hub.stats?.overallXirrPct;
    for (final m in hub.familyMembers) {
      if (m.id == _familyMemberId) return m.xirrPct;
    }
    return null;
  }

  Future<void> _setFavorite(String personaKey) async {
    await FavoritePersonaStore.instance.save(widget.userId, personaKey);
    if (!mounted) return;
    setState(() => _favoriteKey = personaKey);
  }

  Future<void> _selectPersona(String? id) async {
    setState(() => _familyMemberId = id);
    ref.read(familyPortfolioFilterProvider.notifier).state =
        FavoritePersonaStore.keyFromSelection(id);
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

  List<DematAccountRow> _liftDirectoryValues(
    List<DematAccountRow> directory,
    List<AccountsPortfolioRow> books,
  ) {
    return directory.map((a) {
      final dirVal = a.holdingValue ?? 0.0;
      double bookVal = 0.0;
      final boid = (a.boid ?? a.accountNo ?? '').trim();
      final name = (a.dpName ?? '').trim().toLowerCase();
      for (final b in books) {
        final bb = (b.dematBoid ?? '').trim();
        final bn = (b.displayName ?? '').trim().toLowerCase();
        final matchBoid = boid.isNotEmpty && bb.isNotEmpty && boid == bb;
        final matchName = name.isNotEmpty && bn.isNotEmpty && name == bn;
        if (!matchBoid && !matchName) continue;
        final cur = b.current ?? 0.0;
        if (cur > bookVal) bookVal = cur;
      }
      final lifted = dirVal > bookVal ? dirVal : bookVal;
      if (lifted == dirVal) return a;
      return DematAccountRow(
        accountNo: a.accountNo,
        accountType: a.accountType,
        status: a.status,
        email: a.email,
        mobile: a.mobile,
        holderName: a.holderName,
        dpId: a.dpId,
        clientId: a.clientId,
        boid: a.boid,
        dpName: a.dpName,
        nominee: a.nominee,
        nomineeRegistered: a.nomineeRegistered,
        frozenStatus: a.frozenStatus,
        holdingValue: lifted,
        mappedBroker: a.mappedBroker,
        amcName: a.amcName,
        folio: a.folio,
        active: a.active,
        portfolioId: a.portfolioId,
        familyMemberId: a.familyMemberId,
      );
    }).toList();
  }

  bool _matchesPersona(String? rowFamilyId) {
    if (_familyMemberId == FavoritePersonaStore.kAll) return true;
    final primary = rowFamilyId == null || rowFamilyId.trim().isEmpty;
    if (_familyMemberId == null) return primary;
    return rowFamilyId == _familyMemberId;
  }

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
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
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

    final personaDemat = hub.dematAccounts
        .where((a) => _matchesPersona(a.familyMemberId))
        .toList();
    final personaBooks = hub.portfolios
        .where((p) => _matchesPersona(p.familyMemberId))
        .toList();
    final runningBrokersOnly =
        personaBooks.where((p) => p.isRunningBroker).toList();
    final mfBooks = personaBooks.where((p) => p.isMutualFundBook).toList();
    final dematBooks = personaBooks.where((p) => p.isDematBook).toList();
    final directoryDemat = personaDemat
        .where((a) => (a.accountType ?? '').toLowerCase() != 'mf')
        .toList();
    final directoryMf = personaDemat
        .where((a) => (a.accountType ?? '').toLowerCase() == 'mf')
        .toList();
    // Demat/MF tabs must stay on the CAS directory (full account list).
    // CAS_DEMAT books only fill in when the directory is empty for that persona.
    // Row value = max(directory, matched book) so empty books do not understate.
    final demat = directoryDemat.isNotEmpty
        ? _liftDirectoryValues(directoryDemat, dematBooks)
        : dematBooks.map(_bookAsAccount).toList();
    final mf = directoryMf.isNotEmpty
        ? _liftDirectoryValues(directoryMf, mfBooks)
        : mfBooks.map(_bookAsAccount).toList();
    // Broker tab: live books union valued first-class CAS directory rows.
    final runningBrokers = runningBrokersUnionDirectory(
      runningBrokers: runningBrokersOnly,
      directoryDemat: directoryDemat,
    );
    NpsMetaRow? personaNps;
    if (_familyMemberId == FavoritePersonaStore.kAll) {
      for (final n in hub.npsAccounts) {
        if (n.familyMemberId == null || n.familyMemberId!.trim().isEmpty) {
          personaNps = n;
          break;
        }
      }
      personaNps ??= hub.nps ??
          (hub.npsAccounts.isNotEmpty ? hub.npsAccounts.first : null);
    } else if (_familyMemberId == null) {
      for (final n in hub.npsAccounts) {
        if (n.familyMemberId == null || n.familyMemberId!.trim().isEmpty) {
          personaNps = n;
          break;
        }
      }
      personaNps ??= hub.nps;
    } else {
      for (final n in hub.npsAccounts) {
        if (n.familyMemberId == _familyMemberId) {
          personaNps = n;
          break;
        }
      }
    }
    final hasNps =
        personaNps?.pran != null && personaNps!.pran!.isNotEmpty;
    String? npsPortfolioId;
    for (final p in hub.portfolios) {
      final id = p.portfolioId;
      if (!p.isNps || id == null || id.isEmpty) continue;
      if (!_matchesPersona(p.familyMemberId)) continue;
      npsPortfolioId = id;
      break;
    }

    // Prefer server persona total (books + directory residual) for weights.
    final scopeTotal = () {
      if (_familyMemberId == FavoritePersonaStore.kAll) {
        return hub.stats?.householdTotalValue ?? 0.0;
      }
      if (_familyMemberId != null) {
        for (final m in hub.familyMembers) {
          if (m.id == _familyMemberId && m.totalValue != null) {
            return m.totalValue!;
          }
        }
      }
      return hub.stats?.primaryTotalValue ?? 0.0;
    }();

    final allRows = mapAccountsHubToAdvancedRows(
      brokers: runningBrokers,
      mf: mf,
      demat: demat,
      hub: hub,
      hasNps: hasNps,
      nps: personaNps,
      scopeTotalValue: scopeTotal,
      includeFamilySummaries: _tab == _UsersPageTab.family,
    );
    final tabKey = switch (_tab) {
      _UsersPageTab.overview => 'overview',
      _UsersPageTab.brokers => 'brokers',
      _UsersPageTab.mf => 'mf',
      _UsersPageTab.demat => 'demat',
      _UsersPageTab.nps => 'nps',
      _UsersPageTab.family => 'family',
    };
    final rows = filterAdvancedAccountRowsByTab(rows: allRows, tab: tabKey);
    final selectedXirr = _selectedXirrPct(hub);
    final activeAccountCount = valuedAccountCountForPersona(
      hub: hub,
      familyMemberId: _familyMemberId,
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
      for (final m in hub.familyMembers)
        if (m.id != null && m.id!.trim().isNotEmpty)
          m.id!: valuedAccountCountForPersona(
            hub: hub,
            familyMemberId: m.id,
          ),
    };

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
                name: () {
                  if (_familyMemberId == FavoritePersonaStore.kAll) {
                    return 'Household';
                  }
                  if (_familyMemberId == null) return name;
                  for (final m in hub.familyMembers) {
                    if (m.id == _familyMemberId &&
                        m.name != null &&
                        m.name!.trim().isNotEmpty) {
                      return m.name!.trim();
                    }
                  }
                  return name;
                }(),
                pran: _familyMemberId == null ||
                        _familyMemberId == FavoritePersonaStore.kAll
                    ? pran
                    : personaNps?.pran,
                registrationDate: personaNps?.registrationDate,
                nomineeDetails: null,
                hasLinked: hasLinked,
                familySharePct: null,
                showKpis: false,
                kpis: const [],
                totalValue: scopeTotal,
                xirrPct: selectedXirr,
                activeAccountCount: activeAccountCount,
              ),
              const SizedBox(height: 10),
              Builder(
                builder: (context) {
                  final compact = MediaQuery.sizeOf(context).width < 720;
                  final primaryLabel =
                      hub.identity?.name?.trim().isNotEmpty == true
                          ? hub.identity!.name!.trim()
                          : 'You';
                  final selectedKey =
                      FavoritePersonaStore.keyFromSelection(_familyMemberId);
                  if (compact) {
                    return _MobilePersonaBar(
                      selectedKey: selectedKey,
                      primaryLabel: primaryLabel,
                      members: [
                        for (final m in hub.familyMembers)
                          if (m.id != null && m.id!.trim().isNotEmpty)
                            (
                              id: m.id!,
                              name: m.name?.trim().isNotEmpty == true
                                  ? m.name!.trim()
                                  : 'Family member',
                            ),
                      ],
                      favoriteKey: _favoriteKey,
                      onSelected: (key) => _selectPersona(
                        FavoritePersonaStore.selectionFromKey(key),
                      ),
                      onFavorite: () => _setFavorite(selectedKey),
                      selectedTab: _tab,
                      tabLabelFor: (t) => _tabLabel(
                        t,
                        runningBrokers,
                        mf,
                        demat,
                        hasNps,
                        hub.familyMembers.length,
                      ),
                      onTabSelected: (t) => setState(() => _tab = t),
                    );
                  }
                  return PersonaCardStrip(
                    members: hub.familyMembers,
                    selectedId: _familyMemberId,
                    primaryLabel: primaryLabel,
                    favoriteKey: _favoriteKey,
                    householdTotalValue: hub.stats?.householdTotalValue,
                    householdXirrPct: hub.stats?.householdXirrPct,
                    householdAccountCount: householdAccountCount,
                    primaryTotalValue: hub.stats?.primaryTotalValue,
                    primaryXirrPct: hub.stats?.overallXirrPct,
                    primaryAccountCount: primaryAccountCount,
                    memberAccountCounts: memberAccountCounts,
                    onSelected: _selectPersona,
                    onFavorite: _setFavorite,
                    onDelete: (m) => _deleteFamilyFromCard(context, m),
                    onAddFamily: () => _addFamilyFromCard(context),
                  );
                },
              ),
              if ((_tab == _UsersPageTab.demat || _tab == _UsersPageTab.mf) &&
                  personaDemat.isEmpty) ...[
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
                child: _tab == _UsersPageTab.family
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (MediaQuery.sizeOf(context).width >= 720)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                              child: _CategoryTabs(
                                selected: _tab,
                                labelFor: (t) => _tabLabel(
                                  t,
                                  runningBrokers,
                                  mf,
                                  demat,
                                  hasNps,
                                  hub.familyMembers.length,
                                ),
                                onSelected: (t) => setState(() => _tab = t),
                              ),
                            ),
                          Expanded(
                            child: _UsersFamilyPanel(
                              userId: widget.userId,
                              members: hub.familyMembers,
                              books: hub.portfolios,
                            ),
                          ),
                        ],
                      )
                    : Builder(
                        builder: (context) {
                          final compact =
                              MediaQuery.sizeOf(context).width < 720;
                          return AdvancedAccountsTemplate(
                            accounts: rows,
                            isLoading: false,
                            accentColor: ModuleColors.dashboard,
                            initialViewMode: compact ? 'card' : 'table',
                            allowViewModeToggle: !compact,
                            toolbarLeading: compact
                                ? null
                                : _CategoryTabs(
                                    selected: _tab,
                                    labelFor: (t) => _tabLabel(
                                      t,
                                      runningBrokers,
                                      mf,
                                      demat,
                                      hasNps,
                                      hub.familyMembers.length,
                                    ),
                                    onSelected: (t) => setState(() => _tab = t),
                                  ),
                            footerNoun: _footerNoun(_tab),
                            footerCenterNote:
                                (_tab == _UsersPageTab.demat ||
                                            _tab == _UsersPageTab.mf) &&
                                        hasCasDirectory
                                    ? 'All CDSL accounts verified via OTP'
                                    : null,
                            onRefresh: () => ref.invalidate(
                              accountsHubProvider(widget.userId),
                            ),
                            emptyTitle: 'No rows for this view',
                            emptySubtitle:
                                'Switch filters or import CDSL CAS',
                          );
                        },
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

  String _tabLabel(
    _UsersPageTab t,
    List<AccountsPortfolioRow> brokers,
    List<DematAccountRow> mf,
    List<DematAccountRow> demat,
    bool hasNps, [
    int familyCount = 0,
  ]) {
    return switch (t) {
      _UsersPageTab.overview => 'Overview',
      _UsersPageTab.brokers => 'Broker (${brokers.length})',
      _UsersPageTab.mf => 'Mutual Fund (${mf.length})',
      _UsersPageTab.demat => 'Demat (${demat.length})',
      _UsersPageTab.nps => hasNps ? 'NPS (1)' : 'NPS (0)',
      _UsersPageTab.family => 'Family ($familyCount)',
    };
  }

  String _footerNoun(_UsersPageTab t) => switch (t) {
        _UsersPageTab.demat => 'Demat accounts',
        _UsersPageTab.mf => 'MF folios',
        _UsersPageTab.brokers => 'broker accounts',
        _UsersPageTab.nps => 'NPS accounts',
        _UsersPageTab.family => 'family members',
        _ => 'accounts',
      };

  Future<void> _addFamilyFromCard(BuildContext context) async {
    final hub = ref.read(accountsHubProvider(widget.userId)).asData?.value;
    if (hub != null && hub.familyMembers.length >= 5) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum of 5 family members allowed')),
        );
      }
      return;
    }
    final result = await _UsersFamilyPanel._promptFamilyMember(context);
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

  Future<void> _deleteFamilyFromCard(
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
          'Removes $name, their linked broker portfolios, and CAS/NPS imports for that persona. Your primary portfolios stay.',
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
      if (_familyMemberId == id) {
        setState(() => _familyMemberId = null);
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
}

class _UsersFamilyPanel extends ConsumerWidget {
  const _UsersFamilyPanel({
    required this.userId,
    required this.members,
    required this.books,
  });

  final String userId;
  final List<FamilyMemberRow> members;
  final List<AccountsPortfolioRow> books;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(accountsHubProvider(userId));
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    if (members.length >= 5) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum of 5 family members allowed')),
        );
      }
      return;
    }
    final result = await _promptFamilyMember(context);
    if (result == null || !context.mounted) return;
    try {
      final client = await ref.read(portfolioApiClientProvider.future);
      await createFamilyMember(
        client: client,
        displayName: result.$1,
        email: result.$2,
      );
      await _refresh(ref);
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

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    FamilyMemberRow member,
  ) async {
    final id = member.id?.trim();
    if (id == null || id.isEmpty) return;
    final result = await _promptFamilyMember(
      context,
      initialName: member.name,
      initialEmail: member.email,
      title: 'Edit family member',
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
      await _refresh(ref);
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

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
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
          'Removes $name, their linked broker portfolios, and CAS/NPS imports for that persona. Your primary portfolios stay.',
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
      await _refresh(ref);
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

  static Future<(String, String?)?> _promptFamilyMember(
    BuildContext context, {
    String? initialName,
    String? initialEmail,
    String title = 'Add family member',
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
              autofocus: true,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: members.length >= 5
                  ? null
                  : () => _add(context, ref),
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: Text(
                members.length >= 5
                    ? 'Family limit reached (5)'
                    : 'Add family member',
              ),
            ),
          ),
          if (members.length >= 5) ...[
            const SizedBox(height: 6),
            Text(
              'You can add up to 5 family members.',
              style: context.text.caption().copyWith(
                    color: context.colors.textSecondary,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          if (members.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No family members yet.\nAdd one or import a CDSL/NPS statement for another holder.',
                  textAlign: TextAlign.center,
                  style: context.text.body().copyWith(
                        color: context.colors.textSecondary,
                      ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: members.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final m = members[i];
                  final memberId = m.id;
                  final tagged = books
                      .where((p) =>
                          memberId != null &&
                          p.familyMemberId == memberId)
                      .toList();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      m.name?.trim().isNotEmpty == true
                          ? m.name!.trim()
                          : 'Family member',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      [
                        if (m.email != null && m.email!.isNotEmpty) m.email,
                        '${tagged.length} portfolios',
                        if (m.source != null) m.source,
                      ].whereType<String>().join(' · '),
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _edit(context, ref, m),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => _delete(context, ref, m),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
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
    required this.showKpis,
    required this.kpis,
    this.pran,
    this.registrationDate,
    this.nomineeDetails,
    this.familySharePct,
    this.totalValue,
    this.xirrPct,
    this.activeAccountCount = 0,
  });

  final String? name;
  final String? pran;
  final String? registrationDate;
  final String? nomineeDetails;
  final double? familySharePct;
  final bool hasLinked;
  final bool showKpis;
  final List<_KpiSpec> kpis;
  final double? totalValue;
  final double? xirrPct;
  final int activeAccountCount;

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
    final compact = MediaQuery.sizeOf(context).width < 720;

    final xirrPanel = _XirrPanel(
      totalValue: totalValue,
      xirrPct: xirrPct,
      compact: compact,
    );

    return AmGlassCard(
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Mobile cards are often <360 after page+card padding; keep
          // name and XIRR on one row whenever compact or width allows.
          final sideBySide = compact || constraints.maxWidth >= 320;
          final left = _leftStack(
            context,
            accent,
            muted,
            success,
            compact: compact,
            trailing: compact && !(showKpis && kpis.isNotEmpty)
                ? xirrPanel
                : null,
          );
          final right = showKpis && kpis.isNotEmpty
              ? _kpiRow(context, accent)
              : xirrPanel;
          if (compact && !(showKpis && kpis.isNotEmpty)) {
            // Name + XIRR already share a row inside _leftStack.
            return left;
          }
          if (sideBySide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: left),
                SizedBox(width: compact ? 8 : 12),
                right,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              left,
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: right),
              if (showKpis && kpis.isNotEmpty) ...[
                const SizedBox(height: 14),
                _kpiRow(context, accent),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _activeBadge(Color success) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: success.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: success.withValues(alpha: 0.55)),
      ),
      child: Text(
        'Active',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: success,
        ),
      ),
    );
  }

  Widget _leftStack(
    BuildContext context,
    Color accent,
    Color muted,
    Color success, {
    required bool compact,
    Widget? trailing,
  }) {
    final nominee = nomineeDetails?.trim();
    final hasMeta = (pran != null && pran!.isNotEmpty) ||
        (registrationDate != null && registrationDate!.trim().isNotEmpty) ||
        (nominee != null && nominee.isNotEmpty) ||
        familySharePct != null;
    final avatarSize = compact ? 36.0 : 48.0;
    final nameStyle = context.text.sectionTitle().copyWith(
          fontWeight: FontWeight.w800,
          fontSize: compact ? 13 : 20,
          height: 1.15,
        );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
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
                    fontSize: 12,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: nameStyle,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
            ],
          ),
          if (hasMeta) ...[
            const SizedBox(height: 6),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: accent.withValues(alpha: 0.65)),
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
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
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
                  fontSize: 15,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(_displayName, style: nameStyle),
                  if (hasLinked) _activeBadge(success),
                  Text(
                    formatAccountCountLabel(activeAccountCount),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (hasMeta) const SizedBox(height: 8),
        if (hasMeta)
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

class _XirrPanel extends StatelessWidget {
  const _XirrPanel({
    required this.totalValue,
    required this.xirrPct,
    this.compact = false,
  });

  final double? totalValue;
  final double? xirrPct;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final muted = context.colors.textSecondary;
    final xirrColor = xirrPct == null
        ? muted
        : (xirrPct! >= 0
            ? context.colors.statusSuccess
            : context.colors.statusError);
    final xirrText = PersonaCardStrip.formatXirr(xirrPct);
    final valueText = PersonaCardStrip.formatBalance(
      totalValue != null && totalValue! > 0 ? totalValue : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'XIRR',
          style: TextStyle(
            fontSize: compact ? 9 : 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            height: 1.1,
            color: muted,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          xirrText,
          style: TextStyle(
            fontSize: compact ? 18 : 22,
            fontWeight: FontWeight.w800,
            height: 1.1,
            color: xirrColor,
          ),
        ),
        if (valueText != '—') ...[
          const SizedBox(height: 1),
          Text(
            valueText,
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w600,
              height: 1.1,
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ],
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
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _UsersPageTab.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t = _UsersPageTab.values[i];
          final isSelected = selected == t;
          return InkWell(
            onTap: () => onSelected(t),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? accent
                      : context.colors.border.withValues(alpha: 0.7),
                ),
              ),
              child: Text(
                labelFor(t),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? context.colors.actionPrimaryFg
                      : context.colors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AccountTypeDropdown extends StatelessWidget {
  const _AccountTypeDropdown({
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
    final colors = context.colors;
    return PopupMenuButton<_UsersPageTab>(
      tooltip: 'Account type',
      offset: const Offset(0, 40),
      onSelected: onSelected,
      color: colors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accent.withValues(alpha: 0.35)),
      ),
      itemBuilder: (ctx) => [
        for (final t in _UsersPageTab.values)
          PopupMenuItem<_UsersPageTab>(
            value: t,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    labelFor(t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight:
                          t == selected ? FontWeight.w700 : FontWeight.w500,
                      color: t == selected ? accent : colors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (t == selected)
                  Icon(Icons.check_rounded, size: 16, color: accent),
              ],
            ),
          ),
      ],
      child: Container(
        height: 36,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.category_outlined, size: 14, color: accent),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                labelFor(selected),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _MobilePersonaBar extends StatelessWidget {
  const _MobilePersonaBar({
    required this.selectedKey,
    required this.primaryLabel,
    required this.members,
    required this.favoriteKey,
    required this.onSelected,
    required this.onFavorite,
    required this.selectedTab,
    required this.tabLabelFor,
    required this.onTabSelected,
  });

  final String selectedKey;
  final String primaryLabel;
  final List<({String id, String name})> members;
  final String? favoriteKey;
  final ValueChanged<String> onSelected;
  final VoidCallback onFavorite;
  final _UsersPageTab selectedTab;
  final String Function(_UsersPageTab) tabLabelFor;
  final ValueChanged<_UsersPageTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.dashboard;
    final favorited = favoriteKey == selectedKey;
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: SharedFamilyFilterDropdown(
            compact: true,
            selectedKey: selectedKey,
            primaryLabel: primaryLabel,
            members: members,
            accentColor: accent,
            allLabel: 'All',
            onSelected: onSelected,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 4,
          child: _AccountTypeDropdown(
            selected: selectedTab,
            labelFor: tabLabelFor,
            onSelected: onTabSelected,
          ),
        ),
        const SizedBox(width: 2),
        IconButton(
          onPressed: onFavorite,
          tooltip: 'Favorite',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: Icon(
            favorited ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 22,
            color: favorited
                ? context.colors.statusWarning
                : context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
