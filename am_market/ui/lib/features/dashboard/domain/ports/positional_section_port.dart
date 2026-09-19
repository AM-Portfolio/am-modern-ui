import 'package:am_market_common/models/market_info_models.dart';
import 'package:am_market_common/services/api_service.dart';
import 'package:am_market_ui/features/dashboard/domain/dashboard_section_id.dart';
import 'package:am_market_ui/features/dashboard/domain/dashboard_section_port.dart';
import 'package:am_market_ui/features/dashboard/domain/section_view_model.dart';
import 'package:am_market_ui/features/market_analysis/internal/domain/models/institutional_flow_series.dart';

class PositionalSectionPort implements DashboardSectionPort {
  PositionalSectionPort({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  @override
  DashboardSectionId get id => DashboardSectionId.positional;

  @override
  Future<SectionViewModel> load({
    required String timeframe,
    String? focusedIndex,
  }) async {
    final symbol = (focusedIndex == null || focusedIndex.isEmpty)
        ? 'NIFTY 50'
        : focusedIndex;
    final flowInterval = flowsIntervalForTf(timeframe);
    final changeOiInterval = switch (timeframe.toUpperCase()) {
      '1D' => 1,
      '1W' => 5,
      _ => 30,
    };

    OiData? oi;
    ChangeOiData? change;
    InstitutionalFlowResponse? fii;
    InstitutionalFlowResponse? dii;
    try {
      final results = await Future.wait<Object?>([
        _api.fetchOi(symbol: symbol),
        _api.fetchChangeOi(symbol: symbol, interval: changeOiInterval),
        _api.fetchFii(
          interval: flowInterval,
          dataTypes: const [
            FlowSegments.cash,
            FlowSegments.indexFutures,
            FlowSegments.indexOptions,
          ],
        ),
        _api.fetchDii(interval: flowInterval),
      ]);
      oi = results[0] as OiData?;
      change = results[1] as ChangeOiData?;
      fii = results[2] as InstitutionalFlowResponse?;
      dii = results[3] as InstitutionalFlowResponse?;
    } catch (_) {
      return const SectionViewModel(
        stripEmpty: true,
        moversEmpty: true,
        lower: SectionLowerVm(
          isEmpty: true,
          message: 'No session flow for this timeframe',
        ),
      );
    }

    final byDay = mergeFlowDays(fii: fii, dii: dii);
    final strip = <SectionStripItem>[];
    if (oi != null) {
      strip.add(SectionStripItem(
        id: 'oi_pcr',
        label: 'OI PCR',
        valueText: oi.pcr.toStringAsFixed(2),
        signedValue: oi.pcr - 1,
      ));
    }
    if (change != null) {
      strip.add(SectionStripItem(
        id: 'chg_pcr',
        label: 'Chg PCR',
        valueText: change.changePcr.toStringAsFixed(2),
        signedValue: change.changePcr,
      ));
    }
    String exact(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}';
    final latestDay = byDay.isEmpty
        ? null
        : (byDay.keys.toList()..sort()).last;
    final nets = latestDay == null ? null : byDay[latestDay];
    if (nets != null) {
      strip.addAll([
        SectionStripItem(
          id: 'fii_cash',
          label: 'FII cash',
          valueText: exact(nets.fiiCash),
          signedValue: nets.fiiCash,
        ),
        SectionStripItem(
          id: 'dii_cash',
          label: 'DII cash',
          valueText: exact(nets.diiCash),
          signedValue: nets.diiCash,
        ),
        SectionStripItem(
          id: 'fii_fut',
          label: 'FII fut',
          valueText: exact(nets.fiiFutures),
          signedValue: nets.fiiFutures,
        ),
        SectionStripItem(
          id: 'fii_opt',
          label: 'FII opt',
          valueText: exact(nets.fiiOptions),
          signedValue: nets.fiiOptions,
        ),
      ]);
    }

    final lower = _buildLower(
      byDay: byDay,
      timeframe: timeframe,
      oi: oi,
      change: change,
    );

    final flowMovers = _flowMovers(byDay);

    return SectionViewModel(
      stripItems: strip,
      chartSpec: const SectionChartSpec(
        showFiiCash: true,
        showDiiCash: true,
        showFiiFutures: true,
        showFiiOptions: true,
      ),
      gainers: flowMovers.$1,
      losers: flowMovers.$2,
      stripEmpty: strip.isEmpty,
      moversEmpty: flowMovers.$1.isEmpty && flowMovers.$2.isEmpty,
      lower: lower,
    );
  }

  SectionLowerVm _buildLower({
    required Map<DateTime, FlowDayNets> byDay,
    required String timeframe,
    OiData? oi,
    ChangeOiData? change,
  }) {
    if (byDay.isEmpty) {
      return const SectionLowerVm(
        isEmpty: true,
        message: 'No session flow for this timeframe',
      );
    }

    final monthly = positioningUsesMonthlyCards(timeframe);
    if (monthly) {
      final byMonth = aggregateFlowMonths(byDay);
      final months = byMonth.keys.toList()..sort();
      final year = months.last.year;
      final yearMonths = months.where((m) => m.year == year).toList();
      final metrics = <String, List<SectionMetricRow>>{};
      for (final m in yearMonths) {
        metrics[SectionLowerVm.monthKey(m)] =
            _metricsFor(byMonth[m]!, oi, change);
      }
      final heatmap = <String, double>{
        for (final m in yearMonths)
          SectionLowerVm.monthKey(m):
              byMonth[m]!.fiiCash + byMonth[m]!.diiCash,
      };
      return SectionLowerVm(
        sessionDays: yearMonths,
        dayMetrics: metrics,
        heatmapValues: heatmap,
        isEmpty: yearMonths.isEmpty,
      );
    }

    final sorted = byDay.keys.toList()..sort();
    final sessions = visibleFlowDays(sorted, timeframe)
        .where(byDay.containsKey)
        .toList();
    final metrics = <String, List<SectionMetricRow>>{};
    for (final d in sessions) {
      metrics[SectionLowerVm.dayKey(d)] = _metricsFor(byDay[d]!, oi, change);
    }
    final heatmap = <String, double>{
      for (final d in sessions)
        SectionLowerVm.dayKey(d): byDay[d]!.fiiCash + byDay[d]!.diiCash,
    };
    return SectionLowerVm(
      sessionDays: sessions,
      dayMetrics: metrics,
      heatmapValues: heatmap,
      isEmpty: sessions.isEmpty,
      message: sessions.isEmpty ? 'No session flow for this timeframe' : null,
    );
  }

  List<SectionMetricRow> _metricsFor(
    FlowDayNets nets,
    OiData? oi,
    ChangeOiData? change,
  ) {
    String exact(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}';
    final rows = <SectionMetricRow>[];
    if (oi != null) {
      rows.add(SectionMetricRow(
        label: 'OI PCR',
        text: oi.pcr.toStringAsFixed(2),
        value: oi.pcr - 1,
      ));
    }
    if (change != null) {
      rows.add(SectionMetricRow(
        label: 'Chg PCR',
        text: change.changePcr.toStringAsFixed(2),
        value: change.changePcr,
      ));
    }
    rows.addAll([
      SectionMetricRow(
        label: 'FII cash',
        text: exact(nets.fiiCash),
        value: nets.fiiCash,
      ),
      SectionMetricRow(
        label: 'DII cash',
        text: exact(nets.diiCash),
        value: nets.diiCash,
      ),
      SectionMetricRow(
        label: 'FII fut',
        text: exact(nets.fiiFutures),
        value: nets.fiiFutures,
      ),
      SectionMetricRow(
        label: 'FII opt',
        text: exact(nets.fiiOptions),
        value: nets.fiiOptions,
      ),
    ]);
    return rows;
  }

  (List<SectionMoverItem>, List<SectionMoverItem>) _flowMovers(
    Map<DateTime, FlowDayNets> byDay,
  ) {
    if (byDay.isEmpty) return (const [], const []);
    final days = byDay.keys.toList()..sort();
    final scored = [
      for (final d in days)
        (
          d: d,
          net: byDay[d]!.fiiCash + byDay[d]!.diiCash,
        ),
    ]..sort((a, b) => b.net.compareTo(a.net));

    SectionMoverItem item(({DateTime d, double net}) e) {
      final label =
          '${e.d.day.toString().padLeft(2, '0')}/${e.d.month.toString().padLeft(2, '0')}';
      return SectionMoverItem(
        symbol: label,
        name: 'Session $label',
        ltp: e.net,
        change: e.net,
        pChange: e.net,
      );
    }

    final leaders = scored.where((e) => e.net > 0).take(5).map(item).toList();
    final laggards =
        scored.reversed.where((e) => e.net < 0).take(5).map(item).toList();
    return (leaders, laggards);
  }
}
