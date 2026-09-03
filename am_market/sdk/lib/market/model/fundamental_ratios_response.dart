// ignore_for_file: unnecessary_null_comparison, parameter_assignments, unused_import, unused_element, always_put_required_named_parameters_first, constant_identifier_names, lines_longer_than_80_chars, avoid_dynamic_calls, invalid_assignment, undefined_method, undefined_getter, for_in_of_invalid_type, case_expression_type_is_not_switch_expression_subtype, deprecated_member_use_from_same_package
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

part of openapi.api;

class FundamentalRatiosResponse {
  FundamentalRatiosResponse({
    this.symbol,
    this.companyName,
    this.sector,
    this.industry,
    this.peRatio,
    this.pbRatio,
    this.roe,
    this.roce,
    this.dividendYield,
    this.debtToEquity,
    this.eps,
    this.bookValue,
    this.marketCap,
    this.priceToSales,
    this.evEbitda,
    this.peers,
    this.currentPrice,
    this.nim,
    this.netNpa,
    this.casa,
    this.quickRatio,
    this.currentRatio,
    this.cfoPat,
    this.operatingMarginPercent,
    this.netProfitMarginPercent,
    this.shareholding,
    this.incomeStatement,
    this.balanceSheet,
    this.cashFlow,
    this.description,
    this.dayHigh,
    this.dayLow,
    this.dayChange,
    this.dayChangePercent,
    this.sectorMarketCapInr,
    this.sectorMarketCapUsd,
    this.week52High,
    this.week52Low,
    this.priceCagr1Y,
    this.priceCagr3Y,
    this.priceCagr5Y,
    this.corporateActions,
  });

  String? symbol;
  String? companyName;
  String? sector;
  String? industry;
  double? peRatio;
  double? pbRatio;
  double? roe;
  double? roce;
  double? dividendYield;
  double? debtToEquity;
  double? eps;
  double? bookValue;
  double? marketCap;
  double? priceToSales;
  double? evEbitda;
  List<CompetitorPeer>? peers;
  double? currentPrice;
  
  // Banking Metrics
  double? nim;
  double? netNpa;
  double? casa;
  
  // Liquidity
  double? quickRatio;

  // Analytics Metrics
  double? currentRatio;
  double? cfoPat;
  double? operatingMarginPercent;
  double? netProfitMarginPercent;
  double? week52High;
  double? week52Low;
  double? priceCagr1Y;
  double? priceCagr3Y;
  double? priceCagr5Y;

  // New Profile / Price Metrics
  String? description;
  double? dayHigh;
  double? dayLow;
  double? dayChange;
  double? dayChangePercent;
  double? sectorMarketCapInr;
  double? sectorMarketCapUsd;

  // Financials & Shareholding dynamic lists
  List<dynamic>? shareholding;
  List<dynamic>? incomeStatement;
  List<dynamic>? balanceSheet;
  List<dynamic>? cashFlow;
  List<dynamic>? corporateActions;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FundamentalRatiosResponse &&
    other.symbol == symbol &&
    other.companyName == companyName &&
    other.sector == sector &&
    other.industry == industry &&
    other.peRatio == peRatio &&
    other.pbRatio == pbRatio &&
    other.roe == roe &&
    other.roce == roce &&
    other.dividendYield == dividendYield &&
    other.debtToEquity == debtToEquity &&
    other.eps == eps &&
    other.bookValue == bookValue &&
    other.marketCap == marketCap &&
    other.priceToSales == priceToSales;

  @override
  int get hashCode =>
    (symbol == null ? 0 : symbol!.hashCode) +
    (companyName == null ? 0 : companyName!.hashCode) +
    (sector == null ? 0 : sector!.hashCode) +
    (industry == null ? 0 : industry!.hashCode) +
    (peRatio == null ? 0 : peRatio!.hashCode) +
    (pbRatio == null ? 0 : pbRatio!.hashCode) +
    (roe == null ? 0 : roe!.hashCode) +
    (roce == null ? 0 : roce!.hashCode) +
    (dividendYield == null ? 0 : dividendYield!.hashCode) +
    (debtToEquity == null ? 0 : debtToEquity!.hashCode) +
    (eps == null ? 0 : eps!.hashCode) +
    (bookValue == null ? 0 : bookValue!.hashCode) +
    (marketCap == null ? 0 : marketCap!.hashCode) +
    (priceToSales == null ? 0 : priceToSales!.hashCode);

  @override
  String toString() => 'FundamentalRatiosResponse[symbol=$symbol, companyName=$companyName, sector=$sector, industry=$industry, peRatio=$peRatio, pbRatio=$pbRatio, roe=$roe, roce=$roce, dividendYield=$dividendYield, debtToEquity=$debtToEquity, eps=$eps, bookValue=$bookValue, marketCap=$marketCap, priceToSales=$priceToSales]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.symbol != null) json[r'symbol'] = this.symbol;
    if (this.companyName != null) json[r'companyName'] = this.companyName;
    if (this.sector != null) json[r'sector'] = this.sector;
    if (this.industry != null) json[r'industry'] = this.industry;
    if (this.peRatio != null) json[r'peRatio'] = this.peRatio;
    if (this.pbRatio != null) json[r'pbRatio'] = this.pbRatio;
    if (this.roe != null) json[r'roe'] = this.roe;
    if (this.roce != null) json[r'roce'] = this.roce;
    if (this.dividendYield != null) json[r'dividendYield'] = this.dividendYield;
    if (this.debtToEquity != null) json[r'debtToEquity'] = this.debtToEquity;
    if (this.eps != null) json[r'eps'] = this.eps;
    if (this.bookValue != null) json[r'bookValue'] = this.bookValue;
    if (this.marketCap != null) json[r'marketCap'] = this.marketCap;
    if (this.priceToSales != null) json[r'priceToSales'] = this.priceToSales;
    return json;
  }

  static FundamentalRatiosResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // The API response has nested objects: { valuation: {...}, profitability: {...} }
      // as well as optional flat fields for backwards compat.
      final valuation = json['valuation'] is Map
          ? (json['valuation'] as Map).cast<String, dynamic>()
          : <String, dynamic>{};
      final profitability = json['profitability'] is Map
          ? (json['profitability'] as Map).cast<String, dynamic>()
          : <String, dynamic>{};
      final company = json['company'] is Map
          ? (json['company'] as Map).cast<String, dynamic>()
          : <String, dynamic>{};
      final analytics = json['analytics'] is Map
          ? (json['analytics'] as Map).cast<String, dynamic>()
          : <String, dynamic>{};
      final financials = json['financials'] is Map
          ? (json['financials'] as Map).cast<String, dynamic>()
          : <String, dynamic>{};

      // Helper to coerce num -> double
      double? num2d(dynamic v) => v is num ? v.toDouble() : null;

      return FundamentalRatiosResponse(
        // Identity fields from company section (unified endpoint) or flat
        symbol: mapValueOfType<String>(json, r'symbol') ??
            mapValueOfType<String>(company, r'symbol'),
        companyName: mapValueOfType<String>(json, r'companyName') ??
            mapValueOfType<String>(company, r'companyName'),
        sector: mapValueOfType<String>(json, r'sector') ??
            mapValueOfType<String>(company, r'sector'),
        industry: mapValueOfType<String>(json, r'industry'),
        
        description: mapValueOfType<String>(json, r'description') ??
            mapValueOfType<String>(company, r'description'),
        dayHigh: num2d(company['dayHigh']) ?? mapValueOfType<double>(json, r'dayHigh'),
        dayLow: num2d(company['dayLow']) ?? mapValueOfType<double>(json, r'dayLow'),
        dayChange: num2d(company['dayChange']) ?? mapValueOfType<double>(json, r'dayChange'),
        dayChangePercent: num2d(company['dayChangePercent']) ?? mapValueOfType<double>(json, r'dayChangePercent'),
        sectorMarketCapInr: num2d(company['sectorMarketCapInr']) ?? mapValueOfType<double>(json, r'sectorMarketCapInr'),
        sectorMarketCapUsd: num2d(company['sectorMarketCapUsd']) ?? mapValueOfType<double>(json, r'sectorMarketCapUsd'),

        // Valuation ratios — try nested 'valuation' first, then flat keys
        peRatio: num2d(valuation['pe']) ?? mapValueOfType<double>(json, r'peRatio'),
        pbRatio: num2d(valuation['pb']) ?? mapValueOfType<double>(json, r'pbRatio'),
        roe: num2d(valuation['roe']) ?? num2d(profitability['roe']) ?? mapValueOfType<double>(json, r'roe'),
        roce: num2d(valuation['roce']) ?? num2d(profitability['roce']) ?? mapValueOfType<double>(json, r'roce'),
        dividendYield: num2d(valuation['dividendYield']) ?? mapValueOfType<double>(json, r'dividendYield'),
        debtToEquity: num2d(valuation['debtToEquity']) ?? mapValueOfType<double>(json, r'debtToEquity'),
        eps: num2d(valuation['eps']) ?? mapValueOfType<double>(json, r'eps'),
        bookValue: num2d(valuation['bookValue']) ?? mapValueOfType<double>(json, r'bookValue'),
        marketCap: num2d(valuation['marketCap']) ?? mapValueOfType<double>(json, r'marketCap'),
        priceToSales: num2d(valuation['priceToSales']) ?? mapValueOfType<double>(json, r'priceToSales'),
        evEbitda: num2d(valuation['evEbitda']) ?? mapValueOfType<double>(json, r'evEbitda'),
        peers: json['peers'] is List ? (json['peers'] as List).map((e) => CompetitorPeer.fromJson(e)).whereType<CompetitorPeer>().toList() : [],
        currentPrice: num2d(company['currentPrice']) ?? mapValueOfType<double>(json, r'currentPrice'),
        
        // Custom parsed banking/analytics fields
        nim: num2d(valuation['nim']),
        netNpa: num2d(valuation['netNpa']),
        casa: num2d(valuation['casa']),
        quickRatio: num2d(valuation['quickRatio']),
        currentRatio: num2d(analytics['currentRatio']),
        cfoPat: num2d(analytics['cfoPat']),
        operatingMarginPercent: num2d(analytics['operatingMarginPercent']),
        netProfitMarginPercent: num2d(analytics['netProfitMarginPercent']),
        week52High: num2d(analytics['week52High']),
        week52Low: num2d(analytics['week52Low']),
        priceCagr1Y: num2d(analytics['priceCagr1Y']),
        priceCagr3Y: num2d(analytics['priceCagr3Y']),
        priceCagr5Y: num2d(analytics['priceCagr5Y']),
        
        // Lists
        shareholding: json['shareholding'] is List ? json['shareholding'] as List : [],
        incomeStatement: financials['incomeStatement'] is List
            ? financials['incomeStatement'] as List
            : (json['incomeStatement'] is List ? json['incomeStatement'] as List : []),
        balanceSheet: financials['balanceSheet'] is List
            ? financials['balanceSheet'] as List
            : (json['balanceSheet'] is List ? json['balanceSheet'] as List : []),
        cashFlow: financials['cashFlow'] is List
            ? financials['cashFlow'] as List
            : (json['cashFlow'] is List ? json['cashFlow'] as List : []),
        corporateActions: json['corporateActions'] is List ? json['corporateActions'] as List : [],
      );
    }
    return null;
  }

  static List<FundamentalRatiosResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FundamentalRatiosResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FundamentalRatiosResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static const requiredKeys = <String>{};
}

class CompetitorPeer {
  String? instrumentKey;
  String? isin;
  String? symbol;
  String? companyName;
  String? sector;
  double? currentPrice;
  double? dayChange;
  double? dayChangePercent;
  double? pe;
  double? pb;
  double? roe;
  double? roce;
  double? roa;
  double? evEbitda;

  String? description;
  double? sectorMarketCapInr;
  double? sectorMarketCapUsd;

  CompetitorPeer({
    this.instrumentKey,
    this.isin,
    this.symbol,
    this.companyName,
    this.sector,
    this.currentPrice,
    this.dayChange,
    this.dayChangePercent,
    this.pe,
    this.pb,
    this.roe,
    this.roce,
    this.roa,
    this.evEbitda,
    this.description,
    this.sectorMarketCapInr,
    this.sectorMarketCapUsd,
  });

  static CompetitorPeer? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();
      double? num2d(dynamic v) => v is num ? v.toDouble() : null;
      return CompetitorPeer(
        instrumentKey: json['instrumentKey']?.toString(),
        isin: json['isin']?.toString(),
        symbol: json['symbol']?.toString(),
        companyName: json['companyName']?.toString(),
        sector: json['sector']?.toString(),
        currentPrice: num2d(json['currentPrice']),
        dayChange: num2d(json['dayChange']),
        dayChangePercent: num2d(json['dayChangePercent']),
        pe: num2d(json['pe']),
        pb: num2d(json['pb']),
        roe: num2d(json['roe']),
        roce: num2d(json['roce']),
        roa: num2d(json['roa']),
        evEbitda: num2d(json['evEbitda']),
        description: json['description']?.toString(),
        sectorMarketCapInr: num2d(json['sectorMarketCapInr']),
        sectorMarketCapUsd: num2d(json['sectorMarketCapUsd']),
      );
    }
    return null;
  }

  static List<CompetitorPeer> listFromJson(dynamic json, {bool growable = false}) {
    final result = <CompetitorPeer>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CompetitorPeer.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}
