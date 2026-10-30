import 'package:flutter/material.dart';

/// User-facing copy for Stress β vs NIFTY 50. Chip numbers must match this sheet.
class StressBetaHowWeCalculate {
  static const title = 'How we calculate β';

  static const formula =
      'β = Covariance(your daily returns, NIFTY 50 daily returns) '
      '÷ Variance(NIFTY 50 daily returns)';

  static const meaningLine =
      'β says how much your stocks and ETFs tend to move when NIFTY 50 moves.';

  static String chipTooltip({
    required bool assumed,
    required bool warming,
    required String benchmark,
    required double? betaUsed,
    required int? historyDays,
  }) {
    if (warming) {
      return 'Measuring how your stocks and ETFs move vs NIFTY 50…';
    }
    if (assumed) {
      return 'Not enough complete days yet (need 20). '
          'Index scenarios use β 1.00 until history loads.';
    }
    final betaStr = betaUsed == null ? '—' : betaUsed.toStringAsFixed(2);
    final daysPart = (historyDays != null && historyDays > 0)
        ? '$historyDays trading days'
        : 'available days';
    return 'β $betaStr vs NIFTY 50 from $daysPart.\n'
        'If NIFTY moves 1%, this sleeve has tended to move $betaStr%.';
  }

  static String impactExample({
    required double? betaUsed,
    required double? equityWeightPct,
    required int? historyDays,
    required bool assumed,
  }) {
    final beta = assumed ? 1.0 : (betaUsed ?? 1.0);
    final sleeve = equityWeightPct ?? 70.0;
    final days = (historyDays != null && historyDays > 0) ? historyDays : 40;
    final pct = (sleeve / 100.0) * (-10.0) * beta;
    return 'Example: stocks+ETFs ${sleeve.toStringAsFixed(0)}% of the book, '
        'β ${beta.toStringAsFixed(2)}, $days trading days, NIFTY −10% → '
        'about ${pct.toStringAsFixed(1)}% of the whole portfolio '
        '(cash and funds are not shocked).';
  }
}

Future<void> showStressBetaHowWeCalculate(
  BuildContext context, {
  required bool assumed,
  required double? betaUsed,
  required int? historyDays,
  required double? equityWeightPct,
}) {
  final theme = Theme.of(context);
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text(StressBetaHowWeCalculate.title),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  StressBetaHowWeCalculate.meaningLine,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  StressBetaHowWeCalculate.formula,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Included: shares and listed ETFs (including Nifty/Bank/Gold ETFs).\n'
                  'Not included: cash, bonds, commodities, mutual funds, F&O.\n'
                  'Benchmark: NIFTY 50 only. Sensex and event rows use this NIFTY β as an estimate.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  assumed
                      ? 'Showing β 1.00 until we have 20 complete trading days vs NIFTY 50.'
                      : StressBetaHowWeCalculate.impactExample(
                          betaUsed: betaUsed,
                          equityWeightPct: equityWeightPct,
                          historyDays: historyDays,
                          assumed: assumed,
                        ),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sector rows (Banking, IT) ignore β — they only shock names in that sector.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
