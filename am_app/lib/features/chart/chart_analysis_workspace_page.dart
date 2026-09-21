import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chart_analysis_card.dart';
import 'chart_analysis_models.dart';
import 'chart_analysis_workspace_provider.dart';

/// TradingView-style multi-window chart analysis workspace.
class ChartAnalysisWorkspacePage extends ConsumerStatefulWidget {
  const ChartAnalysisWorkspacePage({
    super.key,
    required this.userId,
    required this.initialTimeFrame,
    this.initialSeries = const [],
  });

  final String userId;
  final String initialTimeFrame;
  final List<String> initialSeries;

  @override
  ConsumerState<ChartAnalysisWorkspacePage> createState() =>
      _ChartAnalysisWorkspacePageState();
}

class _ChartAnalysisWorkspacePageState
    extends ConsumerState<ChartAnalysisWorkspacePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chartAnalysisWorkspaceProvider(widget.userId).notifier).open(
            timeFrame: widget.initialTimeFrame,
            seedSeries: widget.initialSeries,
          );
    });
  }

  @override
  void didUpdateWidget(covariant ChartAnalysisWorkspacePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTimeFrame != widget.initialTimeFrame ||
        !_listEq(oldWidget.initialSeries, widget.initialSeries)) {
      ref.read(chartAnalysisWorkspaceProvider(widget.userId).notifier).open(
            timeFrame: widget.initialTimeFrame,
            seedSeries: widget.initialSeries,
          );
    }
  }

  bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chartAnalysisWorkspaceProvider(widget.userId));
    final ws = ref.read(chartAnalysisWorkspaceProvider(widget.userId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart analysis'),
        actions: [
          SegmentedButton<ChartWorkspaceLayout>(
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            segments: const [
              ButtonSegment(
                value: ChartWorkspaceLayout.one,
                label: Text('1'),
              ),
              ButtonSegment(
                value: ChartWorkspaceLayout.two,
                label: Text('2'),
              ),
              ButtonSegment(
                value: ChartWorkspaceLayout.four,
                label: Text('4'),
              ),
            ],
            selected: {state.layout},
            onSelectionChanged: (s) => ws.setLayout(s.first),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Sync TF', style: TextStyle(fontSize: 12)),
            selected: state.syncTimeFrame,
            onSelected: ws.setSyncTimeFrame,
          ),
          IconButton(
            tooltip: 'Add chart',
            onPressed: state.cards.length >= 4 ? null : ws.addCard,
            icon: const Icon(Icons.add),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _WorkspaceGrid(
        userId: widget.userId,
        state: state,
      ),
    );
  }
}

class _WorkspaceGrid extends StatelessWidget {
  const _WorkspaceGrid({
    required this.userId,
    required this.state,
  });

  final String userId;
  final ChartAnalysisWorkspaceState state;

  @override
  Widget build(BuildContext context) {
    final cards = state.cards;
    if (cards.isEmpty) {
      return const Center(child: Text('No charts'));
    }

    switch (state.layout) {
      case ChartWorkspaceLayout.one:
        return ChartAnalysisCard(
          userId: userId,
          card: cards.first,
          canClose: cards.length > 1,
        );
      case ChartWorkspaceLayout.two:
        return Column(
          children: [
            for (var i = 0; i < cards.take(2).length; i++)
              Expanded(
                child: ChartAnalysisCard(
                  userId: userId,
                  card: cards[i],
                  canClose: cards.length > 1,
                ),
              ),
          ],
        );
      case ChartWorkspaceLayout.four:
        final shown = cards.take(4).toList();
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ChartAnalysisCard(
                      userId: userId,
                      card: shown[0],
                      canClose: shown.length > 1,
                    ),
                  ),
                  if (shown.length > 1)
                    Expanded(
                      child: ChartAnalysisCard(
                        userId: userId,
                        card: shown[1],
                        canClose: shown.length > 1,
                      ),
                    ),
                ],
              ),
            ),
            if (shown.length > 2)
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: ChartAnalysisCard(
                        userId: userId,
                        card: shown[2],
                        canClose: shown.length > 1,
                      ),
                    ),
                    if (shown.length > 3)
                      Expanded(
                        child: ChartAnalysisCard(
                          userId: userId,
                          card: shown[3],
                          canClose: shown.length > 1,
                        ),
                      )
                    else
                      const Expanded(child: SizedBox()),
                  ],
                ),
              ),
          ],
        );
    }
  }
}
