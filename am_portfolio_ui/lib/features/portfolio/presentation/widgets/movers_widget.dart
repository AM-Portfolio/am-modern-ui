import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart' as ds;
import '../../internal/domain/entities/portfolio_analytics.dart';

/// Top movers panel — Gainers left, Losers right.
/// Each tile uses the Stitch design: colored squircle arrow + ticker + price + pill badge.
class MoversWidget extends StatelessWidget {
  const MoversWidget({
    super.key,
    this.movers,
    this.isLoading = false,
    this.error,
    this.onViewAll,
  });
  final Movers? movers;
  final bool isLoading;
  final String? error;
  final ValueChanged<Movers>? onViewAll;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0D1B2A).withValues(alpha: 0.9),
                      const Color(0xFF0A1628).withValues(alpha: 0.75),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.92),
                      const Color(0xFFF5F7FF).withValues(alpha: 0.8),
                    ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.07 : 0.4),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.auto_graph_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Top Movers',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                  ),
                  const Spacer(),
                  if (onViewAll != null && movers != null && (movers!.topGainers.length > 5 || movers!.topLosers.length > 5))
                    TextButton(
                      onPressed: () => onViewAll!(movers!),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        'See Top 10',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (error != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  color: Theme.of(context).colorScheme.error, size: 48),
              const SizedBox(height: 8),
              Text('Failed to load movers data',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14)),
              const SizedBox(height: 4),
              Text(error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (movers == null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.data_usage_outlined,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                  size: 48),
              const SizedBox(height: 8),
              Text('No movers data available',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child:
              _buildColumn(context, 'Gainers', movers!.topGainers, true),
        ),
        const SizedBox(width: 20),
        Expanded(
          child:
              _buildColumn(context, 'Losers', movers!.topLosers, false),
        ),
      ],
    );
  }

  Widget _buildColumn(
    BuildContext context,
    String title,
    List<Stock> stocks,
    bool isGainers,
  ) {
    final color = isGainers ? ds.AppColors.profit : ds.AppColors.loss;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isGainers
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: color,
              size: 15,
            ),
            const SizedBox(width: 5),
            Text(
              '$title (${stocks.length})',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: color,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (stocks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Text(
                'No ${isGainers ? 'gainers' : 'losers'} found',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ),
          )
        else
          ...stocks.take(5).map(
            (stock) => MoverTile(stock: stock, isGainer: isGainers),
          ),
      ],
    );
  }
}

class MoverTile extends StatefulWidget {
  final Stock stock;
  final bool isGainer;
  const MoverTile({super.key, required this.stock, required this.isGainer});

  @override
  State<MoverTile> createState() => _MoverTileState();
}

class _MoverTileState extends State<MoverTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        widget.isGainer ? ds.AppColors.profit : ds.AppColors.loss;
    final stock = widget.stock;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        transform: _hovered
            ? (Matrix4.diagonal3Values(1.015, 1.015, 1.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: _hovered
              ? color.withValues(alpha: isDark ? 0.08 : 0.05)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.025)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered
                ? color.withValues(alpha: 0.35)
                : color.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.12),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // ── Squircle directional icon ──
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                widget.isGainer
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 14,
                color: color,
              ),
            ),
            const SizedBox(width: 8),

            // ── Ticker ──
            Expanded(
              child: Text(
                stock.symbol,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ── Price ──
            Text(
              '₹${stock.lastPrice.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.75)
                        : Colors.black.withValues(alpha: 0.65),
                  ),
            ),
            const SizedBox(width: 8),

            // ── Percentage pill with glow ──
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.16 : 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 6,
                    spreadRadius: -1,
                  ),
                ],
              ),
              child: Text(
                '${stock.changePercent >= 0 ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
