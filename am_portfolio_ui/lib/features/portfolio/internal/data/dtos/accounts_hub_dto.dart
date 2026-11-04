import 'cas_dto.dart';
import 'nps_dto.dart';

/// GET /v1/portfolios/accounts-hub
class AccountsHubDto {
  const AccountsHubDto({
    this.identity,
    this.stats,
    this.portfolios = const [],
    this.dematAccounts = const [],
    this.nps,
    this.cas,
    this.familyMembers = const [],
  });

  factory AccountsHubDto.fromJson(Map<String, dynamic> json) {
    final identity = json['identity'];
    final stats = json['stats'];
    final portfolios = json['portfolios'];
    final demat = json['dematAccounts'];
    final nps = json['nps'];
    final cas = json['cas'];
    final family = json['familyMembers'];
    return AccountsHubDto(
      identity: identity is Map<String, dynamic>
          ? AccountsIdentityDto.fromJson(identity)
          : null,
      stats: stats is Map<String, dynamic>
          ? AccountsStatsDto.fromJson(stats)
          : null,
      portfolios: portfolios is List
          ? portfolios
              .whereType<Map>()
              .map((e) => AccountsPortfolioRowDto.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
      dematAccounts: demat is List
          ? demat
              .whereType<Map>()
              .map((e) => DematAccountDto.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
      nps: nps is Map<String, dynamic>
          ? NpsDocumentMetaDto.fromJson(nps)
          : null,
      cas: cas is Map<String, dynamic>
          ? CasDocumentMetaDto.fromJson(cas)
          : null,
      familyMembers: family is List
          ? family
              .whereType<Map>()
              .map((e) => FamilyMemberSummaryDto.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
    );
  }

  final AccountsIdentityDto? identity;
  final AccountsStatsDto? stats;
  final List<AccountsPortfolioRowDto> portfolios;
  final List<DematAccountDto> dematAccounts;
  final NpsDocumentMetaDto? nps;
  final CasDocumentMetaDto? cas;
  final List<FamilyMemberSummaryDto> familyMembers;
}

class FamilyMemberSummaryDto {
  const FamilyMemberSummaryDto({
    this.id,
    this.name,
    this.email,
    this.portfolioCount,
    this.source,
  });

  factory FamilyMemberSummaryDto.fromJson(Map<String, dynamic> json) =>
      FamilyMemberSummaryDto(
        id: json['id'] as String?,
        name: json['name'] as String?,
        email: json['email'] as String?,
        portfolioCount: (json['portfolioCount'] as num?)?.toInt(),
        source: json['source'] as String?,
      );

  final String? id;
  final String? name;
  final String? email;
  final int? portfolioCount;
  final String? source;
}

class AccountsIdentityDto {
  const AccountsIdentityDto({
    this.name,
    this.email,
    this.mobile,
    this.pran,
    this.userId,
  });

  factory AccountsIdentityDto.fromJson(Map<String, dynamic> json) =>
      AccountsIdentityDto(
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

class AccountsStatsDto {
  const AccountsStatsDto({
    this.activeDematCount,
    this.mfFolioCount,
    this.dematAccountCount,
    this.npsLinked,
    this.brokerPortfolioCount,
    this.overallXirrPct,
    this.primaryTotalValue,
    this.familyTotalValue,
    this.householdTotalValue,
    this.familySharePct,
  });

  factory AccountsStatsDto.fromJson(Map<String, dynamic> json) =>
      AccountsStatsDto(
        activeDematCount: (json['activeDematCount'] as num?)?.toInt(),
        mfFolioCount: (json['mfFolioCount'] as num?)?.toInt(),
        dematAccountCount: (json['dematAccountCount'] as num?)?.toInt(),
        npsLinked: json['npsLinked'] as bool?,
        brokerPortfolioCount: (json['brokerPortfolioCount'] as num?)?.toInt(),
        overallXirrPct: (json['overallXirrPct'] as num?)?.toDouble(),
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
  final double? primaryTotalValue;
  final double? familyTotalValue;
  final double? householdTotalValue;
  final double? familySharePct;
}

class AccountsPortfolioRowDto {
  const AccountsPortfolioRowDto({
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
  });

  factory AccountsPortfolioRowDto.fromJson(Map<String, dynamic> json) =>
      AccountsPortfolioRowDto(
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
}
