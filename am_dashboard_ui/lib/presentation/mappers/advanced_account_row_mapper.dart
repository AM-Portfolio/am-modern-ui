import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';
import 'package:am_design_system/am_design_system.dart';

bool _isPrimaryPortfolio(AccountsPortfolioRow p) {
  final id = p.familyMemberId?.trim();
  return id == null || id.isEmpty;
}

double? _weightPctOfScope(double? value, double? scopeTotal) {
  if (value == null || scopeTotal == null || scopeTotal <= 0) return null;
  return (value / scopeTotal) * 100.0;
}

/// Maps accounts-hub models into design-system [AdvancedAccountRow]s.
///
/// [brokers] / [mf] / [demat] should already be persona-scoped by the caller
/// (You / member / All). [nps] overrides [hub.nps] for the selected persona.
List<AdvancedAccountRow> mapAccountsHubToAdvancedRows({
  required List<AccountsPortfolioRow> brokers,
  required List<DematAccountRow> mf,
  required List<DematAccountRow> demat,
  required AccountsHub hub,
  required bool hasNps,
  NpsMetaRow? nps,
  double? scopeTotalValue,
  bool includeFamilySummaries = true,
}) {
  final out = <AdvancedAccountRow>[];
  final npsMeta = nps ?? hub.nps;

  final identityEmail = hub.identity?.email?.trim();
  final identityMobile = hub.identity?.mobile?.trim();

  for (final p in brokers) {
    final title = p.displayName?.trim().isNotEmpty == true
        ? p.displayName!.trim()
        : (p.brokerType ?? p.portfolioId ?? 'Broker');
    final broker = p.brokerType?.trim();
    final assets = p.assetCount;
    final primaryBroker = _isPrimaryPortfolio(p);
    out.add(
      AdvancedAccountRow(
        id: p.portfolioId ?? 'broker-$title',
        type: 'broker',
        title: title,
        accountId: p.portfolioId,
        broker: broker,
        email: primaryBroker ? identityEmail : null,
        mobile: primaryBroker ? identityMobile : null,
        status: 'Active',
        statusKind: AccountStatusKind.active,
        value: p.current ?? 0,
        hasValue: p.current != null,
        weightPct: _weightPctOfScope(p.current, scopeTotalValue),
        subtitle: [
          if (broker != null && broker.isNotEmpty) broker,
          if (assets != null) '$assets assets',
        ].join(' · '),
      ),
    );
  }

  for (final a in mf) {
    out.add(_dematRow(a, type: 'mf', scopeTotalValue: scopeTotalValue));
  }
  for (final a in demat) {
    out.add(_dematRow(a, type: 'demat', scopeTotalValue: scopeTotalValue));
  }

  if (hasNps && npsMeta != null) {
    final n = npsMeta;
    final nominee = n.nomineeDetails?.trim();
    out.add(
      AdvancedAccountRow(
        id: 'nps-${n.pran ?? 'linked'}',
        type: 'nps',
        title: n.pran != null ? 'PRAN ${n.pran}' : 'NPS',
        accountId: n.pran,
        nominee: nominee,
        nomineeMissing: nominee == null || nominee.isEmpty,
        email: n.subscriberEmail,
        mobile: n.subscriberMobile,
        status: 'Active',
        statusKind: AccountStatusKind.active,
        value: n.totalValue ?? 0,
        hasValue: n.totalValue != null,
        weightPct: _weightPctOfScope(n.totalValue, scopeTotalValue),
        subtitle: [
          if (n.registrationDate != null &&
              n.registrationDate!.trim().isNotEmpty)
            'Reg ${n.registrationDate}',
          if (n.asOfDate != null) 'As of ${n.asOfDate}',
          if (n.tier1Value != null) 'T-I',
          if (n.tier2Value != null) 'T-II',
        ].join(' · '),
      ),
    );
  }

  if (includeFamilySummaries) {
    final familyBooks = hub.portfolios
        .where((p) => !_isPrimaryPortfolio(p))
        .toList();
    for (final m in hub.familyMembers) {
      final memberId = m.id?.trim();
      final books = familyBooks
          .where((p) => memberId != null && p.familyMemberId == memberId)
          .toList();
      final bookValue =
          books.fold<double>(0, (s, p) => s + (p.current ?? 0));
      out.add(
        AdvancedAccountRow(
          id: m.id ?? 'family-${m.name}',
          type: 'family',
          title: m.name?.trim().isNotEmpty == true
              ? m.name!.trim()
              : 'Family member',
          accountId: m.id,
          email: m.email,
          status: 'Linked',
          statusKind: AccountStatusKind.active,
          value: bookValue,
          hasValue: books.isNotEmpty,
          subtitle: [
            if (m.email != null && m.email!.isNotEmpty) m.email!,
            if (m.portfolioCount != null) '${m.portfolioCount} demat',
            if (m.source != null) m.source!,
          ].join(' · '),
        ),
      );
    }
  }

  return out;
}

AdvancedAccountRow _dematRow(
  DematAccountRow a, {
  required String type,
  double? scopeTotalValue,
}) {
  final isMf = type == 'mf';
  final named = a.dpName?.trim();
  final title = isMf
      ? (named != null && named.isNotEmpty ? named : 'Mutual Funds')
      : (a.dpName ?? a.boid ?? a.accountNo);
  final accountId = isMf
      ? (a.folio ?? a.accountNo)
      : (a.boid ?? a.clientId ?? a.accountNo);

  final nomineeRaw = a.nominee?.trim();
  final nomineeLower = nomineeRaw?.toLowerCase() ?? '';
  final hasNominee = nomineeRaw != null &&
      nomineeRaw.isNotEmpty &&
      !nomineeLower.contains('not registered') &&
      nomineeLower != 'please nominate';
  final nomineeMissing = !hasNominee &&
      (a.nomineeRegistered == false ||
          nomineeLower.contains('not registered') ||
          nomineeLower == 'please nominate' ||
          nomineeRaw == null ||
          nomineeRaw.isEmpty);
  final nomineeLabel = hasNominee
      ? nomineeRaw
      : (nomineeMissing ? 'No nominee' : null);

  final statusKind = AdvancedAccountRow.resolveStatusKind(
    status: a.status,
    frozen: a.frozenStatus,
    active: a.active,
  );

  return AdvancedAccountRow(
    id: '$type-${a.accountNo}-$accountId',
    type: type,
    title: title,
    accountId: accountId,
    broker: a.mappedBroker ?? (isMf ? a.amcName : null),
    nominee: nomineeLabel,
    nomineeMissing: nomineeMissing,
    email: a.email,
    mobile: a.mobile,
    status: a.status,
    frozen: a.frozenStatus,
    statusKind: statusKind,
    value: a.holdingValue ?? 0,
    hasValue: a.holdingValue != null,
    weightPct: _weightPctOfScope(a.holdingValue, scopeTotalValue),
    subtitle: [
      if (!isMf) 'Depository: CDSL',
      if (isMf && a.amcName != null && a.amcName!.trim().isNotEmpty)
        a.amcName!.trim(),
      if (!isMf && a.dpId != null && a.dpId!.trim().isNotEmpty)
        'DP ${a.dpId}',
    ].join(' · '),
  );
}

List<AdvancedAccountRow> filterAdvancedAccountRowsByTab({
  required List<AdvancedAccountRow> rows,
  required String tab,
}) {
  switch (tab) {
    case 'brokers':
      return rows.where((r) => r.type == 'broker').toList();
    case 'mf':
      return rows.where((r) => r.type == 'mf').toList();
    case 'demat':
      return rows.where((r) => r.type == 'demat').toList();
    case 'nps':
      return rows.where((r) => r.type == 'nps').toList();
    case 'family':
      return rows.where((r) => r.type == 'family').toList();
    case 'overview':
    default:
      return rows;
  }
}

List<AdvancedAccountRow> filterAdvancedAccountRowsByBroker({
  required List<AdvancedAccountRow> rows,
  required String brokerFilter,
}) {
  if (brokerFilter == 'all' || brokerFilter.isEmpty) return rows;
  if (brokerFilter.toLowerCase() == 'other') {
    return rows.where((r) {
      if (r.type == 'family' || r.type == 'nps') return true;
      final key = _rowBrokerKey(r);
      return key.isEmpty || key == '—';
    }).toList();
  }
  final key = brokerFilter.toUpperCase();
  return rows.where((r) {
    if (r.type == 'broker') {
      return (r.broker ?? r.title).toUpperCase() == key ||
          r.title.toUpperCase() == key;
    }
    return (r.broker ?? '').toUpperCase() == key;
  }).toList();
}

String _rowBrokerKey(AdvancedAccountRow r) {
  final b = (r.broker ?? '').trim();
  if (b.isNotEmpty) return b.toUpperCase();
  final t = AdvancedAccountRow.firstWordOfTitle(r.title);
  return (t ?? '').trim().toUpperCase();
}

/// Broker swatch options counted from the current tab's rows (before broker filter).
///
/// [All] always equals [scopeRows].length so it matches what the table shows.
/// Known running brokers with zero rows stay visible (count 0) for Demat/Broker tabs.
List<({String key, String label, int count})> buildBrokerSwatchOptions({
  required List<AccountsPortfolioRow> runningBrokers,
  required List<DematAccountRow> demat,
  required List<DematAccountRow> mf,
  required String tab,
  List<AdvancedAccountRow>? scopeRows,
}) {
  final keys = <String>[];
  final labels = <String, String>{};

  void ensure(String rawKey, String label) {
    final key = rawKey.trim().toUpperCase();
    if (key.isEmpty) return;
    if (!keys.contains(key)) keys.add(key);
    labels.putIfAbsent(key, () => label);
  }

  final rows = scopeRows;
  if (rows != null) {
    for (final r in rows) {
      if (r.type == 'family' || r.type == 'nps') continue;
      final key = _rowBrokerKey(r);
      if (key.isEmpty || key == '—') continue;
      ensure(key, r.displayBroker == '—' ? key : r.displayBroker);
    }
    for (final p in runningBrokers) {
      final broker = (p.brokerType ?? p.displayName ?? '').trim();
      if (broker.isEmpty) continue;
      ensure(
        broker,
        p.displayName?.trim().isNotEmpty == true
            ? p.displayName!.trim()
            : broker,
      );
    }

    int countFor(String key) => rows.where((r) {
          if (r.type == 'family' || r.type == 'nps') return false;
          return _rowBrokerKey(r) == key;
        }).length;

    final countable = rows
        .where((r) => r.type != 'family')
        .toList(growable: false);
    final out = <({String key, String label, int count})>[
      (key: 'all', label: 'All', count: countable.length),
    ];
    for (final key in keys) {
      out.add((key: key, label: labels[key] ?? key, count: countFor(key)));
    }
    final mapped = keys.fold<int>(0, (s, k) => s + countFor(k));
    final other = countable.length - mapped;
    if (other > 0) {
      out.add((key: 'other', label: 'Other', count: other));
    }
    return out;
  }

  // Legacy path (tests / callers without scopeRows).
  for (final p in runningBrokers) {
    final broker = (p.brokerType ?? p.displayName ?? '').trim();
    if (broker.isEmpty) continue;
    ensure(
      broker,
      p.displayName?.trim().isNotEmpty == true
          ? p.displayName!.trim()
          : broker,
    );
  }
  for (final a in [...demat, ...mf]) {
    final mapped = (a.mappedBroker ?? '').trim();
    if (mapped.isEmpty) continue;
    ensure(mapped, mapped);
  }

  int countForLegacy(String key) {
    switch (tab) {
      case 'brokers':
        return runningBrokers.where((p) {
          final k = (p.brokerType ?? p.displayName ?? '').trim().toUpperCase();
          return k == key;
        }).length;
      case 'mf':
        return mf
            .where((a) => (a.mappedBroker ?? '').trim().toUpperCase() == key)
            .length;
      case 'demat':
        return demat
            .where((a) => (a.mappedBroker ?? '').trim().toUpperCase() == key)
            .length;
      case 'overview':
      default:
        final d = demat
            .where((a) => (a.mappedBroker ?? '').trim().toUpperCase() == key)
            .length;
        final m = mf
            .where((a) => (a.mappedBroker ?? '').trim().toUpperCase() == key)
            .length;
        if (d + m > 0) return d + m;
        return runningBrokers.where((p) {
          final k = (p.brokerType ?? p.displayName ?? '').trim().toUpperCase();
          return k == key;
        }).length;
    }
  }

  int allTotalLegacy() {
    switch (tab) {
      case 'brokers':
        return runningBrokers.length;
      case 'mf':
        return mf.length;
      case 'demat':
        return demat.length;
      case 'overview':
      default:
        // Prefer directory rows; do not also add running books (avoids All=8 chips=3).
        final dir = demat.length + mf.length;
        return dir > 0 ? dir : runningBrokers.length;
    }
  }

  final out = <({String key, String label, int count})>[
    (key: 'all', label: 'All', count: allTotalLegacy()),
  ];
  for (final key in keys) {
    out.add((key: key, label: labels[key] ?? key, count: countForLegacy(key)));
  }
  return out;
}

/// Counts broker/demat/mf/nps rows with strictly positive value.
/// Excludes family summary rows and zero-holding placeholders.
int countValuedAccounts(Iterable<AdvancedAccountRow> rows) {
  var n = 0;
  for (final r in rows) {
    final t = r.type.toLowerCase();
    if (t == 'family') continue;
    if (t != 'broker' && t != 'demat' && t != 'mf' && t != 'nps') continue;
    if (!r.hasValue || r.value <= 0) continue;
    n++;
  }
  return n;
}

String formatAccountCountLabel(int count) {
  if (count <= 0) return '0 accounts';
  if (count == 1) return '1 account';
  return '$count accounts';
}

bool matchesSoftPersona(String? rowFamilyId, String? selection) {
  // selection null = You; '__all__' = household; else member id.
  if (selection == '__all__') return true;
  final primary = rowFamilyId == null || rowFamilyId.trim().isEmpty;
  if (selection == null) return primary;
  return rowFamilyId == selection;
}

/// Valued account count for a soft-family persona selection.
int valuedAccountCountForPersona({
  required AccountsHub hub,
  required String? familyMemberId,
}) {
  final books = hub.portfolios
      .where((p) => matchesSoftPersona(p.familyMemberId, familyMemberId))
      .toList();
  final running = books.where((p) => p.isRunningBroker).toList();
  final dematAll = hub.dematAccounts
      .where((a) => matchesSoftPersona(a.familyMemberId, familyMemberId))
      .toList();
  final demat = dematAll
      .where((a) => (a.accountType ?? '').toLowerCase() != 'mf')
      .toList();
  final mf = dematAll
      .where((a) => (a.accountType ?? '').toLowerCase() == 'mf')
      .toList();
  NpsMetaRow? nps;
  if (familyMemberId == '__all__' || familyMemberId == null) {
    for (final n in hub.npsAccounts) {
      if (n.familyMemberId == null || n.familyMemberId!.trim().isEmpty) {
        nps = n;
        break;
      }
    }
    nps ??= hub.nps;
  } else {
    for (final n in hub.npsAccounts) {
      if (n.familyMemberId == familyMemberId) {
        nps = n;
        break;
      }
    }
  }
  final hasNps = nps?.pran != null && nps!.pran!.isNotEmpty;
  final rows = mapAccountsHubToAdvancedRows(
    brokers: running,
    mf: mf,
    demat: demat,
    hub: hub,
    hasNps: hasNps,
    nps: nps,
    includeFamilySummaries: false,
  );
  return countValuedAccounts(rows);
}

({double totalValue, int linkedCount, int brokersActive, int nomineeOk, int nomineeMissing})
    dematNomineeStats(List<DematAccountRow> rows) {
  var total = 0.0;
  var ok = 0;
  var missing = 0;
  final brokers = <String>{};
  for (final a in rows) {
    total += a.holdingValue ?? 0;
    final mapped = (a.mappedBroker ?? '').trim();
    if (mapped.isNotEmpty) brokers.add(mapped.toUpperCase());
    final nomineeRaw = a.nominee?.trim();
    final lower = nomineeRaw?.toLowerCase() ?? '';
    final hasNominee = nomineeRaw != null &&
        nomineeRaw.isNotEmpty &&
        !lower.contains('not registered') &&
        lower != 'please nominate';
    if (hasNominee) {
      ok++;
    } else if (a.nomineeRegistered == false ||
        lower.contains('not registered') ||
        lower == 'please nominate' ||
        nomineeRaw == null ||
        nomineeRaw.isEmpty) {
      missing++;
    }
  }
  return (
    totalValue: total,
    linkedCount: rows.length,
    brokersActive: brokers.length,
    nomineeOk: ok,
    nomineeMissing: missing,
  );
}
