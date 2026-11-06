import 'package:am_chart_ui/am_chart_ui.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/am_market_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/paper_market_client.dart';

enum _PaperChartSection {
  overview,
  financials,
  shareholding,
  heatmap,
  optionChain,
  futures,
  margin,
}

/// Chart-terminal-style bottom strip for paper Chart tab (no EI hero/title).
class PaperChartBottomPanel extends ConsumerStatefulWidget {
  const PaperChartBottomPanel({
    super.key,
    required this.symbol,
    required this.ctrl,
  });

  final String symbol;
  final ChartTerminalController ctrl;

  @override
  ConsumerState<PaperChartBottomPanel> createState() =>
      _PaperChartBottomPanelState();
}

class _PaperChartBottomPanelState extends ConsumerState<PaperChartBottomPanel> {
  _PaperChartSection _section = _PaperChartSection.overview;

  bool get _isIndex => PaperMarketClient.isIndexSymbol(widget.symbol);

  List<(_PaperChartSection, String)> get _tags {
    if (_isIndex) {
      return const [
        (_PaperChartSection.heatmap, 'Heatmap'),
        (_PaperChartSection.optionChain, 'Option Chain'),
        (_PaperChartSection.futures, 'Futures'),
        (_PaperChartSection.margin, 'Margin'),
      ];
    }
    return const [
      (_PaperChartSection.overview, 'Overview'),
      (_PaperChartSection.financials, 'Financials'),
      (_PaperChartSection.shareholding, 'Shareholding'),
      (_PaperChartSection.optionChain, 'Option Chain'),
      (_PaperChartSection.futures, 'Futures'),
      (_PaperChartSection.margin, 'Margin'),
    ];
  }

  bool _isFo(_PaperChartSection s) =>
      s == _PaperChartSection.optionChain ||
      s == _PaperChartSection.futures ||
      s == _PaperChartSection.margin;

  void _syncFo(String symbol) {
    var sym = symbol.trim().toUpperCase();
    if (sym == 'NIFTY 50') sym = 'NIFTY';
    if (sym == 'NIFTY BANK') sym = 'BANKNIFTY';
    if (sym.isEmpty) return;
    ref.read(foActiveSymbolProvider.notifier).state = sym;
  }

  @override
  void didUpdateWidget(covariant PaperChartBottomPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol) {
      final tags = _tags;
      if (!tags.any((t) => t.$1 == _section)) {
        _section = tags.first.$1;
      }
      if (_isFo(_section)) {
        _syncFo(widget.symbol);
      }
    }
  }

  IconData _iconFor(_PaperChartSection section) {
    return switch (section) {
      _PaperChartSection.overview => Icons.grid_view_rounded,
      _PaperChartSection.financials => Icons.bar_chart_rounded,
      _PaperChartSection.shareholding => Icons.account_tree_outlined,
      _PaperChartSection.heatmap => Icons.view_quilt_rounded,
      _PaperChartSection.optionChain => Icons.hub_outlined,
      _PaperChartSection.futures => Icons.trending_up_rounded,
      _PaperChartSection.margin => Icons.link_rounded,
    };
  }

  Widget _body(String sym) {
    switch (_section) {
      case _PaperChartSection.overview:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: EquityInsiderKpis(key: ValueKey('kpi-$sym'), symbol: sym),
        );
      case _PaperChartSection.financials:
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: EquityInsiderFinancials(
            key: ValueKey('fin-$sym'),
            symbol: sym,
            compact: true,
          ),
        );
      case _PaperChartSection.shareholding:
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: EquityInsiderShareholding(
            key: ValueKey('sh-$sym'),
            symbol: sym,
          ),
        );
      case _PaperChartSection.heatmap:
        return MarketHeatmapWidget(
          key: ValueKey('heatmap-$sym'),
          symbol: sym,
          onSelectStock: (stockSym) {
            widget.ctrl.selectSymbol(stockSym);
            setState(() => _section = _PaperChartSection.overview);
          },
        );
      case _PaperChartSection.optionChain:
        return FoPage(
          key: ValueKey('fo-oc-$sym'),
          initialSymbol: PaperMarketClient.toFoUnderlier(sym),
          embed: true,
          embedSection: FoEmbedSection.optionChain,
        );
      case _PaperChartSection.futures:
        return FoPage(
          key: ValueKey('fo-fut-$sym'),
          initialSymbol: PaperMarketClient.toFoUnderlier(sym),
          embed: true,
          embedSection: FoEmbedSection.futures,
        );
      case _PaperChartSection.margin:
        return FoPage(
          key: ValueKey('fo-mgn-$sym'),
          initialSymbol: PaperMarketClient.toFoUnderlier(sym),
          embed: true,
          embedSection: FoEmbedSection.margin,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = ModuleColors.market;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final border = theme.dividerColor.withValues(alpha: 0.45);
    final tags = _tags;
    final sym = widget.symbol.trim().toUpperCase();
    final selected =
        tags.any((t) => t.$1 == _section) ? _section : tags.first.$1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.55),
            border: Border(bottom: BorderSide(color: border)),
          ),
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: tags.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 2),
                    itemBuilder: (context, i) {
                      final (tag, label) = tags[i];
                      final isActive = selected == tag;
                      final color = isActive ? accent : muted;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() => _section = tag);
                            if (tag == _PaperChartSection.heatmap) {
                              widget.ctrl.setBottomMinimized(false);
                            }
                            if (_isFo(tag)) {
                              _syncFo(sym);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color:
                                      isActive ? accent : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_iconFor(tag), size: 15, color: color),
                                const SizedBox(width: 6),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isActive
                                        ? theme.colorScheme.onSurface
                                        : muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Minimize panel',
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => widget.ctrl.setBottomMinimized(true),
                  icon: Icon(Icons.keyboard_arrow_down, color: muted),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: sym.isEmpty
              ? Center(
                  child: Text(
                    'Select a symbol',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                )
              : _body(sym),
        ),
      ],
    );
  }
}
