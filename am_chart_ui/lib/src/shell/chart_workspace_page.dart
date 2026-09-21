import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chart_types/chart_type_id.dart';
import '../persistence/workspace_store.dart';
import '../timeframe/chart_timeframe.dart';
import 'chart_pane_card.dart';
import 'chart_terminal_controller.dart';

typedef ChartPaneBuilder = Widget Function(
  BuildContext context,
  ChartTerminalState state,
  ChartTerminalController ctrl,
);

/// Full advanced chart terminal. Hosts may override sidebar / bottom panes.
class ChartWorkspacePage extends ConsumerStatefulWidget {
  const ChartWorkspacePage({
    super.key,
    this.initialSymbol,
    this.initialTimeframe,
    this.sidebarBuilder,
    this.bottomPanelBuilder,
    this.sidebarWidth = 300,
    this.bottomPanelHeight = 320,
    this.showHeaderSearch = true,
  });

  final String? initialSymbol;
  final String? initialTimeframe;
  final ChartPaneBuilder? sidebarBuilder;
  final ChartPaneBuilder? bottomPanelBuilder;
  final double sidebarWidth;
  /// Initial bottom panel height (resizable via drag handle).
  final double bottomPanelHeight;
  /// When false, symbol is chosen only via sidebar / host (no top search).
  final bool showHeaderSearch;

  @override
  ConsumerState<ChartWorkspacePage> createState() => _ChartWorkspacePageState();
}

class _ChartWorkspacePageState extends ConsumerState<ChartWorkspacePage> {
  bool _analysisFocus = false;
  late double _bottomHeight;

  @override
  void initState() {
    super.initState();
    _bottomHeight = widget.bottomPanelHeight;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chartTerminalProvider.notifier).bootstrap(
            symbol: widget.initialSymbol,
            timeframeCode: widget.initialTimeframe,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chartTerminalProvider);
    final ctrl = ref.read(chartTerminalProvider.notifier);
    final theme = Theme.of(context);

    final sidebar = widget.sidebarBuilder?.call(context, state, ctrl) ??
        const _MissingPane(label: 'Watchlist — host did not provide pane');
    final bottom = widget.bottomPanelBuilder?.call(context, state, ctrl) ??
        const _MissingPane(
            label: 'Fundamentals / F&O — host did not provide pane');

    return Scaffold(
      body: Column(
        children: [
          _SlimTopBar(
            state: state,
            ctrl: ctrl,
            analysisFocus: _analysisFocus,
            showHeaderSearch: widget.showHeaderSearch,
            onToggleFocus: () =>
                setState(() => _analysisFocus = !_analysisFocus),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxH = constraints.maxHeight;
                      final bottomH = _analysisFocus
                          ? 0.0
                          : _bottomHeight.clamp(220.0, maxH * 0.7);
                      final handleH = _analysisFocus ? 0.0 : 6.0;
                      final chartH = maxH - bottomH - handleH;

                      return Column(
                        children: [
                          SizedBox(
                            height: chartH,
                            child: _ChartGrid(state: state),
                          ),
                          if (!_analysisFocus) ...[
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onVerticalDragUpdate: (d) {
                                setState(() {
                                  _bottomHeight =
                                      (_bottomHeight - d.delta.dy)
                                          .clamp(220.0, maxH * 0.7);
                                });
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.resizeUpDown,
                                child: Container(
                                  height: handleH,
                                  color: theme.dividerColor
                                      .withValues(alpha: 0.35),
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 36,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: theme.hintColor
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: bottomH, child: bottom),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                if (!_analysisFocus) ...[
                  const VerticalDivider(width: 1),
                  SizedBox(width: widget.sidebarWidth, child: sidebar),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartGrid extends StatelessWidget {
  const _ChartGrid({required this.state});
  final ChartTerminalState state;

  @override
  Widget build(BuildContext context) {
    final panes = state.panes;
    final active = state.activePaneIndex;
    final multi = state.layout != ChartGridLayout.one;

    Widget card(int i) => ChartPaneCard(
          paneIndex: i,
          pane: panes[i],
          isActive: i == active,
          showDrawRail: true,
          showIdentityStrip: multi,
        );

    switch (state.layout) {
      case ChartGridLayout.one:
        return card(0);
      case ChartGridLayout.two:
        return Row(
          children: [
            Expanded(child: card(0)),
            const VerticalDivider(width: 1),
            Expanded(child: card(1)),
          ],
        );
      case ChartGridLayout.four:
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: card(0)),
                  const VerticalDivider(width: 1),
                  Expanded(child: card(1)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: card(2)),
                  const VerticalDivider(width: 1),
                  Expanded(child: card(3)),
                ],
              ),
            ),
          ],
        );
    }
  }
}

class _SlimTopBar extends ConsumerStatefulWidget {
  const _SlimTopBar({
    required this.state,
    required this.ctrl,
    required this.analysisFocus,
    required this.onToggleFocus,
    this.showHeaderSearch = true,
  });
  final ChartTerminalState state;
  final ChartTerminalController ctrl;
  final bool analysisFocus;
  final VoidCallback onToggleFocus;
  final bool showHeaderSearch;

  @override
  ConsumerState<_SlimTopBar> createState() => _SlimTopBarState();
}

class _SlimTopBarState extends ConsumerState<_SlimTopBar> {
  final _searchCtrl = TextEditingController();

  static const _intraday = [
    ChartTimeframe.m1,
    ChartTimeframe.m5,
    ChartTimeframe.m15,
    ChartTimeframe.h1,
  ];
  static const _daily = [
    ChartTimeframe.d1,
    ChartTimeframe.w1,
    ChartTimeframe.mo1,
    ChartTimeframe.y1,
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.state;
    final ctrl = widget.ctrl;
    final active = state.active;
    final showSearch = widget.showHeaderSearch;

    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            _LayoutIconToggle(
              layout: state.layout,
              onChanged: ctrl.setLayout,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                '${active.symbol} · ${active.exchange}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (active.quote != null) ...[
              const SizedBox(width: 6),
              Text(
                '${active.quote!.last.toStringAsFixed(2)}  '
                '${active.quote!.changePct >= 0 ? '+' : ''}'
                '${active.quote!.changePct.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: active.quote!.changePct >= 0
                      ? Colors.tealAccent.shade400
                      : Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(width: 4),
            PopupMenuButton<ChartTimeframe>(
              tooltip: 'Timeframe',
              padding: EdgeInsets.zero,
              onSelected: (tf) => ctrl.setTimeframe(tf),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  enabled: false,
                  height: 28,
                  child: Text('Intraday',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700)),
                ),
                for (final tf in _intraday)
                  PopupMenuItem(
                    value: tf,
                    height: 32,
                    child: Text(tf.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: active.timeframe == tf
                              ? FontWeight.w700
                              : FontWeight.w400,
                        )),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  enabled: false,
                  height: 28,
                  child: Text('Daily',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700)),
                ),
                for (final tf in _daily)
                  PopupMenuItem(
                    value: tf,
                    height: 32,
                    child: Text(tf.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: active.timeframe == tf
                              ? FontWeight.w700
                              : FontWeight.w400,
                        )),
                  ),
              ],
              child: Chip(
                label: Text(active.timeframe.label,
                    style: const TextStyle(fontSize: 10)),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            PopupMenuButton<ChartTypeId>(
              tooltip: 'Chart type',
              onSelected: ctrl.setChartType,
              itemBuilder: (context) => [
                for (final t in ChartTypeId.values)
                  PopupMenuItem(
                    value: t,
                    enabled: t.isAvailable,
                    child: Text(
                      t.isAvailable ? t.label : '${t.label} (Coming)',
                      style: TextStyle(
                        color: t.isAvailable ? null : theme.disabledColor,
                      ),
                    ),
                  ),
              ],
              child: Chip(
                label: Text(active.chartType.label,
                    style: const TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
              ),
            ),
            IconButton(
              tooltip: 'Fit chart',
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: ctrl.requestFit,
              icon: const Icon(Icons.fit_screen),
            ),
            if (showSearch) ...[
              const SizedBox(width: 4),
              SizedBox(
                width: 180,
                child: SmartSearchAnchor(
                  controller: _searchCtrl,
                  compact: true,
                  hintText: 'Search symbol…',
                  category: 'STOCKS',
                  accentColor: theme.colorScheme.primary,
                  onSelected: (sym) {
                    _searchCtrl.clear();
                    ctrl.selectSymbol(sym);
                  },
                  onSubmit: () {
                    final q = _searchCtrl.text.trim();
                    if (q.isEmpty) return;
                    _searchCtrl.clear();
                    ctrl.selectSymbol(q);
                  },
                ),
              ),
            ],
            IconButton(
              tooltip: widget.analysisFocus
                  ? 'Show panels'
                  : 'Analysis focus (chart only)',
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: widget.onToggleFocus,
              icon: Icon(
                widget.analysisFocus
                    ? Icons.view_sidebar_outlined
                    : Icons.fullscreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon-only layout toggle: 1 pane / side-by-side / 2×2 grid.
class _LayoutIconToggle extends StatelessWidget {
  const _LayoutIconToggle({
    required this.layout,
    required this.onChanged,
  });

  final ChartGridLayout layout;
  final ValueChanged<ChartGridLayout> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = {
      ChartGridLayout.one: layout == ChartGridLayout.one,
      ChartGridLayout.two: layout == ChartGridLayout.two,
      ChartGridLayout.four: layout == ChartGridLayout.four,
    };

    Widget btn({
      required ChartGridLayout value,
      required IconData icon,
      required String tooltip,
    }) {
      final on = selected[value] == true;
      return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              icon,
              size: 20,
              color: on ? theme.colorScheme.primary : theme.hintColor,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(
          value: ChartGridLayout.one,
          icon: Icons.crop_square_outlined,
          tooltip: '1 pane',
        ),
        btn(
          value: ChartGridLayout.two,
          icon: Icons.view_column_outlined,
          tooltip: '2 panes side by side',
        ),
        btn(
          value: ChartGridLayout.four,
          icon: Icons.grid_view_outlined,
          tooltip: '4 panes 2×2',
        ),
      ],
    );
  }
}

class _MissingPane extends StatelessWidget {
  const _MissingPane({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }
}
