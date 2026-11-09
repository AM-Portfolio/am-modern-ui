/// NPS statement wire DTOs (GET /v1/portfolios/nps/latest, /nps/schemes).

class NpsDocumentMetaDto {
  const NpsDocumentMetaDto({
    this.documentSource,
    this.asOfDate,
    this.statementFrom,
    this.statementTo,
    this.importedAt,
    this.pran,
    this.subscriberName,
    this.subscriberEmail,
    this.subscriberMobile,
    this.tier1Value,
    this.tier2Value,
    this.totalValue,
    this.nomineeDetails,
    this.registrationDate,
    this.validationAllOk,
  });

  factory NpsDocumentMetaDto.fromJson(Map<String, dynamic> json) {
    final validation = json['validation'];
    return NpsDocumentMetaDto(
      documentSource: json['documentSource'] as String?,
      asOfDate: json['asOfDate'] as String?,
      statementFrom: json['statementFrom'] as String?,
      statementTo: json['statementTo'] as String?,
      importedAt: json['importedAt'] as String?,
      pran: json['pran'] as String?,
      subscriberName: json['subscriberName'] as String?,
      subscriberEmail: json['subscriberEmail'] as String?,
      subscriberMobile: json['subscriberMobile'] as String?,
      tier1Value: (json['tier1Value'] as num?)?.toDouble(),
      tier2Value: (json['tier2Value'] as num?)?.toDouble(),
      totalValue: (json['totalValue'] as num?)?.toDouble(),
      nomineeDetails: json['nomineeDetails'] as String?,
      registrationDate: json['registrationDate'] as String?,
      validationAllOk: validation is Map ? validation['allOk'] as bool? : null,
    );
  }

  final String? documentSource;
  final String? asOfDate;
  final String? statementFrom;
  final String? statementTo;
  final String? importedAt;
  final String? pran;
  final String? subscriberName;
  final String? subscriberEmail;
  final String? subscriberMobile;
  final double? tier1Value;
  final double? tier2Value;
  final double? totalValue;
  final String? nomineeDetails;
  final String? registrationDate;
  final bool? validationAllOk;
}

class NpsSchemeLineDto {
  const NpsSchemeLineDto({
    this.isin,
    this.schemeCode,
    this.name,
    this.tier,
    this.schemeClass,
    this.schemeOption,
    this.units,
    this.statementNav,
    this.liveNav,
    this.statementValue,
    this.liveValue,
    this.gainVsStatement,
    this.isinResolveStatus,
    this.pran,
  });

  factory NpsSchemeLineDto.fromJson(Map<String, dynamic> json) =>
      NpsSchemeLineDto(
        isin: json['isin'] as String?,
        schemeCode: json['schemeCode'] as String?,
        name: json['name'] as String?,
        tier: json['tier'] as String?,
        schemeClass: json['schemeClass'] as String?,
        schemeOption: json['schemeOption'] as String?,
        units: (json['units'] as num?)?.toDouble(),
        statementNav: (json['statementNav'] as num?)?.toDouble(),
        liveNav: (json['liveNav'] as num?)?.toDouble(),
        statementValue: (json['statementValue'] as num?)?.toDouble(),
        liveValue: (json['liveValue'] as num?)?.toDouble(),
        gainVsStatement: (json['gainVsStatement'] as num?)?.toDouble(),
        isinResolveStatus: json['isinResolveStatus'] as String?,
        pran: json['pran'] as String?,
      );

  final String? isin;
  final String? schemeCode;
  final String? name;
  final String? tier;
  final String? schemeClass;
  final String? schemeOption;
  final double? units;
  final double? statementNav;
  final double? liveNav;
  final double? statementValue;
  final double? liveValue;
  final double? gainVsStatement;
  final String? isinResolveStatus;
  final String? pran;

  bool get isUnmapped =>
      isinResolveStatus == 'UNMAPPED' ||
      (isin == null || isin!.isEmpty);
}
