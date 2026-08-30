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
      return FundamentalRatiosResponse(
        symbol: mapValueOfType<String>(json, r'symbol'),
        companyName: mapValueOfType<String>(json, r'companyName'),
        sector: mapValueOfType<String>(json, r'sector'),
        industry: mapValueOfType<String>(json, r'industry'),
        peRatio: mapValueOfType<double>(json, r'peRatio'),
        pbRatio: mapValueOfType<double>(json, r'pbRatio'),
        roe: mapValueOfType<double>(json, r'roe'),
        roce: mapValueOfType<double>(json, r'roce'),
        dividendYield: mapValueOfType<double>(json, r'dividendYield'),
        debtToEquity: mapValueOfType<double>(json, r'debtToEquity'),
        eps: mapValueOfType<double>(json, r'eps'),
        bookValue: mapValueOfType<double>(json, r'bookValue'),
        marketCap: mapValueOfType<double>(json, r'marketCap'),
        priceToSales: mapValueOfType<double>(json, r'priceToSales'),
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
