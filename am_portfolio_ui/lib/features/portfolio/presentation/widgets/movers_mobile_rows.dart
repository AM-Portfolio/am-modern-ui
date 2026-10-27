// Unused backup of the phone-width table rows. Do not delete.
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../internal/domain/entities/portfolio_analytics.dart';
import 'movers_join.dart';
import 'movers_table_cells.dart';

enum _MobileMetric { ltp, value, pnl, invested }

/// Phone-width Top Movers: identity + qty left, one metric right.
class MoversMobileRows extends StatefulWidget {
  const MoversMobileRows({
    super.key,
    required this.stocks,
    required this.showCost,
  });

  final List<Stock> stocks;
  final bool showCost;

  @override
  State<MoversMobileRows> createState() => _MoversMobileRowsState();
}

class _MoversMobileRowsState extends State<MoversMobileRows> {
  _MobileMetric _metric = _MobileMetric.ltp;

  @override
  void didUpdateWidget(covariant MoversMobileRows oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.showCost && _metric == _MobileMetric.invested) {
      _metric = _MobileMetric.ltp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = <_MobileMetric>[
      _MobileMetric.ltp,
      _MobileMetric.value,
      _MobileMetric.pnl,
      if (widget.showCost) _MobileMetric.invested,
    ];

    return Column(
      children: [
        _MobileMetricChips(
          metrics: metrics,
          selected: _metric,
          onSelect: (m) => setState(() => _metric = m),
        ),
        const SizedBox(height: 10),
        ...widget.stocks.map(
          (s) => _MobileMoverRow(
            stock: s,
            metric: _metric,
          ),
        ),
      ],
    );
  }
}

class _MobileMetricChips extends StatelessWidget {
  const _MobileMetricChips({
    required this.metrics,
    required this.selected,
    required this.onSelect,
  });

  final List<_MobileMetric> metrics;
  final _MobileMetric selected;
  final ValueChanged<_MobileMetric> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.colors.marketBorderDefault.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final m in metrics)
            Expanded(
              child: _MetricChip(
                label: _label(m),
                selected: selected == m,
                onTap: () => onSelect(m),
              ),
            ),
        ],
      ),
    );
  }

  static String _label(_MobileMetric m) {
    switch (m) {
      case _MobileMetric.ltp:
        return 'LTP';
      case _MobileMetric.value:
        return 'Value';
      case _MobileMetric.pnl:
        return 'P&L';
      case _MobileMetric.invested:
        return 'Invested';
    }
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.color
        ?.withValues(alpha: 0.5);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 32),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? ModuleColors.portfolio : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileMoverRow extends StatelessWidget {
  const _MobileMoverRow({
    required this.stock,
    required this.metric,
  });

  final Stock stock;
  final _MobileMetric metric;

  @override
  Widget build(BuildContext context) {
    final sector = moverSubtitle(stock);
    final qty = (stock.quantity != null && stock.quantity! > 0)
        ? formatMoverQty(stock.quantity!)
        : null;
    final leftSub = [
      if (qty != null) qty,
      if (sector != null) sector,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: context.colors.surface.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  MoverSymbolAvatar(symbol: stock.symbol, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            stock.symbol,
                            maxLines: 1,
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                          ),
                        ),
                        if (leftSub.isNotEmpty)
                          Text(
                            leftSub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: KeyedSubtree(
                    key: ValueKey(metric),
                    child: _metricView(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricView(BuildContext context) {
    switch (metric) {
      case _MobileMetric.ltp:
        return _LtpMetric(stock: stock);
      case _MobileMetric.value:
        return _PlainMetric(
          primary: stock.marketValue != null && stock.marketValue! > 0
              ? formatMoverInr(stock.marketValue!)
              : '—',
        );
      case _MobileMetric.pnl:
        return MoverPnlChip(
          amount: moverDisplayPnl(stock),
          percent: moverDisplayPnlPercent(stock),
          compact: true,
          minWidth: 0,
        );
      case _MobileMetric.invested:
        final invested = stock.hasCostBasis && stock.investedAmount != null
            ? formatMoverInr(stock.investedAmount!)
            : '—';
        final avg = stock.hasCostBasis && stock.avgPrice != null
            ? '${formatMoverInr(stock.avgPrice!)} avg'
            : null;
        return _PlainMetric(primary: invested, secondary: avg);
    }
  }
}

class _LtpMetric extends StatelessWidget {
  const _LtpMetric({required this.stock});

  final Stock stock;

  @override
  Widget build(BuildContext context) {
    final ltp = stock.lastPrice > 0 ? formatMoverInr(stock.lastPrice) : '—';
    final dayColor = stock.changePercent > 0.005
        ? context.colors.marketPositiveIndicator
        : stock.changePercent < -0.005
            ? context.colors.marketNegativeIndicator
            : Theme.of(context).colorScheme.onSurfaceVariant;
    final dayPct = stock.lastPrice > 0 &&
            (stock.changeAmount != 0 || stock.changePercent != 0)
        ? formatSignedPct(stock.changePercent)
        : null;
    return _PlainMetric(
      primary: ltp,
      secondary: dayPct,
      secondaryColor: dayColor,
    );
  }
}

class _PlainMetric extends StatelessWidget {
  const _PlainMetric({
    required this.primary,
    this.secondary,
    this.secondaryColor,
  });

  final String primary;
  final String? secondary;
  final Color? secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            primary,
            maxLines: 1,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
          ),
        ),
        if (secondary != null)
          Text(
            secondary!,
            maxLines: 1,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: secondaryColor ??
                  Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
