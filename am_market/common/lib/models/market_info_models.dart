double _doubleValue(Map<String, dynamic> json, String snake, String camel) {
  final value = json[snake] ?? json[camel];
  return value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}

int _intValue(Map<String, dynamic> json, String snake, String camel) {
  final value = json[snake] ?? json[camel];
  return value is num ? value.toInt() : int.tryParse('$value') ?? 0;
}

class InstitutionalFlowRecord {
  const InstitutionalFlowRecord({
    required this.timeStamp,
    required this.buyAmount,
    required this.sellAmount,
    required this.buyContracts,
    required this.sellContracts,
    required this.oiContracts,
    required this.oiAmount,
    required this.totalLongContracts,
    required this.totalShortContracts,
    required this.totalCallLongContracts,
    required this.totalPutLongContracts,
    required this.totalCallShortContracts,
    required this.totalPutShortContracts,
  });

  factory InstitutionalFlowRecord.fromJson(Map<String, dynamic> json) {
    return InstitutionalFlowRecord(
      timeStamp: _intValue(json, 'time_stamp', 'timeStamp'),
      buyAmount: _doubleValue(json, 'buy_amount', 'buyAmount'),
      sellAmount: _doubleValue(json, 'sell_amount', 'sellAmount'),
      buyContracts: _intValue(json, 'buy_contracts', 'buyContracts'),
      sellContracts: _intValue(json, 'sell_contracts', 'sellContracts'),
      oiContracts: _intValue(json, 'oi_contracts', 'oiContracts'),
      oiAmount: _doubleValue(json, 'oi_amount', 'oiAmount'),
      totalLongContracts:
          _intValue(json, 'total_long_contracts', 'totalLongContracts'),
      totalShortContracts:
          _intValue(json, 'total_short_contracts', 'totalShortContracts'),
      totalCallLongContracts: _intValue(
        json,
        'total_call_long_contracts',
        'totalCallLongContracts',
      ),
      totalPutLongContracts: _intValue(
        json,
        'total_put_long_contracts',
        'totalPutLongContracts',
      ),
      totalCallShortContracts: _intValue(
        json,
        'total_call_short_contracts',
        'totalCallShortContracts',
      ),
      totalPutShortContracts: _intValue(
        json,
        'total_put_short_contracts',
        'totalPutShortContracts',
      ),
    );
  }

  final int timeStamp;
  final double buyAmount;
  final double sellAmount;
  final int buyContracts;
  final int sellContracts;
  final int oiContracts;
  final double oiAmount;
  final int totalLongContracts;
  final int totalShortContracts;
  final int totalCallLongContracts;
  final int totalPutLongContracts;
  final int totalCallShortContracts;
  final int totalPutShortContracts;

  double get netAmount => buyAmount - sellAmount;

  DateTime get time => DateTime.fromMillisecondsSinceEpoch(timeStamp);
}

class InstitutionalFlowResponse {
  const InstitutionalFlowResponse({
    required this.status,
    required this.data,
  });

  factory InstitutionalFlowResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final data = <String, List<InstitutionalFlowRecord>>{};
    if (rawData is Map) {
      rawData.forEach((key, value) {
        if (value is List) {
          data['$key'] = value
              .whereType<Map>()
              .map(
                (row) => InstitutionalFlowRecord.fromJson(
                  Map<String, dynamic>.from(row),
                ),
              )
              .toList();
        }
      });
    }
    return InstitutionalFlowResponse(
      status: '${json['status'] ?? ''}',
      data: data,
    );
  }

  final String status;
  final Map<String, List<InstitutionalFlowRecord>> data;

  InstitutionalFlowRecord? latestFor(String segment) {
    final rows = data[segment];
    if (rows == null || rows.isEmpty) return null;
    return rows.reduce((a, b) => a.timeStamp >= b.timeStamp ? a : b);
  }
}

class OiStrikeRow {
  const OiStrikeRow({
    required this.strikePrice,
    required this.callOi,
    required this.putOi,
    required this.callChangeOi,
    required this.putChangeOi,
  });

  factory OiStrikeRow.fromJson(Map<String, dynamic> json) {
    return OiStrikeRow(
      strikePrice: _doubleValue(json, 'strike_price', 'strikePrice'),
      callOi: _intValue(json, 'call_oi', 'callOi'),
      putOi: _intValue(json, 'put_oi', 'putOi'),
      callChangeOi: _intValue(json, 'call_change_oi', 'callChangeOi'),
      putChangeOi: _intValue(json, 'put_change_oi', 'putChangeOi'),
    );
  }

  final double strikePrice;
  final int callOi;
  final int putOi;
  final int callChangeOi;
  final int putChangeOi;
}

class OiData {
  const OiData({
    required this.totalPuts,
    required this.totalCalls,
    required this.spotClosingPrice,
    required this.expiry,
    required this.rows,
  });

  factory OiData.fromJson(Map<String, dynamic> json) {
    final rawRows = json['call_put_oi_data_list'] ?? json['callPutOiDataList'];
    return OiData(
      totalPuts: _intValue(json, 'total_puts', 'totalPuts'),
      totalCalls: _intValue(json, 'total_calls', 'totalCalls'),
      spotClosingPrice:
          _doubleValue(json, 'spot_closing_price', 'spotClosingPrice'),
      expiry: '${json['expiry'] ?? ''}',
      rows: rawRows is List
          ? rawRows
              .whereType<Map>()
              .map(
                (row) => OiStrikeRow.fromJson(Map<String, dynamic>.from(row)),
              )
              .toList()
          : const [],
    );
  }

  final int totalPuts;
  final int totalCalls;
  final double spotClosingPrice;
  final String expiry;
  final List<OiStrikeRow> rows;

  double get pcr => totalCalls == 0 ? 0 : totalPuts / totalCalls;
}

class ChangeOiData {
  const ChangeOiData({
    required this.totalPutChangeOi,
    required this.totalCallChangeOi,
    required this.spotClosingPrice,
    required this.expiry,
    required this.rows,
  });

  factory ChangeOiData.fromJson(Map<String, dynamic> json) {
    final rawRows = json['call_put_oi_data_list'] ?? json['callPutOiDataList'];
    return ChangeOiData(
      totalPutChangeOi:
          _intValue(json, 'total_put_change_oi', 'totalPutChangeOi'),
      totalCallChangeOi:
          _intValue(json, 'total_call_change_oi', 'totalCallChangeOi'),
      spotClosingPrice:
          _doubleValue(json, 'spot_closing_price', 'spotClosingPrice'),
      expiry: '${json['expiry'] ?? ''}',
      rows: rawRows is List
          ? rawRows
              .whereType<Map>()
              .map(
                (row) => OiStrikeRow.fromJson(Map<String, dynamic>.from(row)),
              )
              .toList()
          : const [],
    );
  }

  final int totalPutChangeOi;
  final int totalCallChangeOi;
  final double spotClosingPrice;
  final String expiry;
  final List<OiStrikeRow> rows;

  double get changePcr =>
      totalCallChangeOi == 0 ? 0 : totalPutChangeOi / totalCallChangeOi;
}

class OiSummary {
  const OiSummary({
    required this.symbol,
    required this.instrumentKey,
    required this.totalCalls,
    required this.totalPuts,
    required this.spot,
    required this.expiry,
    required this.pcr,
  });

  factory OiSummary.fromJson(Map<String, dynamic> json) {
    return OiSummary(
      symbol: '${json['symbol'] ?? ''}',
      instrumentKey: '${json['instrument_key'] ?? json['instrumentKey'] ?? ''}',
      totalCalls: _intValue(json, 'total_calls', 'totalCalls'),
      totalPuts: _intValue(json, 'total_puts', 'totalPuts'),
      spot: _doubleValue(json, 'spot', 'spot'),
      expiry: '${json['expiry'] ?? ''}',
      pcr: _doubleValue(json, 'pcr', 'pcr'),
    );
  }

  final String symbol;
  final String instrumentKey;
  final int totalCalls;
  final int totalPuts;
  final double spot;
  final String expiry;
  final double pcr;
}

class FlowsOverview {
  const FlowsOverview({
    required this.interval,
    required this.fii,
    required this.dii,
    required this.oi,
  });

  factory FlowsOverview.fromJson(Map<String, dynamic> json) {
    final rawFii = json['fii'];
    final rawDii = json['dii'];
    final rawOi = json['oi'];
    return FlowsOverview(
      interval: '${json['interval'] ?? '1D'}',
      fii: InstitutionalFlowResponse.fromJson(
        rawFii is Map ? Map<String, dynamic>.from(rawFii) : const {},
      ),
      dii: InstitutionalFlowResponse.fromJson(
        rawDii is Map ? Map<String, dynamic>.from(rawDii) : const {},
      ),
      oi: rawOi is List
          ? rawOi
              .whereType<Map>()
              .map(
                (value) => OiSummary.fromJson(
                  Map<String, dynamic>.from(value),
                ),
              )
              .toList()
          : const [],
    );
  }

  final String interval;
  final InstitutionalFlowResponse fii;
  final InstitutionalFlowResponse dii;
  final List<OiSummary> oi;
}
