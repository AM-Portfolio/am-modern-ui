import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_market_ui/features/f_o/providers/futures_provider.dart';
import 'package:am_market_ui/features/f_o/providers/option_chain_provider.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';
import 'package:am_market_ui/features/watchlists/presentation/widgets/market_watchlist_star.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as legacy_provider;

class FoHeaderCard extends ConsumerStatefulWidget {
  const FoHeaderCard({
    required this.symbol,
    this.onBack,
    super.key,
  });

  final String symbol;
  final VoidCallback? onBack;

  @override
  ConsumerState<FoHeaderCard> createState() => _FoHeaderCardState();
}

class _FoHeaderCardState extends ConsumerState<FoHeaderCard> {
  static final NumberFormat _inr = NumberFormat('#,##,##0.00', 'en_IN');
  static const _missing = '—';
  var _sparkRequested = false;

  @override
  Widget build(BuildContext context) {
    final openAsync = ref.watch(marketIsOpenProvider);
    final isMarketOpen =
        openAsync.maybeWhen(data: (v) => v, orElse: () => false);
    final statusObj = ref.watch(marketStatusProvider);
    final statusReason = statusObj?.reason ?? '';
    final statusText = isMarketOpen ? 'Open' : 'Closed';
    final statusTooltip = !isMarketOpen &&
            statusReason.isNotEmpty &&
            statusReason != 'UNKNOWN'
        ? statusReason
        : null;
    final statusColor =
        isMarketOpen ? context.statusSuccess : context.statusError;

    final chainAsync = ref.watch(optionChainProvider);
    final chainData = chainAsync.maybeWhen(data: (d) => d, orElse: () => null);

    final selectedContract = ref.watch(selectedFutureContractProvider);
    final contracts = ref.watch(futuresContractsProvider).maybeWhen(
          data: (d) => d,
          orElse: () => <dynamic>[],
        );
    final firstContract = contracts.isNotEmpty && contracts.first is Map
        ? Map<String, dynamic>.from(contracts.first as Map)
        : null;
    final activeContract = selectedContract ?? firstContract;

    final chainLtp = _positiveNum(chainData?['underlyingLtp']);
    final contractLtp = _positiveNum(activeContract?['ltp']);
    final ltp = chainLtp ?? contractLtp;

    final chainChange = _readNum(chainData, const [
      'underlyingChange',
      'change',
    ]);
    final chainPChange = _readNum(chainData, const [
      'underlyingPChange',
      'pChange',
    ]);
    final contractChange = _readNum(activeContract, const ['change']);
    final contractPChange = _readNum(activeContract, const ['pChange']);
    final change = chainChange ?? contractChange;
    final pChange = chainPChange ?? contractPChange;

    final isPositive = (change ?? 0) >= 0;
    final deltaColor = isPositive
        ? MarketColors.positive(context)
        : MarketColors.negative(context);

    final exchangeRaw = (chainData?['exchange'] ?? activeContract?['exchange'])
        ?.toString();
    final exchange = (exchangeRaw == null || exchangeRaw.isEmpty)
        ? 'NSE'
        : exchangeRaw
            .toUpperCase()
            .replaceAll('_FO', '')
            .replaceAll('_EQ', '');

    final strikes = (chainData?['strikes'] as List<dynamic>?) ?? [];
    var totalCallOi = 0.0;
    var totalPutOi = 0.0;
    var totalIv = 0.0;
    var ivCount = 0;

    for (final s in strikes) {
      if (s is! Map) continue;
      final row = Map<String, dynamic>.from(s);
      final call = row['call'] is Map
          ? Map<String, dynamic>.from(row['call'] as Map)
          : null;
      final put = row['put'] is Map
          ? Map<String, dynamic>.from(row['put'] as Map)
          : null;
      if (call != null) {
        totalCallOi += (call['oi'] as num?)?.toDouble() ?? 0;
        final iv = _greeksIv(call);
        if (iv != null && iv > 0) {
          totalIv += iv;
          ivCount++;
        }
      }
      if (put != null) {
        totalPutOi += (put['oi'] as num?)?.toDouble() ?? 0;
        final iv = _greeksIv(put);
        if (iv != null && iv > 0) {
          totalIv += iv;
          ivCount++;
        }
      }
    }

    final pcr = totalCallOi > 0
        ? (totalPutOi / totalCallOi).toStringAsFixed(2)
        : _missing;
    final avgIv = ivCount > 0 ? _formatIv(totalIv / ivCount) : _missing;

    final apiLotSize = (chainData?['lotSize'] as num?)?.toInt() ??
        (activeContract?['lot_size'] as num?)?.toInt();
    int? firstStrikeLot;
    if (strikes.isNotEmpty && strikes.first is Map) {
      final first = Map<String, dynamic>.from(strikes.first as Map);
      final call = first['call'] is Map
          ? Map<String, dynamic>.from(first['call'] as Map)
          : null;
      final put = first['put'] is Map
          ? Map<String, dynamic>.from(first['put'] as Map)
          : null;
      firstStrikeLot =
          (call?['lotSize'] as num?)?.toInt() ?? (put?['lotSize'] as num?)?.toInt();
    }
    final lotSizeStr = (apiLotSize != null && apiLotSize > 0)
        ? '$apiLotSize'
        : ((firstStrikeLot != null && firstStrikeLot > 0)
            ? '$firstStrikeLot'
            : _missing);

    final sparkKey = _sparklineIndexKey(widget.symbol);
    MarketProvider? market;
    try {
      market = legacy_provider.Provider.of<MarketProvider>(context);
    } catch (_) {
      market = null;
    }
    final sparkPoints = market?.indexSparklines[sparkKey] ??
        market?.indexSparklines[sparkKey.toUpperCase()] ??
        const <double>[];
    final resolvedMarket = market;
    if (!_sparkRequested &&
        resolvedMarket != null &&
        sparkPoints.length < 2) {
      _sparkRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        resolvedMarket.ensureIndexSparklines([sparkKey]);
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < AmBreakpoints.mobile;
        final twoMetricRows = constraints.maxWidth < 360;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: GlassCard(
            padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
            borderRadius: isMobile ? AppRadii.md : AppRadii.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIdentityRow(
                  context: context,
                  isMobile: isMobile,
                  exchange: exchange,
                  ltp: ltp,
                  change: change,
                  pChange: pChange,
                  isPositive: isPositive,
                  deltaColor: deltaColor,
                  sparkPoints: sparkPoints,
                ),
                SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
                _buildMetrics(
                  context: context,
                  twoRows: twoMetricRows,
                  lotSizeStr: lotSizeStr,
                  avgIv: avgIv,
                  pcr: pcr,
                  statusText: statusText,
                  statusColor: statusColor,
                  statusTooltip: statusTooltip,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIdentityRow({
    required BuildContext context,
    required bool isMobile,
    required String exchange,
    required double? ltp,
    required double? change,
    required double? pChange,
    required bool isPositive,
    required Color deltaColor,
    required List<double> sparkPoints,
  }) {
    final radius = BorderRadius.circular(AppRadii.xs);
    final chipPad = EdgeInsets.symmetric(
      horizontal: AppSpacing.xs,
      vertical: AppSpacing.xxs,
    );
    final chartWidth = isMobile ? 96.0 : 180.0;
    final chartHeight = isMobile ? 48.0 : 64.0;
    final ltpStyle = (isMobile
            ? context.text.pageTitle(compact: true)
            : context.text.pageTitle())
        .copyWith(
      color: context.textPrimary,
      fontWeight: FontWeight.w700,
    );

    final nameStyle = (isMobile
            ? context.text.sectionTitle(compact: true)
            : context.text.pageTitle(compact: true))
        .copyWith(
      color: context.textPrimary,
      fontWeight: FontWeight.w700,
    );
    final nameText = Text(
      _displayName(widget.symbol),
      key: const Key('fo-header-name'),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: nameStyle,
    );
    final chips = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AmToggleChip(
            label: exchange,
            selected: true,
            compact: true,
            accentColor: ModuleColors.market,
            borderRadius: radius,
            contentPadding: chipPad,
          ),
          SizedBox(width: AppSpacing.xs),
          AmToggleChip(
            label: 'FUT',
            selected: false,
            compact: true,
            accentColor: ModuleColors.market,
            borderRadius: radius,
            contentPadding: chipPad,
          ),
        ],
      ),
    );
    final priceRow = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(
            ltp == null ? _missing : '₹${_inr.format(ltp)}',
            style: ltpStyle,
          ),
          if (change != null) ...[
            SizedBox(width: AppSpacing.sm),
            Icon(
              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
              size: AppTypeScale.sm,
              color: deltaColor,
            ),
            SizedBox(width: AppSpacing.xxs),
            Text(
              _formatChange(change, pChange),
              style: context.text.label(compact: true).copyWith(
                    color: deltaColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
    final spark = _SparkInset(
      width: chartWidth,
      height: chartHeight,
      points: sparkPoints,
      color: deltaColor,
      showYLabels: !isMobile,
    );
    final star = MarketWatchlistStar(symbol: widget.symbol);
    final back = widget.onBack == null
        ? null
        : IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: context.textPrimary,
              size: isMobile ? AppTypeScale.h5 : AppTypeScale.h4,
            ),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: widget.onBack,
          );

    if (isMobile) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (back != null) ...[
            back,
            SizedBox(width: AppSpacing.xxs),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: nameText),
                    star,
                  ],
                ),
                SizedBox(height: AppSpacing.xs),
                chips,
                SizedBox(height: AppSpacing.xs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: priceRow),
                    SizedBox(width: AppSpacing.xs),
                    spark,
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (back != null) ...[
          back,
          SizedBox(width: AppSpacing.xxs),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(child: nameText),
                  SizedBox(width: AppSpacing.sm),
                  chips,
                ],
              ),
              SizedBox(height: AppSpacing.xs),
              priceRow,
            ],
          ),
        ),
        SizedBox(width: AppSpacing.xs),
        spark,
        SizedBox(width: AppSpacing.xs),
        star,
      ],
    );
  }

  Widget _buildMetrics({
    required BuildContext context,
    required bool twoRows,
    required String lotSizeStr,
    required String avgIv,
    required String pcr,
    required String statusText,
    required Color statusColor,
    String? statusTooltip,
  }) {
    final cells = [
      _MetricCell(
        icon: Icons.inventory_2_outlined,
        label: 'Lot Size',
        value: lotSizeStr,
      ),
      _MetricCell(
        icon: Icons.show_chart,
        label: 'IV',
        value: avgIv,
      ),
      _MetricCell(
        key: const Key('fo-metric-pcr'),
        icon: Icons.bar_chart,
        label: 'PCR (OI)',
        value: pcr,
      ),
      _MetricCell(
        key: const Key('fo-metric-status'),
        icon: Icons.schedule,
        label: 'Market Status',
        value: statusText,
        valueColor: statusColor,
        tooltip: statusTooltip,
      ),
    ];

    if (twoRows) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cells[0]),
              Expanded(child: cells[1]),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: cells[2]),
              Expanded(child: cells[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (final cell in cells) Expanded(child: cell),
      ],
    );
  }

  static String _displayName(String symbol) {
    final s = symbol.trim().toUpperCase();
    return switch (s) {
      'NIFTY' => 'NIFTY 50',
      'BANKNIFTY' => 'NIFTY BANK',
      'FINNIFTY' => 'NIFTY FIN',
      'MIDCPNIFTY' => 'NIFTY MIDCAP',
      _ => s,
    };
  }

  static String _sparklineIndexKey(String symbol) {
    final s = symbol.trim().toUpperCase();
    if (s == 'NIFTY') return 'NIFTY 50';
    if (s == 'BANKNIFTY') return 'NIFTY BANK';
    return s;
  }

  static double? _positiveNum(dynamic raw) {
    if (raw is! num) return null;
    final v = raw.toDouble();
    return v > 0 ? v : null;
  }

  static double? _readNum(Map<String, dynamic>? data, List<String> keys) {
    if (data == null) return null;
    for (final key in keys) {
      if (!data.containsKey(key) || data[key] == null) continue;
      final raw = data[key];
      if (raw is num) return raw.toDouble();
    }
    return null;
  }

  static double? _greeksIv(Map<String, dynamic> side) {
    final greeks = side['greeks'];
    if (greeks is! Map) return null;
    final iv = greeks['iv'];
    return iv is num ? iv.toDouble() : null;
  }

  static String _formatIv(double avg) {
    var value = avg;
    if (value > 0 && value <= 1) {
      value *= 100;
    }
    return '${value.toStringAsFixed(1)}%';
  }

  static String _formatChange(double change, double? pChange) {
    final sign = change > 0 ? '+' : '';
    final amount = '$sign${change.toStringAsFixed(2)}';
    if (pChange == null) return amount;
    final pSign = pChange > 0 ? '+' : '';
    return '$amount ($pSign${pChange.toStringAsFixed(2)}%)';
  }
}

class _SparkInset extends StatelessWidget {
  const _SparkInset({
    required this.width,
    required this.height,
    required this.points,
    required this.color,
    this.showYLabels = true,
  });

  final double width;
  final double height;
  final List<double> points;
  final Color color;
  final bool showYLabels;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('fo-header-chart'),
      width: width,
      height: height,
      padding: EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: points.length < 2
          ? const SizedBox.shrink()
          : AmSparklineChart(
              data: points,
              color: color,
              fill: true,
              lastDot: true,
              showYLabels: showYLabels,
              midlineColor: context.colors.border,
            ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final cell = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: AppTypeScale.base,
              color: context.textSecondary,
            ),
            SizedBox(width: AppSpacing.xxs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.caption(compact: true).copyWith(
                      color: context.textSecondary,
                    ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.label(compact: true).copyWith(
                color: valueColor ?? context.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
    final message = tooltip;
    if (message == null || message.isEmpty) return cell;
    return Tooltip(message: message, child: cell);
  }
}
