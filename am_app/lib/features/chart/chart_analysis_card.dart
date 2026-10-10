import 'package:am_dashboard_ui/domain/models/overlay_chart_models.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chart_analysis_models.dart';
import 'chart_analysis_workspace_provider.dart';

class ChartAnalysisCard extends ConsumerStatefulWidget {
  const ChartAnalysisCard({
    super.key,
    required this.userId,
    required this.card,
    required this.canClose,
  });

  final String userId;
  final ChartCardState card;
  final bool canClose;

  @override
  ConsumerState<ChartAnalysisCard> createState() => _ChartAnalysisCardState();
}

class _ChartAnalysisCardState extends ConsumerState<ChartAnalysisCard> {
  final _searchCtrl = TextEditingController();
  final _api = ApiService();
  List<Map<String, dynamic>> _searchHits = [];
  bool _searching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  ChartAnalysisWorkspaceNotifier get _ws =>
      ref.read(chartAnalysisWorkspaceProvider(widget.userId).notifier);

  Future<void> _runSearch(String q) async {
    final query = q.trim();
    if (query.isEmpty) {
      setState(() => _searchHits = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final presets = OverlayChartIds.addableIndices
          .where((s) => s.toLowerCase().contains(query.toLowerCase()))
          .map((s) => {'trading_symbol': s, 'name': s})
          .toList();
      final results = await _api.searchInstruments(query, 'UPSTOX');
      final hits = <Map<String, dynamic>>[
        ...presets,
        ...results,
      ];
      if (!mounted) return;
      setState(() {
        _searchHits = hits.take(12).toList();
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchHits = [];
        _searching = false;
      });
    }
  }

  String _symbolFromHit(Map<String, dynamic> hit) {
    return (hit['trading_symbol'] ??
            hit['tradingSymbol'] ??
            hit['symbol'] ??
            hit['name'] ??
            '')
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = widget.card;
    final tfs = _ws.timeFrames;

    return Card(
      margin: const EdgeInsets.all(6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 4, 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 32,
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      hintText: card.mode == ChartCardMode.candle
                          ? 'Symbol…'
                          : 'Add symbol…',
                      border: const OutlineInputBorder(),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    onChanged: (v) {
                      Future.delayed(const Duration(milliseconds: 280), () {
                        if (_searchCtrl.text == v) _runSearch(v);
                      });
                    },
                  ),
                ),
                ...tfs.map((tf) {
                  final selected = card.timeFrameCode.toUpperCase() == tf;
                  return FilterChip(
                    label: Text(tf, style: const TextStyle(fontSize: 11)),
                    selected: selected,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => _ws.setCardTimeFrame(card.id, tf),
                  );
                }),
                SegmentedButton<ChartCardMode>(
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: ChartCardMode.compare,
                      label: Text('Compare', style: TextStyle(fontSize: 11)),
                    ),
                    ButtonSegment(
                      value: ChartCardMode.candle,
                      label: Text('Candle', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                  selected: {card.mode},
                  onSelectionChanged: (s) => _ws.setCardMode(card.id, s.first),
                ),
                if (card.mode == ChartCardMode.candle)
                  PopupMenuButton<ChartIndicatorId>(
                    tooltip: 'Indicators',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.functions,
                              size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text('fx',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.primary)),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      for (final id in ChartIndicatorId.values)
                        CheckedPopupMenuItem(
                          value: id,
                          checked: card.indicators.contains(id),
                          child: Text(id.label),
                        ),
                    ],
                    onSelected: (id) => _ws.toggleIndicator(card.id, id),
                  ),
                if (widget.canClose)
                  IconButton(
                    tooltip: 'Close card',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _ws.removeCard(card.id),
                  ),
              ],
            ),
          ),
          if (_searchHits.isNotEmpty)
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _searchHits.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final hit = _searchHits[i];
                  final sym = _symbolFromHit(hit);
                  if (sym.isEmpty) return const SizedBox.shrink();
                  return ActionChip(
                    label: Text(sym, style: const TextStyle(fontSize: 11)),
                    onPressed: () async {
                      await _ws.addSymbolToCard(card.id, sym);
                      _searchCtrl.clear();
                      setState(() => _searchHits = []);
                    },
                  );
                },
              ),
            ),
          if (card.mode == ChartCardMode.compare)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                spacing: 4,
                children: [
                  for (final s in OverlayChartIds.addableIndices)
                    ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 10)),
                      onPressed: () => _ws.addSymbolToCard(card.id, s),
                    ),
                  for (final s in card.symbols)
                    InputChip(
                      label: Text(s, style: const TextStyle(fontSize: 10)),
                      onDeleted: card.symbols.length > 1
                          ? () => _ws.removeSymbolFromCard(card.id, s)
                          : null,
                    ),
                ],
              ),
            ),
          Expanded(child: _buildBody(card)),
        ],
      ),
    );
  }

  Widget _buildBody(ChartCardState card) {
    if (card.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (card.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(card.error!),
            TextButton(
              onPressed: () => _ws.reloadCard(card.id),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (card.mode == ChartCardMode.compare) {
      final labels = card.compareData.labels(preferredOrder: card.symbols);
      if (labels.isEmpty) {
        return const Center(child: Text('No series data'));
      }
      return Padding(
        padding: const EdgeInsets.all(8),
        child: ComparisonChartView(
          data: card.compareData,
          config: MultiSeriesChartConfig(
            preferredSeriesOrder: labels,
            embedMode: true,
            timeFrameCode: card.timeFrameCode,
            showExpandButton: false,
            showEndValuePills: false,
            preNormalizedPercent: false,
            onRemoveSeries: (label) => _ws.removeSymbolFromCard(card.id, label),
          ),
        ),
      );
    }
    if (card.candles.length < 2) {
      return const Center(child: Text('No candle data'));
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: IndicatorCandleChart(
        candles: card.candles,
        indicators: card.indicators,
      ),
    );
  }
}
