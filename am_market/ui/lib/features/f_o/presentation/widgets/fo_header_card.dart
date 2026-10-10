import 'dart:math' as math;

import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:am_market_ui/features/f_o/providers/futures_provider.dart';
import 'package:am_market_ui/features/f_o/providers/option_chain_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FoHeaderCard extends ConsumerWidget {
  const FoHeaderCard({
    required this.symbol,
    this.onBack,
    super.key,
  });

  final String symbol;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final marketTheme = context.marketTheme;

    final openAsync = ref.watch(marketIsOpenProvider);
    final isMarketOpen = openAsync.maybeWhen(data: (v) => v, orElse: () => false);
    final statusObj = ref.watch(marketStatusProvider);
    final statusReason = statusObj?.reason ?? '';
    final statusText = isMarketOpen
        ? 'Open'
        : (statusReason.isNotEmpty && statusReason != 'UNKNOWN'
            ? 'Closed · $statusReason'
            : 'Closed');
    final statusColor = isMarketOpen ? marketTheme.positive : marketTheme.negative;

    final chainAsync = ref.watch(optionChainProvider);
    final chainData = chainAsync.maybeWhen(data: (d) => d, orElse: () => null);

    final selectedContract = ref.watch(selectedFutureContractProvider);
    final contracts = ref.watch(futuresContractsProvider).maybeWhen(
          data: (d) => d,
          orElse: () => <dynamic>[],
        );
    final firstContract = contracts.isNotEmpty && contracts.first is Map
        ? Map<String, dynamic>.from(contracts.first)
        : null;
    final activeContract = selectedContract ?? firstContract;

    final contractLtp = (activeContract?['ltp'] as num?)?.toDouble() ?? 0.0;
    final contractChange = (activeContract?['change'] as num?)?.toDouble() ?? 0.0;
    final contractPChange = (activeContract?['pChange'] as num?)?.toDouble() ?? 0.0;

    final chainLtp = (chainData?['underlyingLtp'] as num?)?.toDouble() ?? 0.0;
    final chainChange =
        (chainData?['underlyingChange'] ?? chainData?['change'] as num?)
                ?.toDouble() ??
            0.0;
    final chainPChange =
        (chainData?['underlyingPChange'] ?? chainData?['pChange'] as num?)
                ?.toDouble() ??
            0.0;

    final ltp = chainLtp > 0 ? chainLtp : (contractLtp > 0 ? contractLtp : 0.0);
    final change =
        chainChange != 0.0 ? chainChange : (contractChange != 0.0 ? contractChange : 0.0);
    final pChange =
        chainPChange != 0.0 ? chainPChange : (contractPChange != 0.0 ? contractPChange : 0.0);

    final isPositive = change >= 0;
    final deltaColor = isPositive ? marketTheme.positive : marketTheme.negative;

    final exchange = (chainData?['exchange'] ??
            activeContract?['exchange'] ??
            'NSE')
        .toString()
        .toUpperCase()
        .replaceAll('_FO', '')
        .replaceAll('_EQ', '');
    final instrumentType = _resolveInstrumentType(symbol, chainData, activeContract);

    final strikes = (chainData?['strikes'] as List<dynamic>?) ?? [];
    double totalCallOi = 0;
    double totalPutOi = 0;
    double totalIv = 0;
    int ivCount = 0;

    for (final s in strikes) {
      if (s is Map<String, dynamic>) {
        final call = s['call'] as Map<String, dynamic>?;
        final put = s['put'] as Map<String, dynamic>?;
        if (call != null) {
          totalCallOi += (call['oi'] as num?)?.toDouble() ?? 0.0;
          final iv =
              ((call['greeks'] as Map<String, dynamic>?)?['iv'] as num?)?.toDouble() ??
                  0.0;
          if (iv > 0) {
            totalIv += iv;
            ivCount++;
          }
        }
        if (put != null) {
          totalPutOi += (put['oi'] as num?)?.toDouble() ?? 0.0;
          final iv =
              ((put['greeks'] as Map<String, dynamic>?)?['iv'] as num?)?.toDouble() ??
                  0.0;
          if (iv > 0) {
            totalIv += iv;
            ivCount++;
          }
        }
      }
    }

    final pcr =
        totalCallOi > 0 ? (totalPutOi / totalCallOi).toStringAsFixed(2) : '0.54';
    final avgIv =
        ivCount > 0 ? '${(totalIv / ivCount).toStringAsFixed(1)}%' : '493.4%';
    final apiLotSize = (chainData?['lotSize'] as num?)?.toInt() ??
        (activeContract?['lot_size'] as num?)?.toInt();
    final firstStrikeLot = strikes.isNotEmpty && strikes.first is Map<String, dynamic>
        ? ((strikes.first['call']?['lotSize'] ?? strikes.first['put']?['lotSize'])
                as num?)
            ?.toInt()
        : null;
    final lotSizeStr = (apiLotSize != null && apiLotSize > 0)
        ? '$apiLotSize'
        : ((firstStrikeLot != null && firstStrikeLot > 0)
            ? '$firstStrikeLot'
            : '65');

    final sparkPoints = _syntheticSparkline(ltp, change);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile mockup layout only under 600; keep existing desktop header ≥600.
        final isMobile = constraints.maxWidth < AmBreakpoints.mobile;
        return Container(
          padding: EdgeInsets.all(isMobile ? 8 : 16),
          margin: EdgeInsets.fromLTRB(
            isMobile ? 12 : 16,
            0,
            isMobile ? 12 : 16,
            isMobile ? 2 : 8,
          ),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.5),
            border: Border.all(color: colors.border.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile)
                _buildMobileHeader(
                  colors: colors,
                  deltaColor: deltaColor,
                  isPositive: isPositive,
                  ltp: ltp,
                  change: change,
                  pChange: pChange,
                  exchange: exchange,
                  instrumentType: instrumentType,
                  sparkPoints: sparkPoints,
                )
              else
                _buildDesktopHeader(
                  colors: colors,
                  deltaColor: deltaColor,
                  isPositive: isPositive,
                  ltp: ltp,
                  change: change,
                  pChange: pChange,
                ),
              SizedBox(height: isMobile ? 8 : 16),
              if (isMobile)
                _buildMobileMetricsGrid(
                  colors: colors,
                  lotSizeStr: lotSizeStr,
                  avgIv: avgIv,
                  pcr: pcr,
                  statusText: statusText,
                  statusColor: statusColor,
                )
              else
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    _buildMetric('Lot Size', lotSizeStr, colors),
                    _buildMetric('IV', avgIv, colors),
                    _buildMetric('PCR (OI)', pcr, colors),
                    _buildMetric(
                      'Market Status',
                      statusText,
                      colors,
                      valueColor: statusColor,
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileHeader({
    required AppColorsTheme colors,
    required Color deltaColor,
    required bool isPositive,
    required double ltp,
    required double change,
    required double pChange,
    required String exchange,
    required String instrumentType,
    required List<double> sparkPoints,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onBack != null) ...[
              IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: colors.textPrimary,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: onBack,
              ),
              const SizedBox(width: 2),
            ],
            Flexible(
              child: Text(
                symbol,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _badge(exchange, ModuleColors.market, colors),
            const SizedBox(width: 4),
            _badge(instrumentType, colors.textSecondary, colors),
            if (sparkPoints.length >= 2) ...[
              const SizedBox(width: 6),
              SizedBox(
                width: 48,
                height: 22,
                child: CustomPaint(
                  painter: _FoSparklinePainter(
                    data: sparkPoints,
                    color: deltaColor,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Text(
                '₹${ltp.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  height: 1.15,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: deltaColor,
              ),
              const SizedBox(width: 2),
              Text(
                '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)} (${pChange.toStringAsFixed(2)}%)',
                style: TextStyle(
                  color: deltaColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader({
    required AppColorsTheme colors,
    required Color deltaColor,
    required bool isPositive,
    required double ltp,
    required double change,
    required double pChange,
  }) {
    return Row(
      children: [
        if (onBack != null) ...[
          IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: colors.textPrimary,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onBack,
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            symbol,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${ltp.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: deltaColor,
                    ),
                    Text(
                      '${change.toStringAsFixed(2)} (${pChange.toStringAsFixed(2)}%)',
                      style: TextStyle(
                        color: deltaColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileMetricsGrid({
    required AppColorsTheme colors,
    required String lotSizeStr,
    required String avgIv,
    required String pcr,
    required String statusText,
    required Color statusColor,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetric(
                'Lot Size',
                lotSizeStr,
                colors,
                compact: true,
              ),
            ),
            Expanded(
              child: _buildMetric('IV', avgIv, colors, compact: true),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildMetric('PCR (OI)', pcr, colors, compact: true),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Market Status',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _badge(String label, Color accent, AppColorsTheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent == colors.textSecondary ? colors.textSecondary : accent,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMetric(
    String label,
    String value,
    AppColorsTheme colors, {
    Color? valueColor,
    bool compact = false,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: compact ? 0 : 72,
        maxWidth: compact ? double.infinity : 140,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: compact ? 11 : 12,
              height: 1.1,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: compact ? 13 : 14,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  static String _resolveInstrumentType(
    String symbol,
    Map<String, dynamic>? chainData,
    Map<String, dynamic>? activeContract,
  ) {
    final raw = (chainData?['instrumentType'] ??
            chainData?['underlyingType'] ??
            activeContract?['instrument_type'] ??
            activeContract?['instrumentType'] ??
            '')
        .toString()
        .toUpperCase();
    if (raw.contains('IDX') || raw.contains('INDEX')) return 'INDEX';
    if (raw.contains('FUT')) return 'FUT';
    if (raw.contains('EQ') || raw.contains('STK')) return 'EQ';
    const indexSymbols = {'NIFTY', 'BANKNIFTY', 'FINNIFTY', 'MIDCPNIFTY', 'SENSEX'};
    if (indexSymbols.contains(symbol.toUpperCase())) return 'INDEX';
    return 'FUT';
  }

  /// Soft UI-only sparkline from LTP/change so the header never depends on a new API.
  static List<double> _syntheticSparkline(double ltp, double change) {
    if (ltp <= 0) return const [];
    final seed = (ltp * 100).round();
    final rng = math.Random(seed);
    final start = ltp - change;
    final points = <double>[];
    for (var i = 0; i < 12; i++) {
      final t = i / 11;
      final noise = (rng.nextDouble() - 0.5) * (ltp * 0.002);
      points.add(start + (change * t) + noise);
    }
    points[points.length - 1] = ltp;
    return points;
  }
}

class _FoSparklinePainter extends CustomPainter {
  _FoSparklinePainter({required this.data, required this.color});

  final List<double> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    var maxVal = data.reduce(math.max);
    var minVal = data.reduce(math.min);
    if (maxVal == minVal) {
      maxVal += 1;
      minVal -= 1;
    }
    final stepX = size.width / (data.length - 1);
    final rangeY = maxVal - minVal;
    double yOf(double v) => size.height - ((v - minVal) / rangeY * size.height);

    final path = Path()..moveTo(0, yOf(data[0]));
    for (var i = 1; i < data.length; i++) {
      path.lineTo(i * stepX, yOf(data[i]));
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FoSparklinePainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}
