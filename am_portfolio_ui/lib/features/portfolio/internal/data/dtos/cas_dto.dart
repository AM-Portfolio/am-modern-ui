/// CDSL CAS wire DTOs (GET /v1/portfolios/accounts, /cas/latest, /folios).

class CasDocumentMetaDto {
  const CasDocumentMetaDto({
    this.documentSource,
    this.asOfDate,
    this.statementFrom,
    this.statementTo,
    this.importedAt,
    this.validationAllOk,
    this.totalValue,
  });

  factory CasDocumentMetaDto.fromJson(Map<String, dynamic> json) {
    final validation = json['validation'];
    final cover = json['cover'];
    return CasDocumentMetaDto(
      documentSource: json['documentSource'] as String?,
      asOfDate: json['asOfDate'] as String?,
      statementFrom: json['statementFrom'] as String?,
      statementTo: json['statementTo'] as String?,
      importedAt: json['importedAt'] as String?,
      validationAllOk: validation is Map
          ? validation['allOk'] as bool?
          : null,
      totalValue: cover is Map
          ? (cover['totalValue'] as num?)?.toDouble()
          : null,
    );
  }

  final String? documentSource;
  final String? asOfDate;
  final String? statementFrom;
  final String? statementTo;
  final String? importedAt;
  final bool? validationAllOk;
  final double? totalValue;
}

class DematAccountDto {
  const DematAccountDto({
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
    this.holdingValue,
    this.mappedBroker,
    this.amcName,
    this.folio,
    this.active,
    this.portfolioId,
  });

  factory DematAccountDto.fromJson(Map<String, dynamic> json) => DematAccountDto(
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
        holdingValue: (json['holdingValue'] as num?)?.toDouble(),
        mappedBroker: json['mappedBroker']?.toString(),
        amcName: json['amcName'] as String?,
        folio: json['folio'] as String?,
        active: json['active'] as bool?,
        portfolioId: json['portfolioId'] as String?,
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
  final double? holdingValue;
  final String? mappedBroker;
  final String? amcName;
  final String? folio;
  final bool? active;
  final String? portfolioId;

  bool get isLinked =>
      mappedBroker != null && mappedBroker!.trim().isNotEmpty;
}

class CasMfFolioDto {
  const CasMfFolioDto({
    required this.folio,
    this.amcName,
    this.rtaName,
    this.advisorName,
    this.ucc,
    this.holdings = const [],
  });

  factory CasMfFolioDto.fromJson(Map<String, dynamic> json) => CasMfFolioDto(
        folio: json['folio'] as String? ?? '',
        amcName: json['amcName'] as String?,
        rtaName: json['rtaName'] as String?,
        advisorName: json['advisorName'] as String?,
        ucc: json['ucc'] as String?,
        holdings: (json['holdings'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
      );

  final String folio;
  final String? amcName;
  final String? rtaName;
  final String? advisorName;
  final String? ucc;
  final List<Map<String, dynamic>> holdings;
}
