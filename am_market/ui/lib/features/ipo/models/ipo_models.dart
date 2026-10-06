class AsraxIpoCountsDto {
  final int open;
  final int upcoming;
  final int closed;
  final int closingToday;
  final int listed;
  final int total;
  final String? lastSyncedAt;

  AsraxIpoCountsDto({
    this.open = 0,
    this.upcoming = 0,
    this.closed = 0,
    this.closingToday = 0,
    this.listed = 0,
    this.total = 0,
    this.lastSyncedAt,
  });

  factory AsraxIpoCountsDto.fromJson(Map<String, dynamic> json) {
    return AsraxIpoCountsDto(
      open: json['open'] as int? ?? 0,
      upcoming: json['upcoming'] as int? ?? 0,
      closed: json['closed'] as int? ?? 0,
      closingToday: json['closingToday'] as int? ?? 0,
      listed: json['listed'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      lastSyncedAt: json['lastSyncedAt'] as String?,
    );
  }
}

class AsraxInvestorCategoryDto {
  final String category;
  final String? subscription;

  AsraxInvestorCategoryDto({
    required this.category,
    this.subscription,
  });

  factory AsraxInvestorCategoryDto.fromJson(Map<String, dynamic> json) {
    return AsraxInvestorCategoryDto(
      category: json['category'] as String? ?? '',
      subscription: json['subscription'] as String?,
    );
  }
}

class AsraxIpoSummaryDto {
  final String id;
  final String? symbol;
  final String? companyName;
  final String? status;
  final String? isin;
  final String? issueType;
  final double? issueSizeCr;
  final String? industry;
  final double? minimumPrice;
  final double? maximumPrice;
  final String? biddingStartDate;
  final String? biddingEndDate;
  final String? totalSubscription;
  final List<AsraxInvestorCategoryDto>? eligibleInvestors;
  final int? lotSize;
  final int? minimumQuantity;
  final double? cutOffPrice;
  final double? minInvestment;

  AsraxIpoSummaryDto({
    required this.id,
    this.symbol,
    this.companyName,
    this.status,
    this.isin,
    this.issueType,
    this.issueSizeCr,
    this.industry,
    this.minimumPrice,
    this.maximumPrice,
    this.biddingStartDate,
    this.biddingEndDate,
    this.totalSubscription,
    this.eligibleInvestors,
    this.lotSize,
    this.minimumQuantity,
    this.cutOffPrice,
    this.minInvestment,
  });

  factory AsraxIpoSummaryDto.fromJson(Map<String, dynamic> json) {
    return AsraxIpoSummaryDto(
      id: json['id'] as String,
      symbol: json['symbol'] as String?,
      companyName: json['companyName'] as String?,
      status: json['status'] as String?,
      isin: json['isin'] as String?,
      issueType: json['issueType'] as String?,
      issueSizeCr: (json['issueSizeCr'] as num?)?.toDouble(),
      industry: json['industry'] as String?,
      minimumPrice: (json['minimumPrice'] as num?)?.toDouble(),
      maximumPrice: (json['maximumPrice'] as num?)?.toDouble(),
      biddingStartDate: json['biddingStartDate'] as String?,
      biddingEndDate: json['biddingEndDate'] as String?,
      totalSubscription: json['totalSubscription'] as String?,
      eligibleInvestors: (json['eligibleInvestors'] as List<dynamic>?)
          ?.map((e) => AsraxInvestorCategoryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      lotSize: json['lotSize'] != null ? int.tryParse(json['lotSize'].toString()) : null,
      minimumQuantity: json['minimumQuantity'] != null ? int.tryParse(json['minimumQuantity'].toString()) : null,
      cutOffPrice: json['cutOffPrice'] != null ? double.tryParse(json['cutOffPrice'].toString()) : null,
      minInvestment: (json['minInvestment'] ?? json['minimumInvestment'] ?? json['min_investment']) != null
          ? double.tryParse((json['minInvestment'] ?? json['minimumInvestment'] ?? json['min_investment']).toString())
          : null,
    );
  }

  /// Computed minimum investment amount in INR.
  double? get calculatedMinInvestment {
    if (minInvestment != null && minInvestment! > 0) return minInvestment;
    final qty = (minimumQuantity ?? lotSize)?.toDouble();
    final price = cutOffPrice ?? maximumPrice ?? minimumPrice;
    if (qty != null && price != null && qty > 0 && price > 0) {
      return qty * price;
    }
    return null;
  }
}

class AsraxIpoTimelineDto {
  final String? preApplyStartDate;
  final String? applicationStartDate;
  final String? applicationEndDate;
  final String? allotmentStartDate;
  final String? allotmentDate;
  final String? refundInitiationDate;
  final String? dematTransferDate;
  final String? listingDate;
  final String? mandateEndDate;

  // Backward compatibility aliases
  String? get biddingStartDate => applicationStartDate;
  String? get biddingEndDate => applicationEndDate;

  AsraxIpoTimelineDto({
    this.preApplyStartDate,
    this.applicationStartDate,
    this.applicationEndDate,
    this.allotmentStartDate,
    this.allotmentDate,
    this.refundInitiationDate,
    this.dematTransferDate,
    this.listingDate,
    this.mandateEndDate,
  });

  factory AsraxIpoTimelineDto.fromJson(Map<String, dynamic> json) {
    return AsraxIpoTimelineDto(
      preApplyStartDate: json['preApplyStartDate'] as String?,
      applicationStartDate: (json['applicationStartDate'] ?? json['biddingStartDate']) as String?,
      applicationEndDate: (json['applicationEndDate'] ?? json['biddingEndDate']) as String?,
      allotmentStartDate: json['allotmentStartDate'] as String?,
      allotmentDate: json['allotmentDate'] as String?,
      refundInitiationDate: json['refundInitiationDate'] as String?,
      dematTransferDate: json['dematTransferDate'] as String?,
      listingDate: json['listingDate'] as String?,
      mandateEndDate: json['mandateEndDate'] as String?,
    );
  }
}

class AsraxIpoRegistrarDto {
  final String? name;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? websiteUrl;
  final String? registrarKey;

  // Backward compatibility aliases
  String? get contactPerson => contactName;
  String? get contactNumber => phone;
  String? get website => websiteUrl;

  AsraxIpoRegistrarDto({
    this.name,
    this.contactName,
    this.phone,
    this.email,
    this.websiteUrl,
    this.registrarKey,
  });

  factory AsraxIpoRegistrarDto.fromJson(Map<String, dynamic> json) {
    return AsraxIpoRegistrarDto(
      name: json['name'] as String?,
      contactName: (json['contactName'] ?? json['contactPerson']) as String?,
      phone: (json['contactNumber'] ?? json['phone']) as String?,
      email: json['email'] as String?,
      websiteUrl: (json['website'] ?? json['websiteUrl']) as String?,
      registrarKey: json['registrarKey'] as String?,
    );
  }
}

class AsraxIpoDetailsDto {
  final String id;
  final String? symbol;
  final String? companyName;
  final String? status;
  final String? isin;
  final String? issueType;
  final double? issueSizeCr;
  final String? industry;
  final double? minimumPrice;
  final double? maximumPrice;
  final String? biddingStartDate;
  final String? biddingEndDate;
  final String? dailyStartTime;
  final String? dailyEndTime;
  final double? faceValue;
  final double? tickSize;
  final int? lotSize;
  final int? minimumQuantity;
  final double? cutOffPrice;
  final double? listingPrice;
  final String? listingExchange;
  final String? rhpUrl;
  final String? drhpUrl;
  final AsraxIpoTimelineDto? timeline;
  final AsraxIpoRegistrarDto? registrarInfo;
  final String? totalSubscription;
  final List<AsraxInvestorCategoryDto>? eligibleInvestors;
  final double? minInvestment;

  AsraxIpoDetailsDto({
    required this.id,
    this.symbol,
    this.companyName,
    this.status,
    this.isin,
    this.issueType,
    this.issueSizeCr,
    this.industry,
    this.minimumPrice,
    this.maximumPrice,
    this.biddingStartDate,
    this.biddingEndDate,
    this.dailyStartTime,
    this.dailyEndTime,
    this.faceValue,
    this.tickSize,
    this.lotSize,
    this.minimumQuantity,
    this.cutOffPrice,
    this.listingPrice,
    this.listingExchange,
    this.rhpUrl,
    this.drhpUrl,
    this.timeline,
    this.registrarInfo,
    this.totalSubscription,
    this.eligibleInvestors,
    this.minInvestment,
  });

  factory AsraxIpoDetailsDto.fromJson(Map<String, dynamic> json) {
    return AsraxIpoDetailsDto(
      id: json['id'] as String,
      symbol: json['symbol'] as String?,
      companyName: json['companyName'] as String?,
      status: json['status'] as String?,
      isin: json['isin'] as String?,
      issueType: json['issueType'] as String?,
      issueSizeCr: (json['issueSizeCr'] as num?)?.toDouble(),
      industry: json['industry'] as String?,
      minimumPrice: (json['minimumPrice'] as num?)?.toDouble(),
      maximumPrice: (json['maximumPrice'] as num?)?.toDouble(),
      biddingStartDate: json['biddingStartDate'] as String?,
      biddingEndDate: json['biddingEndDate'] as String?,
      dailyStartTime: json['dailyStartTime'] as String?,
      dailyEndTime: json['dailyEndTime'] as String?,
      faceValue: (json['faceValue'] as num?)?.toDouble(),
      tickSize: (json['tickSize'] as num?)?.toDouble(),
      lotSize: json['lotSize'] != null ? int.tryParse(json['lotSize'].toString()) : null,
      minimumQuantity: json['minimumQuantity'] != null ? int.tryParse(json['minimumQuantity'].toString()) : null,
      cutOffPrice: json['cutOffPrice'] != null ? double.tryParse(json['cutOffPrice'].toString()) : null,
      listingPrice: (json['listingPrice'] as num?)?.toDouble(),
      listingExchange: json['listingExchange'] as String?,
      rhpUrl: json['rhpUrl'] as String?,
      drhpUrl: json['drhpUrl'] as String?,
      timeline: json['timeline'] != null
          ? AsraxIpoTimelineDto.fromJson(json['timeline'] as Map<String, dynamic>)
          : null,
      registrarInfo: json['registrarInfo'] != null
          ? AsraxIpoRegistrarDto.fromJson(json['registrarInfo'] as Map<String, dynamic>)
          : null,
      totalSubscription: json['totalSubscription'] as String?,
      eligibleInvestors: (json['eligibleInvestors'] as List<dynamic>?)
          ?.map((e) => AsraxInvestorCategoryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      minInvestment: (json['minInvestment'] ?? json['minimumInvestment'] ?? json['min_investment']) != null
          ? double.tryParse((json['minInvestment'] ?? json['minimumInvestment'] ?? json['min_investment']).toString())
          : null,
    );
  }

  /// Computed minimum investment amount in INR.
  double? get calculatedMinInvestment {
    if (minInvestment != null && minInvestment! > 0) return minInvestment;
    final qty = (minimumQuantity ?? lotSize)?.toDouble();
    final price = cutOffPrice ?? maximumPrice ?? minimumPrice;
    if (qty != null && price != null && qty > 0 && price > 0) {
      return qty * price;
    }
    return null;
  }
}
