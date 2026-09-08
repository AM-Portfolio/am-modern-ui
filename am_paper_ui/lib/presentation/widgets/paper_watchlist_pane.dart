import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/paper_market_client.dart';
import '../../data/quote_models.dart';
import '../../data/watchlist_models.dart';

typedef WatchlistSideCallback = void Function(String symbol, String side);

/// Session watchlist: search via Market SDK, hover shows B/S, depth expands below row.
class PaperWatchlistPane extends StatefulWidget {
  const PaperWatchlistPane({
    super.key,
    required this.selectedSymbol,
    required this.onSelectSymbol,
    required this.onBuySell,
  });

  final String selectedSymbol;
  final ValueChanged<String> onSelectSymbol;
  final WatchlistSideCallback onBuySell;

  @override
  State<PaperWatchlistPane> createState() => _PaperWatchlistPaneState();
}

class _PaperWatchlistPaneState extends State<PaperWatchlistPane> {
  final _client = PaperMarketClient();
  final _searchController = TextEditingController();
  final List<WatchlistStock> _rows = [];
  String? _hoveredSymbol;
  String? _expandedDepthSymbol;
  QuoteDetail? _depthQuote;
  bool _depthLoading = false;
  bool _refreshing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addSymbol(String raw) async {
    final symbol = raw.trim().toUpperCase();
    if (symbol.isEmpty) return;

    WatchlistStock? existing;
    for (final r in _rows) {
      if (r.symbol == symbol) {
        existing = r;
        break;
      }
    }
    if (existing != null) {
      widget.onSelectSymbol(symbol);
      return;
    }

    final docs = await _client.search(symbol, limit: 1);
    WatchlistStock row;
    if (docs != null && docs.isNotEmpty) {
      final match = docs.firstWhere(
        (d) => (d.key?.symbol ?? '').toUpperCase() == symbol,
        orElse: () => docs.first,
      );
      row = _client.stockFromDocument(match);
      if (row.symbol.isEmpty) {
        row = _client.stockFromSymbol(symbol);
      }
    } else {
      row = _client.stockFromSymbol(symbol);
    }

    setState(() {
      _rows.insert(0, row);
    });
    widget.onSelectSymbol(row.symbol);
    await _refreshQuotes();
  }

  Future<void> _refreshQuotes() async {
    if (_rows.isEmpty || _refreshing) return;
    setState(() => _refreshing = true);
    final enriched = await _client.enrichQuotes(List.of(_rows));
    if (!mounted) return;
    setState(() {
      _rows
        ..clear()
        ..addAll(enriched);
      _refreshing = false;
    });
  }

  void _remove(String symbol) {
    setState(() {
      _rows.removeWhere((r) => r.symbol == symbol);
      if (_hoveredSymbol == symbol) _hoveredSymbol = null;
      if (_expandedDepthSymbol == symbol) {
        _expandedDepthSymbol = null;
        _depthQuote = null;
      }
    });
  }

  Future<void> _toggleDepth(WatchlistStock stock) async {
    widget.onSelectSymbol(stock.symbol);
    if (_expandedDepthSymbol == stock.symbol) {
      setState(() {
        _expandedDepthSymbol = null;
        _depthQuote = null;
        _depthLoading = false;
      });
      return;
    }
    setState(() {
      _expandedDepthSymbol = stock.symbol;
      _depthQuote = null;
      _depthLoading = true;
    });
    final detail = await _client.fetchQuoteDetail(
      stock.symbol,
      name: stock.name,
    );
    if (!mounted) return;
    if (_expandedDepthSymbol != stock.symbol) return;
    setState(() {
      _depthQuote = detail;
      _depthLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Text(
                  'Watchlist',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (_refreshing)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.actionPrimaryBg,
                    ),
                  )
                else
                  IconButton(
                    tooltip: 'Refresh quotes',
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    onPressed: _rows.isEmpty ? null : _refreshQuotes,
                    icon: Icon(Icons.refresh, color: colors.textSecondary),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SmartSearchAnchor(
              controller: _searchController,
              compact: true,
              hintText: 'Search stocks',
              category: 'STOCKS',
              accentColor: colors.actionPrimaryBg,
              searchHandler: (q) => _client.search(q),
              onSelected: (sym) {
                _searchController.clear();
                _addSymbol(sym);
              },
              onSubmit: () {
                final q = _searchController.text;
                _searchController.clear();
                _addSymbol(q);
              },
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: colors.divider),
          Expanded(
            child: _rows.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Search by symbol or name to add stocks',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _rows.length,
                    itemBuilder: (context, index) {
                      final stock = _rows[index];
                      final selected =
                          stock.symbol == widget.selectedSymbol.toUpperCase();
                      final hovered = _hoveredSymbol == stock.symbol;
                      final expanded = _expandedDepthSymbol == stock.symbol;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (index > 0)
                            Divider(height: 1, color: colors.divider),
                          _WatchlistRow(
                            stock: stock,
                            selected: selected,
                            showActions: hovered || selected || expanded,
                            depthExpanded: expanded,
                            onHover: (h) => setState(
                              () => _hoveredSymbol = h ? stock.symbol : null,
                            ),
                            onTap: () => widget.onSelectSymbol(stock.symbol),
                            onBuy: () =>
                                widget.onBuySell(stock.symbol, 'BUY'),
                            onSell: () =>
                                widget.onBuySell(stock.symbol, 'SELL'),
                            onDepth: () => _toggleDepth(stock),
                            onRemove: () => _remove(stock.symbol),
                          ),
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: _DepthExpandPanel(
                              loading: _depthLoading && expanded,
                              quote: expanded ? _depthQuote : null,
                              fallbackName: stock.name,
                            ),
                            crossFadeState: expanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _WatchlistRow extends StatelessWidget {
  const _WatchlistRow({
    required this.stock,
    required this.selected,
    required this.showActions,
    required this.depthExpanded,
    required this.onHover,
    required this.onTap,
    required this.onBuy,
    required this.onSell,
    required this.onDepth,
    required this.onRemove,
  });

  final WatchlistStock stock;
  final bool selected;
  final bool showActions;
  final bool depthExpanded;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;
  final VoidCallback onBuy;
  final VoidCallback onSell;
  final VoidCallback onDepth;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final priceColor = stock.isNegative
        ? colors.statusError
        : stock.isPositive
            ? colors.marketPositiveIndicator
            : colors.textPrimary;
    final fmt = NumberFormat('#,##0.00');

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: Material(
        color: selected || depthExpanded
            ? colors.actionPrimaryBg.withValues(alpha: 0.08)
            : colors.surface,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stock.exchange,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                if (showActions)
                  _ActionToolbar(
                    depthExpanded: depthExpanded,
                    onBuy: onBuy,
                    onSell: onSell,
                    onDepth: onDepth,
                    onRemove: onRemove,
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            stock.ltp > 0 ? fmt.format(stock.ltp) : '—',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: priceColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (stock.ltp > 0) ...[
                            const SizedBox(width: 4),
                            Icon(
                              stock.isNegative
                                  ? Icons.arrow_drop_down
                                  : Icons.arrow_drop_up,
                              size: 18,
                              color: priceColor,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        stock.ltp > 0
                            ? '${fmt.format(stock.change)} (${stock.changePercent.toStringAsFixed(2)}%)'
                            : '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: priceColor,
                            ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionToolbar extends StatelessWidget {
  const _ActionToolbar({
    required this.depthExpanded,
    required this.onBuy,
    required this.onSell,
    required this.onDepth,
    required this.onRemove,
  });

  final bool depthExpanded;
  final VoidCallback onBuy;
  final VoidCallback onSell;
  final VoidCallback onDepth;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Sq(
          label: 'B',
          bg: colors.marketPositiveIndicator,
          onTap: onBuy,
        ),
        const SizedBox(width: 4),
        _Sq(
          label: 'S',
          bg: colors.statusError,
          onTap: onSell,
        ),
        const SizedBox(width: 2),
        IconButton(
          tooltip: 'Chart',
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          onPressed: () {},
          icon: Icon(Icons.show_chart, color: colors.textSecondary),
        ),
        IconButton(
          tooltip: depthExpanded ? 'Hide depth' : 'Depth',
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          onPressed: onDepth,
          icon: Icon(
            Icons.candlestick_chart_outlined,
            color: depthExpanded
                ? colors.actionPrimaryBg
                : colors.textSecondary,
          ),
        ),
        IconButton(
          tooltip: 'Remove',
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          onPressed: onRemove,
          icon: Icon(Icons.close, color: colors.actionPrimaryBg),
        ),
      ],
    );
  }
}

class _DepthExpandPanel extends StatelessWidget {
  const _DepthExpandPanel({
    required this.loading,
    required this.quote,
    required this.fallbackName,
  });

  final bool loading;
  final QuoteDetail? quote;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fmt = NumberFormat('#,##0.00');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.scaffoldBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.divider),
      ),
      child: loading
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.actionPrimaryBg,
                  ),
                ),
              ),
            )
          : quote == null
              ? Text(
                  'Unable to load quote',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      quote!.name ?? fallbackName,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _Stat(
                          label: 'LTP',
                          value: quote!.ltp > 0 ? fmt.format(quote!.ltp) : '—',
                        ),
                        _Stat(
                          label: 'Open',
                          value: quote!.open != null
                              ? fmt.format(quote!.open)
                              : '—',
                        ),
                        _Stat(
                          label: 'Prev close',
                          value: quote!.previousClose != null
                              ? fmt.format(quote!.previousClose)
                              : '—',
                        ),
                        _Stat(
                          label: 'High',
                          value: quote!.high != null
                              ? fmt.format(quote!.high)
                              : '—',
                        ),
                        _Stat(
                          label: 'Low',
                          value:
                              quote!.low != null ? fmt.format(quote!.low) : '—',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Market depth',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 6),
                    if (!quote!.hasDepth)
                      Text(
                        'Depth unavailable for this symbol',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                      )
                    else
                      _DepthTable(quote: quote!, fmt: fmt),
                  ],
                ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 88,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _DepthTable extends StatelessWidget {
  const _DepthTable({required this.quote, required this.fmt});

  final QuoteDetail quote;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rows = quote.buyDepth.length > quote.sellDepth.length
        ? quote.buyDepth.length
        : quote.sellDepth.length;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Bid qty',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                'Bid',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.marketPositiveIndicator,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ask',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.statusError,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                'Ask qty',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (var i = 0; i < rows; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    i < quote.buyDepth.length
                        ? '${quote.buyDepth[i].quantity}'
                        : '—',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: Text(
                    i < quote.buyDepth.length
                        ? fmt.format(quote.buyDepth[i].price)
                        : '—',
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.marketPositiveIndicator,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    i < quote.sellDepth.length
                        ? fmt.format(quote.sellDepth[i].price)
                        : '—',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.statusError,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Expanded(
                  child: Text(
                    i < quote.sellDepth.length
                        ? '${quote.sellDepth[i].quantity}'
                        : '—',
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Sq extends StatelessWidget {
  const _Sq({required this.label, required this.bg, required this.onTap});

  final String label;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: context.colors.actionPrimaryFg,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
