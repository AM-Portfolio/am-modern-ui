import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';

/// Dashboard index heatmap with Analysis-style tiles (symbol + %, green/red).
///
/// For large indices (NIFTY 500) loads **all constituents** and pages them
/// (default 40 / page) so every stock is reachable.
class DashboardAnalysisHeatmapPanel extends StatefulWidget {
  const DashboardAnalysisHeatmapPanel({
    super.key,
    required this.indexSymbol,
    required this.timeframe,
    this.pageSize = 40,
  });

  final String indexSymbol;
  final String timeframe;
  final int pageSize;

  @override
  State<DashboardAnalysisHeatmapPanel> createState() =>
      _DashboardAnalysisHeatmapPanelState();
}

class _DashboardAnalysisHeatmapPanelState
    extends State<DashboardAnalysisHeatmapPanel> {
  int _page = 0;
  int _requestId = 0;
  bool _loading = false;
  List<MapEntry<String, double>> _entries = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void didUpdateWidget(covariant DashboardAnalysisHeatmapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.indexSymbol != widget.indexSymbol ||
        oldWidget.timeframe != widget.timeframe) {
      _page = 0;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = _entries.length;
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
        : _entries.sublist(window.start, window.end);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Heatmap: ${widget.indexSymbol}',
                  style: TextStyle(
                    color: MarketColors.textPrimary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
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
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount =
                    (constraints.maxWidth / 110).floor().clamp(4, 10);
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
                                child: _AnalysisHeatmapCard(
                                  symbol: rows[r][c].key,
                                  value: rows[r][c].value,
                                  isDark: isDark,
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

/// Same visual language as Market Analysis heatmap cards.
class _AnalysisHeatmapCard extends StatelessWidget {
  const _AnalysisHeatmapCard({
    required this.symbol,
    required this.value,
    required this.isDark,
  });

  final String symbol;
  final double value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    late final Color cardColor;
    late final Color textColor;
    if (value > 0) {
      cardColor = const Color(0xFF47E266);
      textColor = const Color(0xFF47E266);
    } else if (value < 0) {
      cardColor = const Color(0xFFFFB4AB);
      textColor = const Color(0xFFFFB4AB);
    } else {
      cardColor = const Color(0xFF918FA0);
      textColor = const Color(0xFF918FA0);
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            symbol,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
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
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
