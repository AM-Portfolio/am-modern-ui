import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';
import 'package:am_market_ui/features/market_analysis/presentation/widgets/heatmap_filters.dart';

/// Canonical Market index heatmap — dashboard-style symbol+% cards with paging.
///
/// Used by the Market dashboard and Chart terminal. Avoids GridView aspect
/// squeeze that caused mobile tile overflow banners.
class IndexHeatmapPanel extends StatefulWidget {
  const IndexHeatmapPanel({
    super.key,
    required this.indexSymbol,
    required this.timeframe,
    this.pageSize = 40,
    this.onSelectStock,
    this.embedCompact = false,
    this.showPercentFilters = false,
    this.title,
  });

  final String indexSymbol;
  final String timeframe;
  final int pageSize;
  final ValueChanged<String>? onSelectStock;

  /// Tighter header for Chart dock embeds.
  final bool embedCompact;

  /// Optional % range chips (Chart embed).
  final bool showPercentFilters;

  /// Override header title; default `Heatmap: {indexSymbol}`.
  final String? title;

  @override
  State<IndexHeatmapPanel> createState() => _IndexHeatmapPanelState();
}

class _IndexHeatmapPanelState extends State<IndexHeatmapPanel> {
  int _page = 0;
  int _requestId = 0;
  bool _loading = false;
  List<MapEntry<String, double>> _entries = const [];
  String? _percentFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void didUpdateWidget(covariant IndexHeatmapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.indexSymbol != widget.indexSymbol ||
        oldWidget.timeframe != widget.timeframe) {
      _page = 0;
      _percentFilter = null;
      _reload();
    }
  }

  Future<void> _reload() async {
    final symbol = widget.indexSymbol.trim();
    if (symbol.isEmpty) return;
    final id = ++_requestId;
    setState(() => _loading = true);
    try {
      final entries = await context
          .read<MarketProvider>()
          .loadDashboardIndexHeatmap(symbol, widget.timeframe);
      if (!mounted || id != _requestId) return;
      setState(() {
        _entries = entries;
        _loading = false;
        _page = 0;
      });
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _entries = const [];
        _loading = false;
      });
    }
  }

  List<MapEntry<String, double>> get _filtered {
    final f = _percentFilter;
    if (f == null) return _entries;
    return _entries.where((e) {
      final p = e.value;
      switch (f) {
        case 'Above +5%':
          return p > 5;
        case '+2 to +5%':
          return p >= 2 && p <= 5;
        case '0 to +2%':
          return p >= 0 && p < 2;
        case '0 to -2%':
          return p < 0 && p >= -2;
        case '-2 to -5%':
          return p < -2 && p >= -5;
        case 'Below -5%':
          return p < -5;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final total = filtered.length;
    final window = dashboardHeatmapPageWindow(
      total: total,
      page: _page,
      pageSize: widget.pageSize,
    );
    final safePage = total == 0 ? 0 : _page.clamp(0, window.pageCount - 1);
    if (safePage != _page) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _page = safePage);
      });
    }
    final pageItems = total == 0
        ? const <MapEntry<String, double>>[]
        : filtered.sublist(window.start, window.end);

    final headerPad = widget.embedCompact
        ? const EdgeInsets.fromLTRB(10, 6, 10, 4)
        : const EdgeInsets.fromLTRB(14, 10, 12, 8);
    final titleStyle = TextStyle(
      color: MarketColors.textPrimary(context),
      fontSize: widget.embedCompact ? 13 : 14,
      fontWeight: FontWeight.bold,
    );

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: headerPad,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title ?? 'Heatmap: ${widget.indexSymbol}',
                  style: titleStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (total > 0)
                Text(
                  '$total stocks',
                  style: TextStyle(
                    color: MarketColors.textMuted(context),
                    fontSize: 11,
                  ),
                ),
              if (_loading) ...[
                const SizedBox(width: 10),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
        if (widget.showPercentFilters)
          HeatmapFilters(
            percentFilter: _percentFilter,
            onPercentFilterChanged: (val) {
              setState(() {
                _percentFilter = val;
                _page = 0;
              });
            },
            title: null,
          ),
        if (_loading && _entries.isEmpty)
          const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_entries.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
            child: Text(
              'No heatmap data for ${widget.indexSymbol}',
              style: TextStyle(color: MarketColors.textMuted(context)),
            ),
          )
        else if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
            child: Text(
              'No stocks match this filter',
              style: TextStyle(color: MarketColors.textMuted(context)),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount =
                    (constraints.maxWidth / 110).floor().clamp(3, 10);
                final rows = _chunk(pageItems, crossAxisCount);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var r = 0; r < rows.length; r++) ...[
                      if (r > 0) const SizedBox(height: 6),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var c = 0; c < rows[r].length; c++) ...[
                              if (c > 0) const SizedBox(width: 6),
                              Expanded(
                                child: IndexHeatmapTile(
                                  symbol: rows[r][c].key,
                                  value: rows[r][c].value,
                                  onTap: widget.onSelectStock == null
                                      ? null
                                      : () => widget
                                          .onSelectStock!(rows[r][c].key),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        if (total > widget.pageSize)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: safePage > 0
                      ? () => setState(() => _page = safePage - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left, size: 20),
                  color: MarketColors.textPrimary(context),
                  disabledColor: MarketColors.textMuted(context),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Previous page',
                ),
                Expanded(
                  child: Text(
                    '${window.start + 1}–${window.end} of $total  ·  Page ${safePage + 1} / ${window.pageCount}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: MarketColors.textMuted(context),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: safePage < window.pageCount - 1
                      ? () => setState(() => _page = safePage + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right, size: 20),
                  color: MarketColors.textPrimary(context),
                  disabledColor: MarketColors.textMuted(context),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Next page',
                ),
              ],
            ),
          ),
      ],
    );

    if (widget.embedCompact) {
      return SingleChildScrollView(child: body);
    }
    return body;
  }

  List<List<MapEntry<String, double>>> _chunk(
    List<MapEntry<String, double>> items,
    int size,
  ) {
    if (items.isEmpty || size <= 0) return const [];
    final rows = <List<MapEntry<String, double>>>[];
    for (var i = 0; i < items.length; i += size) {
      rows.add(items.sublist(i, (i + size).clamp(0, items.length)));
    }
    return rows;
  }
}

/// Overflow-safe symbol + % card (minHeight 56, no GridView aspect squeeze).
class IndexHeatmapTile extends StatelessWidget {
  const IndexHeatmapTile({
    super.key,
    required this.symbol,
    required this.value,
    this.onTap,
  });

  final String symbol;
  final double value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent;
    final Color fill;
    if (value > 0) {
      accent = MarketColors.positive(context);
      fill = MarketColors.positiveBg(context);
    } else if (value < 0) {
      accent = MarketColors.negative(context);
      fill = MarketColors.negativeBg(context);
    } else {
      accent = MarketColors.textMuted(context);
      fill = MarketColors.cardSurface(context);
    }

    final child = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            symbol,
            style: TextStyle(
              color: MarketColors.textPrimary(context),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${value > 0 ? '+' : ''}${value.toStringAsFixed(2)}%',
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}
