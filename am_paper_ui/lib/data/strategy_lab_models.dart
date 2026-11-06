/// DTOs for am-strategy-lab backtest + report APIs.
class StrategyLabDoc {
  const StrategyLabDoc({
    required this.strategyId,
    this.label,
    this.version = 1,
    this.definition = const {},
  });

  final String strategyId;
  final String? label;
  final int version;
  final Map<String, dynamic> definition;

  factory StrategyLabDoc.fromJson(Map<String, dynamic> json) {
    return StrategyLabDoc(
      strategyId: (json['strategyId'] ?? '').toString(),
      label: json['label']?.toString(),
      version: (json['version'] as num?)?.toInt() ?? 1,
      definition: Map<String, dynamic>.from(
        (json['definition'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}

class StrategyLabTemplate {
  const StrategyLabTemplate({
    required this.strategyId,
    required this.label,
    required this.supported,
    required this.raw,
  });

  final String strategyId;
  final String label;
  final bool supported;
  final Map<String, dynamic> raw;

  factory StrategyLabTemplate.fromJson(Map<String, dynamic> json) {
    return StrategyLabTemplate(
      strategyId: (json['strategyId'] ?? '').toString(),
      label: (json['label'] ?? json['strategyId'] ?? '').toString(),
      supported: json['supported'] == true,
      raw: Map<String, dynamic>.from(json),
    );
  }

  /// Payload shape accepted by POST /v1/strategies.
  Map<String, dynamic> toUpsertBody() {
    const skip = {
      'persona',
      'supported',
      'minLayers',
      'maxLayers',
      'defaults',
      'label',
      'version',
    };
    final definition = <String, dynamic>{};
    raw.forEach((k, v) {
      if (!skip.contains(k)) definition[k] = v;
    });
    definition['strategyId'] = strategyId;

    // LINE / SUPER need a seed price; Lab aligns it onto market bars if outside range.
    final rule = definition['orderRule'];
    if (rule is Map && rule['price'] == null) {
      definition['orderRule'] = {
        ...Map<String, dynamic>.from(rule),
        'price': 2500.0,
      };
    }

    return {
      'strategyId': strategyId,
      'version': raw['version'] ?? 1,
      'label': label,
      'definition': definition,
    };
  }
}

class BacktestJob {
  const BacktestJob({
    required this.jobId,
    required this.strategyId,
    required this.status,
    required this.symbol,
    required this.fromDate,
    required this.toDate,
    required this.timeframe,
    this.error,
  });

  final String jobId;
  final String strategyId;
  final String status;
  final String symbol;
  final String fromDate;
  final String toDate;
  final String timeframe;
  final String? error;

  bool get isTerminal => status == 'DONE' || status == 'FAILED';

  factory BacktestJob.fromJson(Map<String, dynamic> json) {
    return BacktestJob(
      jobId: (json['jobId'] ?? '').toString(),
      strategyId: (json['strategyId'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      symbol: (json['symbol'] ?? '').toString(),
      fromDate: (json['fromDate'] ?? json['from'] ?? '').toString(),
      toDate: (json['toDate'] ?? json['to'] ?? '').toString(),
      timeframe: (json['timeframe'] ?? '').toString(),
      error: json['error']?.toString(),
    );
  }
}

class ReportSummary {
  const ReportSummary({
    required this.totalPnl,
    required this.trades,
    required this.winRate,
    this.avgEntryPrice,
    this.avgEntryVolume,
  });

  final double totalPnl;
  final int trades;
  final double winRate;
  final double? avgEntryPrice;
  final double? avgEntryVolume;

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      totalPnl: (json['totalPnl'] as num?)?.toDouble() ?? 0,
      trades: (json['trades'] as num?)?.toInt() ?? 0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0,
      avgEntryPrice: (json['avgEntryPrice'] as num?)?.toDouble(),
      avgEntryVolume: (json['avgEntryVolume'] as num?)?.toDouble(),
    );
  }
}

class CalendarBucket {
  const CalendarBucket({
    required this.date,
    required this.pnl,
    required this.trades,
    required this.winRate,
  });

  final String date;
  final double pnl;
  final int trades;
  final double winRate;

  factory CalendarBucket.fromJson(Map<String, dynamic> json) {
    return CalendarBucket(
      date: (json['date'] ?? '').toString(),
      pnl: (json['pnl'] as num?)?.toDouble() ?? 0,
      trades: (json['trades'] as num?)?.toInt() ?? 0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TradeFillRow {
  const TradeFillRow({
    required this.ts,
    required this.side,
    required this.qty,
    required this.price,
    required this.kind,
    this.pnl,
    this.layerIndex,
  });

  final String ts;
  final String side;
  final double qty;
  final double price;
  final String kind;
  final double? pnl;
  final int? layerIndex;

  factory TradeFillRow.fromJson(Map<String, dynamic> json) {
    return TradeFillRow(
      ts: (json['ts'] ?? '').toString(),
      side: (json['side'] ?? '').toString(),
      qty: (json['qty'] as num?)?.toDouble() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      kind: (json['kind'] ?? '').toString(),
      pnl: (json['pnl'] as num?)?.toDouble(),
      layerIndex: (json['layerIndex'] as num?)?.toInt(),
    );
  }
}

class BacktestReport {
  const BacktestReport({
    required this.summary,
    required this.calendar,
    required this.trades,
    this.barsSource,
    this.barsNote,
  });

  final ReportSummary summary;
  final Map<String, List<CalendarBucket>> calendar;
  final List<TradeFillRow> trades;
  final String? barsSource;
  final String? barsNote;

  bool get hasBarsNote => barsNote != null && barsNote!.trim().isNotEmpty;

  factory BacktestReport.fromJson(Map<String, dynamic> json) {
    final calRaw = (json['calendar'] as Map?)?.cast<String, dynamic>() ?? {};
    final calendar = <String, List<CalendarBucket>>{};
    calRaw.forEach((k, v) {
      final list = (v as List?) ?? const [];
      calendar[k] = list
          .whereType<Map>()
          .map((e) => CalendarBucket.fromJson(e.cast<String, dynamic>()))
          .toList();
    });
    final trades = ((json['trades'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => TradeFillRow.fromJson(e.cast<String, dynamic>()))
        .toList();
    return BacktestReport(
      summary: ReportSummary.fromJson(
        Map<String, dynamic>.from(
          (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
      ),
      calendar: calendar,
      trades: trades,
      barsSource: json['barsSource']?.toString(),
      barsNote: json['barsNote']?.toString(),
    );
  }
}
