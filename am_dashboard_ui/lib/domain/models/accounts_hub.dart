/// Dashboard parse of GET /v1/portfolios/accounts-hub
class AccountsHub {
  const AccountsHub({
    this.identity,
    this.stats,
    this.portfolios = const [],
    this.dematAccounts = const [],
    this.nps,
    this.npsAccounts = const [],
    this.familyMembers = const [],
  });

  factory AccountsHub.fromJson(Map<String, dynamic> json) {
    final identity = json['identity'];
    final stats = json['stats'];
    final portfolios = json['portfolios'];
    final demat = json['dematAccounts'];
    final nps = json['nps'];
    final npsAccounts = json['npsAccounts'];
    final family = json['familyMembers'];
    return AccountsHub(
      identity: identity is Map
          ? AccountsIdentity.fromJson(Map<String, dynamic>.from(identity))
          : null,
      stats: stats is Map
          ? AccountsStats.fromJson(Map<String, dynamic>.from(stats))
          : null,
      portfolios: portfolios is List
          ? portfolios
              .whereType<Map>()
              .map((e) => AccountsPortfolioRow.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
      dematAccounts: demat is List
          ? demat
              .whereType<Map>()
              .map((e) => DematAccountRow.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
      nps: nps is Map
          ? NpsMetaRow.fromJson(Map<String, dynamic>.from(nps))
          : null,
      npsAccounts: npsAccounts is List
          ? npsAccounts
              .whereType<Map>()
              .map((e) => NpsMetaRow.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      familyMembers: family is List
          ? family
              .whereType<Map>()
              .map((e) => FamilyMemberRow.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
    );
  }

  final AccountsIdentity? identity;
  final AccountsStats? stats;
  final List<AccountsPortfolioRow> portfolios;
  final List<DematAccountRow> dematAccounts;
  final NpsMetaRow? nps;
  final List<NpsMetaRow> npsAccounts;
  final List<FamilyMemberRow> familyMembers;
}

class FamilyMemberRow {
  const FamilyMemberRow({
    this.id,
    this.name,
    this.email,
    this.portfolioCount,
    this.source,
    this.totalValue,
    this.xirrPct,
  });

  factory FamilyMemberRow.fromJson(Map<String, dynamic> json) =>
      FamilyMemberRow(
        id: json['id'] as String?,
        name: (json['name'] as String?) ??
            (json['displayName'] as String?),
        email: json['email'] as String?,
        portfolioCount: (json['portfolioCount'] as num?)?.toInt(),
        source: json['source'] as String?,
        totalValue: (json['totalValue'] as num?)?.toDouble(),
        xirrPct: (json['xirrPct'] as num?)?.toDouble(),
      );

  final String? id;
  final String? name;
  final String? email;
  final int? portfolioCount;
  final String? source;
  final double? totalValue;
  final double? xirrPct;
}

class AccountsIdentity {
  const AccountsIdentity({
    this.name,
    this.email,
    this.mobile,
    this.pran,
    this.userId,
  });

  factory AccountsIdentity.fromJson(Map<String, dynamic> json) =>
      AccountsIdentity(
        name: json['name'] as String?,
        email: json['email'] as String?,
        mobile: json['mobile'] as String?,
        pran: json['pran'] as String?,
        userId: json['userId'] as String?,
      );

  final String? name;
  final String? email;
  final String? mobile;
  final String? pran;
  final String? userId;
}

class AccountsStats {
  const AccountsStats({
    this.activeDematCount,
    this.mfFolioCount,
    this.dematAccountCount,
    this.npsLinked,
    this.brokerPortfolioCount,
    this.overallXirrPct,
    this.householdXirrPct,
    this.primaryTotalValue,
    this.familyTotalValue,
    this.householdTotalValue,
    this.familySharePct,
  });

  factory AccountsStats.fromJson(Map<String, dynamic> json) => AccountsStats(
        activeDematCount: (json['activeDematCount'] as num?)?.toInt(),
        mfFolioCount: (json['mfFolioCount'] as num?)?.toInt(),
        dematAccountCount: (json['dematAccountCount'] as num?)?.toInt(),
        npsLinked: json['npsLinked'] as bool?,
        brokerPortfolioCount: (json['brokerPortfolioCount'] as num?)?.toInt(),
        overallXirrPct: (json['overallXirrPct'] as num?)?.toDouble(),
        householdXirrPct: (json['householdXirrPct'] as num?)?.toDouble(),
        primaryTotalValue: (json['primaryTotalValue'] as num?)?.toDouble(),
        familyTotalValue: (json['familyTotalValue'] as num?)?.toDouble(),
        householdTotalValue: (json['householdTotalValue'] as num?)?.toDouble(),
        familySharePct: (json['familySharePct'] as num?)?.toDouble(),
      );

  final int? activeDematCount;
  final int? mfFolioCount;
  final int? dematAccountCount;
  final bool? npsLinked;
  final int? brokerPortfolioCount;
  final double? overallXirrPct;
  final double? householdXirrPct;
  final double? primaryTotalValue;
  final double? familyTotalValue;
  final double? householdTotalValue;
  final double? familySharePct;
}

class AccountsPortfolioRow {
  const AccountsPortfolioRow({
    this.portfolioId,
    this.displayName,
    this.brokerType,
    this.portfolioKind,
    this.invested,
    this.current,
    this.returnAbs,
    this.returnPct,
    this.assetCount,
    this.dummy,
    this.familyMemberId,
    this.familyMemberName,
    this.dematBoid,
  });

  factory AccountsPortfolioRow.fromJson(Map<String, dynamic> json) =>
      AccountsPortfolioRow(
        portfolioId: json['portfolioId'] as String?,
        displayName: json['displayName'] as String?,
        brokerType: json['brokerType'] as String?,
        portfolioKind: json['portfolioKind'] as String?,
        invested: (json['invested'] as num?)?.toDouble(),
        current: (json['current'] as num?)?.toDouble(),
        returnAbs: (json['returnAbs'] as num?)?.toDouble(),
        returnPct: (json['returnPct'] as num?)?.toDouble(),
        assetCount: (json['assetCount'] as num?)?.toInt(),
        dummy: json['dummy'] as bool?,
        familyMemberId: json['familyMemberId'] as String?,
        familyMemberName: json['familyMemberName'] as String?,
        dematBoid: json['dematBoid'] as String?,
      );

  final String? portfolioId;
  final String? displayName;
  final String? brokerType;
  final String? portfolioKind;
  final double? invested;
  final double? current;
  final double? returnAbs;
  final double? returnPct;
  final int? assetCount;
  final bool? dummy;
  final String? familyMemberId;
  final String? familyMemberName;
  final String? dematBoid;

  bool get hasHoldings {
    if (assetCount != null) return assetCount! > 0;
    final inv = invested ?? 0;
    final cur = current ?? 0;
    return inv > 0 || cur > 0;
  }

  bool get isCdslAggregator {
    final broker = (brokerType ?? '').toUpperCase();
    if (broker == 'CDSL') return true;
    final name = (displayName ?? '').toLowerCase();
    if (name.contains('cdsl') ||
        name == 'cas' ||
        name.contains('cas aggregator')) {
      return true;
    }
    final kind = (portfolioKind ?? '').toUpperCase();
    return kind.contains('CAS');
  }

  bool get isNps {
    final broker = (brokerType ?? '').trim().toUpperCase();
    if (broker == 'NPS') return true;
    final name = (displayName ?? '').trim().toUpperCase();
    return name == 'NPS';
  }

  bool get isCasDematBook =>
      (brokerType ?? '').trim().toUpperCase() == 'CAS_DEMAT';

  bool get isMutualFundBook {
    if (!isCasDematBook) return false;
    if ((dematBoid ?? '').trim().toLowerCase() == 'mf:cas') return true;
    return (displayName ?? '').trim().toLowerCase() == 'mutual funds';
  }

  bool get isDematBook => isCasDematBook && !isMutualFundBook;

  /// First-class running broker. CAS demat and mutual-fund books are separate tabs.
  /// A book with holdings stays visible when the stored total is still 0.
  bool get isRunningBroker =>
      !isCdslAggregator && !isNps && !isCasDematBook && hasHoldings;
}

/// First-class Kafka / UI broker codes (Groww, Angel One, Zerodha, …).
const Set<String> kFirstClassBrokerCodes = {
  'DHAN',
  'GROWW',
  'ANGEL_ONE',
  'ZERODHA',
  'UPSTOX',
  'FYERS',
  'KOTAK',
  'HDFC',
  'MSTOCK',
};

/// Normalize CAS `mappedBroker` / brokerType to a first-class code, or null.
String? normalizeFirstClassBrokerCode(String? raw) {
  final m = (raw ?? '').trim().toLowerCase().replaceAll('-', '_');
  if (m.isEmpty) return null;
  switch (m) {
    case 'groww':
    case 'grow':
      return 'GROWW';
    case 'angleone':
    case 'angelone':
    case 'angel_one':
      return 'ANGEL_ONE';
    case 'zerodha':
      return 'ZERODHA';
    case 'kotak':
      return 'KOTAK';
    case 'dhan':
      return 'DHAN';
    case 'upstox':
      return 'UPSTOX';
    case 'fyers':
      return 'FYERS';
    case 'hdfc':
    case 'hdfc_bank':
      return 'HDFC';
    case 'mstock':
      return 'MSTOCK';
    default:
      final upper = m.toUpperCase();
      return kFirstClassBrokerCodes.contains(upper) ? upper : null;
  }
}

String firstClassBrokerDisplayName(String code) {
  switch (code.toUpperCase()) {
    case 'GROWW':
      return 'Groww';
    case 'ANGEL_ONE':
      return 'Angel One';
    case 'ZERODHA':
      return 'Zerodha';
    case 'KOTAK':
      return 'Kotak';
    case 'DHAN':
      return 'Dhan';
    case 'UPSTOX':
      return 'Upstox';
    case 'FYERS':
      return 'Fyers';
    case 'HDFC':
      return 'HDFC';
    case 'MSTOCK':
      return 'mStock';
    default:
      return code.replaceAll('_', ' ');
  }
}

/// Running broker books plus synthetic rows for valued first-class CAS directory
/// demats that do not yet have a running book (so Broker tab matches the statement).
List<AccountsPortfolioRow> runningBrokersUnionDirectory({
  required List<AccountsPortfolioRow> runningBrokers,
  required List<DematAccountRow> directoryDemat,
}) {
  final out = List<AccountsPortfolioRow>.from(runningBrokers);
  final covered = <String>{};
  for (final p in runningBrokers) {
    final code = normalizeFirstClassBrokerCode(p.brokerType) ??
        normalizeFirstClassBrokerCode(p.displayName);
    if (code != null) covered.add(code);
  }
  for (final a in directoryDemat) {
    if ((a.accountType ?? '').toLowerCase() == 'mf') continue;
    final value = a.holdingValue ?? 0;
    if (value <= 0) continue;
    final code = normalizeFirstClassBrokerCode(a.mappedBroker);
    if (code == null || covered.contains(code)) continue;
    covered.add(code);
    out.add(
      AccountsPortfolioRow(
        portfolioId: 'cas-dir-$code-${a.accountNo}',
        displayName: firstClassBrokerDisplayName(code),
        brokerType: code,
        current: value,
        assetCount: 0,
        familyMemberId: a.familyMemberId,
      ),
    );
  }
  return out;
}

class DematAccountRow {
  const DematAccountRow({
    required this.accountNo,
    this.accountType,
    this.status,
    this.email,
    this.mobile,
    this.holderName,
    this.dpId,
    this.clientId,
    this.boid,
    this.dpName,
    this.nominee,
    this.nomineeRegistered,
    this.frozenStatus,
    this.holdingValue,
    this.mappedBroker,
    this.amcName,
    this.folio,
    this.active,
    this.portfolioId,
    this.familyMemberId,
  });

  factory DematAccountRow.fromJson(Map<String, dynamic> json) =>
      DematAccountRow(
        accountNo: json['accountNo'] as String? ?? '',
        accountType: json['accountType'] as String?,
        status: json['status'] as String?,
        email: json['email'] as String?,
        mobile: json['mobile'] as String?,
        holderName: json['holderName'] as String?,
        dpId: json['dpId'] as String?,
        clientId: json['clientId'] as String?,
        boid: json['boid'] as String?,
        dpName: json['dpName'] as String?,
        nominee: json['nominee'] as String?,
        nomineeRegistered: json['nomineeRegistered'] as bool?,
        frozenStatus: json['frozenStatus'] as String?,
        holdingValue: (json['holdingValue'] as num?)?.toDouble(),
        mappedBroker: json['mappedBroker']?.toString(),
        amcName: json['amcName'] as String?,
        folio: json['folio'] as String?,
        active: json['active'] as bool?,
        portfolioId: json['portfolioId'] as String?,
        familyMemberId: json['familyMemberId'] as String?,
      );

  final String accountNo;
  final String? accountType;
  final String? status;
  final String? email;
  final String? mobile;
  final String? holderName;
  final String? dpId;
  final String? clientId;
  final String? boid;
  final String? dpName;
  final String? nominee;
  final bool? nomineeRegistered;
  final String? frozenStatus;
  final double? holdingValue;
  final String? mappedBroker;
  final String? amcName;
  final String? folio;
  final bool? active;
  final String? portfolioId;
  final String? familyMemberId;

  /// Prefer BOID, then client id, then account number for selector subtitles.
  String? get externalIdLabel {
    final b = boid?.trim();
    if (b != null && b.isNotEmpty) return b;
    final c = clientId?.trim();
    if (c != null && c.isNotEmpty) return c;
    final a = accountNo.trim();
    return a.isEmpty ? null : a;
  }
}

class NpsMetaRow {
  const NpsMetaRow({
    this.pran,
    this.subscriberName,
    this.subscriberEmail,
    this.subscriberMobile,
    this.asOfDate,
    this.tier1Value,
    this.tier2Value,
    this.totalValue,
    this.nomineeDetails,
    this.registrationDate,
    this.familyMemberId,
  });

  factory NpsMetaRow.fromJson(Map<String, dynamic> json) => NpsMetaRow(
        pran: json['pran'] as String?,
        subscriberName: json['subscriberName'] as String?,
        subscriberEmail: json['subscriberEmail'] as String?,
        subscriberMobile: json['subscriberMobile'] as String?,
        asOfDate: json['asOfDate'] as String?,
        tier1Value: (json['tier1Value'] as num?)?.toDouble(),
        tier2Value: (json['tier2Value'] as num?)?.toDouble(),
        totalValue: (json['totalValue'] as num?)?.toDouble(),
        nomineeDetails: json['nomineeDetails'] as String?,
        registrationDate: json['registrationDate'] as String?,
        familyMemberId: json['familyMemberId'] as String?,
      );

  final String? pran;
  final String? subscriberName;
  final String? subscriberEmail;
  final String? subscriberMobile;
  final String? asOfDate;
  final double? tier1Value;
  final double? tier2Value;
  final double? totalValue;
  final String? nomineeDetails;
  final String? registrationDate;
  final String? familyMemberId;
}

/// Line from GET /v1/portfolios/{id}/nps/schemes.
class NpsSchemeLine {
  const NpsSchemeLine({
    this.isin,
    this.schemeCode,
    this.name,
    this.tier,
    this.schemeClass,
    this.statementValue,
    this.liveValue,
  });

  factory NpsSchemeLine.fromJson(Map<String, dynamic> json) => NpsSchemeLine(
        isin: json['isin'] as String?,
        schemeCode: json['schemeCode'] as String?,
        name: json['name'] as String?,
        tier: json['tier'] as String?,
        schemeClass: json['schemeClass'] as String?,
        statementValue: (json['statementValue'] as num?)?.toDouble(),
        liveValue: (json['liveValue'] as num?)?.toDouble(),
      );

  final String? isin;
  final String? schemeCode;
  final String? name;
  final String? tier;
  final String? schemeClass;
  final double? statementValue;
  final double? liveValue;
}
