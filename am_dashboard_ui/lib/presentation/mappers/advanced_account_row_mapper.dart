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

  for (final p in brokers) {
    final title = p.displayName?.trim().isNotEmpty == true
        ? p.displayName!.trim()
        : (p.brokerType ?? p.portfolioId ?? 'Broker');
    final broker = p.brokerType?.trim();
    final assets = p.assetCount;
    out.add(
      AdvancedAccountRow(
        id: p.portfolioId ?? 'broker-$title',
        type: 'broker',
        title: title,
        accountId: p.portfolioId,
        broker: broker,
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
      for (final p in books) {
        final title = p.displayName?.trim().isNotEmpty == true
            ? p.displayName!.trim()
            : (p.brokerType ?? p.portfolioId ?? 'Broker');
        final broker = p.brokerType?.trim();
        out.add(
          AdvancedAccountRow(
            id: 'family-book-${p.portfolioId ?? title}',
            type: 'family',
            title: title,
            accountId: p.portfolioId,
            broker: broker,
            status: 'Active',
            statusKind: AccountStatusKind.active,
            value: p.current ?? 0,
            hasValue: p.current != null,
            subtitle: [
              m.name?.trim().isNotEmpty == true ? m.name!.trim() : 'Family',
              if (broker != null && broker.isNotEmpty) broker,
              if (p.assetCount != null) '${p.assetCount} assets',
            ].join(' · '),
          ),
        );
      }
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
  final title = isMf
      ? 'Folio ${a.folio ?? a.accountNo}'
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
  final key = brokerFilter.toUpperCase();
  return rows.where((r) {
    if (r.type == 'broker') {
      return (r.broker ?? r.title).toUpperCase() == key ||
          r.title.toUpperCase() == key;
    }
    return (r.broker ?? '').toUpperCase() == key;
  }).toList();
}

/// Broker swatch options with tab-aware counts (includes zeros for known books).
List<({String key, String label, int count})> buildBrokerSwatchOptions({
  required List<AccountsPortfolioRow> runningBrokers,
  required List<DematAccountRow> demat,
  required List<DematAccountRow> mf,
  required String tab,
}) {
  final keys = <String>[];
  final labels = <String, String>{};

  void ensure(String rawKey, String label) {
    final key = rawKey.trim().toUpperCase();
    if (key.isEmpty) return;
    if (!keys.contains(key)) keys.add(key);
    labels.putIfAbsent(key, () => label);
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
  for (final a in [...demat, ...mf]) {
    final mapped = (a.mappedBroker ?? '').trim();
    if (mapped.isEmpty) continue;
    ensure(mapped, mapped);
  }

  int countFor(String key) {
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

  int allTotal() {
    switch (tab) {
      case 'brokers':
        return runningBrokers.length;
      case 'mf':
        return mf.length;
      case 'demat':
        return demat.length;
      case 'overview':
      default:
        return demat.length + mf.length + runningBrokers.length;
    }
  }

  final out = <({String key, String label, int count})>[
    (key: 'all', label: 'All', count: allTotal()),
  ];
  for (final key in keys) {
    out.add((key: key, label: labels[key] ?? key, count: countFor(key)));
  }
  return out;
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
