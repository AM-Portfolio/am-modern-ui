import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../internal/domain/entities/portfolio_analytics.dart';
import 'intelligence/intelligence_glass_card.dart';
import 'movers_tabs.dart';
import 'movers_tile.dart';

/// Top movers panel — Value | Percentage on totals; Gainers / Losers by
/// portfolio day contribution.
class MoversWidget extends StatefulWidget {
  const MoversWidget({
    super.key,
    this.movers,
    this.isLoading = false,
    this.error,
    this.compact = false,
    this.fillHeight = false,
    this.onRetry,
    this.maxRows = 5,
  });
  final Movers? movers;
  final bool isLoading;
  final String? error;
  /// When true, denser padding (Overview intel).
  final bool compact;
  /// Stretch to peer row height on Overview bottom band.
  final bool fillHeight;
  final VoidCallback? onRetry;
  /// Overview shows 5 rows.
  final int maxRows;

  @override
  State<MoversWidget> createState() => _MoversWidgetState();
}

class _MoversWidgetState extends State<MoversWidget> {
  bool _showGainers = true;
  MoversDisplayMode _mode = MoversDisplayMode.value;

  @override
  Widget build(BuildContext context) {
    final trailing = widget.movers == null
        ? null
        : MoversDisplayModeToggle(
            selected: _mode,
            onSelect: (m) => setState(() => _mode = m),
          );

    return IntelligenceGlassCard(
      title: 'Top Movers',
      subtitle: null,
      icon: Icons.auto_graph_rounded,
      padding: EdgeInsets.all(widget.compact ? 14 : 20),
      fillHeight: widget.fillHeight,
      // Peer band needs a bounded column; scrolling here would give unbounded
      // height and break Expanded.
      scrollable: false,
      trailing: trailing,
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
      fillHeight: widget.fillHeight,
      showGainers: _showGainers,
      onShowGainersChanged: (v) => setState(() => _showGainers = v),
      mode: _mode,
      onModeChanged: (m) => setState(() => _mode = m),
    );
  }
}

/// Gainers/Losers tabs + Value/% total column. Shared by Overview.
class MoversPanelContent extends StatefulWidget {
  const MoversPanelContent({
    super.key,
    required this.movers,
    this.compact = false,
    this.maxRows = 5,
    this.fillHeight = false,
    this.showGainers,
    this.onShowGainersChanged,
    this.mode,
    this.onModeChanged,
  });

  final Movers movers;
  final bool compact;
  final int maxRows;
  final bool fillHeight;
  final bool? showGainers;
  final ValueChanged<bool>? onShowGainersChanged;
  final MoversDisplayMode? mode;
  final ValueChanged<MoversDisplayMode>? onModeChanged;

  @override
  State<MoversPanelContent> createState() => _MoversPanelContentState();
}

class _MoversPanelContentState extends State<MoversPanelContent> {
  bool _localShowGainers = true;
  MoversDisplayMode _localMode = MoversDisplayMode.value;

  bool get _showGainers => widget.showGainers ?? _localShowGainers;
  MoversDisplayMode get _mode => widget.mode ?? _localMode;

  void _setShowGainers(bool value) {
    widget.onShowGainersChanged?.call(value);
    if (widget.showGainers == null) {
      setState(() => _localShowGainers = value);
    }
  }

  void _setMode(MoversDisplayMode mode) {
    widget.onModeChanged?.call(mode);
    if (widget.mode == null) {
      setState(() => _localMode = mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movers = widget.movers;
    final list = _showGainers ? movers.topGainers : movers.topLosers;

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toggle lives in card trailing when hosted by [MoversWidget]; when
        // used standalone (tests/modal), show it here if mode is uncontrolled
        // with no parent trailing — only when parent did not pass [mode].
        if (widget.mode == null) ...[
          Align(
            alignment: Alignment.centerRight,
            child: MoversDisplayModeToggle(
              selected: _mode,
              onSelect: _setMode,
            ),
          ),
          SizedBox(height: widget.compact ? 6 : 10),
        ],
        MoversGainersLosersTabs(
          showGainers: _showGainers,
          onSelectGainers: () => _setShowGainers(true),
          onSelectLosers: () => _setShowGainers(false),
        ),
        SizedBox(height: widget.compact ? 8 : 16),
      ],
    );

    final listBody = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: KeyedSubtree(
        key: ValueKey('${_showGainers}_$_mode'),
        child: _buildColumn(context, list, _showGainers),
      ),
    );

    if (!widget.fillHeight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [header, listBody],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Expanded(child: listBody),
      ],
    );
  }

  Widget _buildColumn(
    BuildContext context,
    List<Stock> stocks,
    bool isGainers,
  ) {
    final shown = stocks.take(widget.maxRows).toList();
    if (stocks.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: widget.compact ? 12.0 : 20.0),
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
      );
    }

    if (widget.fillHeight) {
      // Always [maxRows] equal slots so five rows fill the card with no
      // stretched gaps between tiles and no empty pocket under the list.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < widget.maxRows; i++)
            Expanded(
              child: i < shown.length
                  ? MoverTile(
                      stock: shown[i],
                      isGainer: isGainers,
                      mode: _mode,
                      compact: widget.compact,
                      isLast: i == shown.length - 1,
                      fillSlot: true,
                    )
                  : const SizedBox.expand(),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < shown.length; i++)
          MoverTile(
            stock: shown[i],
            isGainer: isGainers,
            mode: _mode,
            compact: widget.compact,
            isLast: i == shown.length - 1,
          ),
      ],
    );
  }
}
