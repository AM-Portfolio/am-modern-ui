import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../internal/domain/entities/portfolio_analytics.dart';
import 'intelligence/intelligence_glass_card.dart';
import 'movers_tabs.dart';
import 'movers_tile.dart';

/// Top movers panel — compact arrow tiles; Today / P&L / Cost grouped views.
class MoversWidget extends StatefulWidget {
  const MoversWidget({
    super.key,
    this.movers,
    this.isLoading = false,
    this.error,
    this.onViewAll,
    this.compact = false,
    this.fillHeight = false,
    this.onRetry,
    this.maxRows = 5,
  });
  final Movers? movers;
  final bool isLoading;
  final String? error;
  final ValueChanged<Movers>? onViewAll;
  /// When true, use Gainers|Losers tabs and denser padding (Overview intel).
  final bool compact;
  /// Stretch to peer row height on Overview bottom band.
  final bool fillHeight;
  final VoidCallback? onRetry;
  /// Overview shows 5; See Top 10 shows 10.
  final int maxRows;

  @override
  State<MoversWidget> createState() => _MoversWidgetState();
}

class _MoversWidgetState extends State<MoversWidget> {
  @override
  Widget build(BuildContext context) {
    final showSeeAll = widget.onViewAll != null &&
        widget.movers != null &&
        (widget.movers!.topGainers.isNotEmpty ||
            widget.movers!.topLosers.isNotEmpty);

    return IntelligenceGlassCard(
      title: 'Top Movers',
      icon: Icons.auto_graph_rounded,
      padding: EdgeInsets.all(widget.compact ? 14 : 20),
      fillHeight: widget.fillHeight,
      scrollable: widget.fillHeight,
      trailing: showSeeAll
          ? TextButton(
              onPressed: () => widget.onViewAll!(widget.movers!),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: ModuleColors.portfolio.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'See Top 10',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ModuleColors.portfolio,
                ),
              ),
            )
          : null,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final placeholderH = widget.compact ? 72.0 : 200.0;
    if (widget.isLoading) {
      return SizedBox(
        height: placeholderH,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (widget.error != null) {
      return SizedBox(
        height: placeholderH,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: widget.compact ? 32 : 48),
              const SizedBox(height: 8),
              Text('Failed to load movers data',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14)),
              const SizedBox(height: 4),
              Text(widget.error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12),
                  textAlign: TextAlign.center),
              if (widget.onRetry != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: widget.onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (widget.movers == null) {
      return SizedBox(
        height: placeholderH,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.data_usage_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: widget.compact ? 32 : 48),
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

    return MoversPanelContent(
      movers: widget.movers!,
      compact: widget.compact,
      maxRows: widget.maxRows,
    );
  }
}

/// Gainers/Losers + metric chips + tiles. Shared by Overview and See Top 10.
class MoversPanelContent extends StatefulWidget {
  const MoversPanelContent({
    super.key,
    required this.movers,
    this.compact = false,
    this.maxRows = 5,
    this.forceTabs = false,
  });

  final Movers movers;
  final bool compact;
  final int maxRows;
  /// Modal always uses tabs even on a wide dialog.
  final bool forceTabs;

  @override
  State<MoversPanelContent> createState() => _MoversPanelContentState();
}

class _MoversPanelContentState extends State<MoversPanelContent> {
  bool _showGainers = true;
  MoverMetric _metric = MoverMetric.today;

  @override
  Widget build(BuildContext context) {
    final useTabs = widget.forceTabs ||
        widget.compact ||
        MediaQuery.of(context).size.width < 600;
    final movers = widget.movers;
    final list = _showGainers ? movers.topGainers : movers.topLosers;

    final chips = MoversMetricChips(
      selected: _metric,
      onSelect: (m) => setState(() => _metric = m),
    );

    if (useTabs) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          MoversGainersLosersTabs(
            showGainers: _showGainers,
            gainersCount: movers.topGainers.length,
            losersCount: movers.topLosers.length,
            onSelectGainers: () => setState(() => _showGainers = true),
            onSelectLosers: () => setState(() => _showGainers = false),
          ),
          SizedBox(height: widget.compact ? 6 : 12),
          chips,
          SizedBox(height: widget.compact ? 8 : 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: ValueKey(_showGainers),
              child: _buildColumn(
                context,
                _showGainers ? 'Gainers' : 'Losers',
                list,
                _showGainers,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        chips,
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildColumn(
                context,
                'Gainers',
                movers.topGainers,
                true,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildColumn(
                context,
                'Losers',
                movers.topLosers,
                false,
              ),
            ),
          ],
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
    final color = isGainers
        ? ModuleColors.portfolio
        : context.colors.marketNegativeIndicator;
    final hideTitle = widget.compact || widget.forceTabs;
    final shown = stocks.take(widget.maxRows).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!hideTitle)
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
        if (!hideTitle) const SizedBox(height: 12),
        if (stocks.isEmpty)
          Padding(
            padding:
                EdgeInsets.symmetric(vertical: widget.compact ? 12.0 : 20.0),
            child: Center(
              child: Text(
                'No ${isGainers ? 'gainers' : 'losers'} today',
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
        else ...[
          ...shown.asMap().entries.map(
            (e) => MoverTile(
              stock: e.value,
              isGainer: isGainers,
              metric: _metric,
              isLast: e.key == shown.length - 1,
            ),
          ),
          if (widget.compact && stocks.length < widget.maxRows)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Only ${stocks.length} holding${stocks.length == 1 ? '' : 's'} moved today',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
            ),
        ],
      ],
    );
  }
}
