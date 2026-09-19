import 'package:am_market_common/models/market_info_models.dart';
import 'package:am_market_common/services/api_service.dart';
import 'package:am_market_ui/features/institutional_flows/domain/fii_dii_activity_models.dart';
import 'package:am_market_ui/features/market_analysis/internal/domain/models/institutional_flow_series.dart';

/// Loads FII/DII activity for MoneyControl-style Activity tab.
class FiiDiiActivityPort {
  FiiDiiActivityPort({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<FiiDiiActivityVm> load({
    required FiiDiiPeriod period,
    required FiiDiiSegment segment,
  }) async {
    try {
      final interval = period.apiInterval;
      final results = await Future.wait<Object>([
        _api.fetchFii(
          interval: interval,
          dataTypes: FlowSegments.fiiAll,
        ),
        _api.fetchDii(interval: interval),
        _api.fetchHistoryBatch(
          const ['NIFTY 50'],
          period.niftyHistoryRange,
        ),
      ]);

      final fii = results[0] as InstitutionalFlowResponse;
      final dii = results[1] as InstitutionalFlowResponse;
      final hist = results[2] as Map<String, List<Map<String, dynamic>>>;

      final byDay = mergeFlowDays(fii: fii, dii: dii);
      if (byDay.isEmpty) {
        return const FiiDiiActivityVm(
          error: 'No FII/DII data for this period',
        );
      }

      final closes = niftyClosesFromHistory(hist['NIFTY 50'] ?? const []);
      final buckets = _bucketsFor(period, byDay, closes);
      buckets.sort((a, b) => b.periodStart.compareTo(a.periodStart));

      final cards = [
        for (final b in buckets.take(12))
          FiiDiiSummaryCardVm(
            dateLabel: b.dateLabel,
            nets: b.nets,
            nifty: b.nifty,
          ),
      ];

      return FiiDiiActivityVm(
        cards: cards,
        buckets: buckets,
        rows: buildActivityRows(buckets: buckets, segment: segment),
      );
    } catch (_) {
      return const FiiDiiActivityVm(
        error: 'Unable to load FII/DII activity',
      );
    }
  }

  List<FiiDiiPeriodBucket> _bucketsFor(
    FiiDiiPeriod period,
    Map<DateTime, FlowDayNets> byDay,
    Map<DateTime, double> closes,
  ) {
    switch (period) {
      case FiiDiiPeriod.daily:
        final days = byDay.keys.toList()..sort();
        return [
          for (final d in days)
            FiiDiiPeriodBucket(
              periodStart: d,
              nets: byDay[d]!,
              dateLabel: formatFiiDiiDate(d, period),
              nifty: niftyForPeriod(
                periodStart: d,
                period: period,
                closes: closes,
                sessionsInPeriod: [d],
              ),
            ),
        ];
      case FiiDiiPeriod.weekly:
        final weeks = aggregateFlowWeeks(byDay);
        return [
          for (final w in (weeks.keys.toList()..sort()))
            FiiDiiPeriodBucket(
              periodStart: w,
              nets: weeks[w]!,
              dateLabel: formatFiiDiiDate(w, period),
              nifty: niftyForPeriod(
                periodStart: w,
                period: period,
                closes: closes,
                sessionsInPeriod: byDay.keys
                    .where((d) =>
                        !d.isBefore(w) &&
                        d.isBefore(w.add(const Duration(days: 7))))
                    .toList(),
              ),
            ),
        ];
      case FiiDiiPeriod.monthly:
        final months = aggregateFlowMonths(byDay);
        return [
          for (final m in (months.keys.toList()..sort()))
            FiiDiiPeriodBucket(
              periodStart: m,
              nets: months[m]!,
              dateLabel: formatFiiDiiDate(m, period),
              nifty: niftyForPeriod(
                periodStart: m,
                period: period,
                closes: closes,
                sessionsInPeriod: byDay.keys
                    .where((d) => d.year == m.year && d.month == m.month)
                    .toList(),
              ),
            ),
        ];
      case FiiDiiPeriod.yearly:
        final years = aggregateFlowYears(byDay);
        return [
          for (final y in (years.keys.toList()..sort()))
            FiiDiiPeriodBucket(
              periodStart: y,
              nets: years[y]!,
              dateLabel: formatFiiDiiDate(y, period),
              nifty: niftyForPeriod(
                periodStart: y,
                period: period,
                closes: closes,
                sessionsInPeriod:
                    byDay.keys.where((d) => d.year == y.year).toList(),
              ),
            ),
        ];
    }
  }
}
