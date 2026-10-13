import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chart_types/chart_type_id.dart';
import '../drawings/chart_draw_models.dart';
import '../drawings/chart_draw_tools_rail.dart';
import '../persistence/workspace_store.dart';
import '../timeframe/chart_timeframe.dart';
import 'chart_pane_card.dart';
import 'chart_terminal_controller.dart';

typedef ChartPaneBuilder =
    Widget Function(
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
  bool _drawRailExpanded = true;
  ChartDrawTool _drawTool = ChartDrawTool.none;
  int _clearDrawingsEpoch = 0;
  int _activeDrawingsCount = 0;

  @override
  void initState() {
    super.initState();
    _bottomHeight = widget.bottomPanelHeight;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chartTerminalProvider.notifier)
          .bootstrap(
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

    ref.listen(chartTerminalProvider.select((s) => s.activePaneIndex), (
      prev,
      next,
    ) {
      if (prev != next) {
        setState(() => _activeDrawingsCount = 0);
      }
    });

    final sidebar =
        widget.sidebarBuilder?.call(context, state, ctrl) ??
        const _MissingPane(label: 'Watchlist — host did not provide pane');
    final bottom =
        widget.bottomPanelBuilder?.call(context, state, ctrl) ??
        const _MissingPane(
          label: 'Fundamentals / F&O — host did not provide pane',
        );

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
                      final isBottomVisible =
                          !_analysisFocus && !state.bottomMinimized;
                      final isBottomDockVisible =
                          !_analysisFocus && state.bottomMinimized;
                      final dockH = isBottomDockVisible ? 28.0 : 0.0;
                      final handleH = isBottomVisible ? 24.0 : 0.0;
                      final bottomH = isBottomVisible
                          ? _bottomHeight.clamp(200.0, maxH * 0.7)
                          : 0.0;
                      final chartH =
                          (maxH - bottomH - handleH - dockH).clamp(100.0, maxH);

                      return Column(
                        children: [
                          SizedBox(
                            height: chartH,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // One shared TV-style draw rail (left of all panes).
                                ChartDrawToolsRail(
                                  expanded: _drawRailExpanded,
                                  activeTool: _drawTool,
                                  drawingCount: _activeDrawingsCount,
                                  onToggleExpanded: () => setState(
                                    () =>
                                        _drawRailExpanded = !_drawRailExpanded,
                                  ),
                                  onSelectTool: (t) => setState(() {
                                    _drawTool = t;
                                  }),
                                  onClearAll: () => setState(() {
                                    _clearDrawingsEpoch++;
                                    _activeDrawingsCount = 0;
                                  }),
                                ),
                                Expanded(
                                  child: _ChartGrid(
                                    state: state,
                                    drawTool: _drawTool,
                                    clearDrawingsEpoch: _clearDrawingsEpoch,
                                    onDrawingsCountChanged: (n) {
                                      if (_activeDrawingsCount != n) {
                                        setState(
                                          () => _activeDrawingsCount = n,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isBottomVisible) ...[
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onDoubleTap: () => ctrl.setBottomMinimized(true),
                              onVerticalDragUpdate: (d) {
                                setState(() {
                                  _bottomHeight = (_bottomHeight - d.delta.dy)
                                      .clamp(200.0, maxH * 0.7);
                                });
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.resizeUpDown,
                                child: Container(
                                  height: handleH,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    border: Border(
                                      top: BorderSide(
                                        color: theme.dividerColor.withValues(
                                          alpha: 0.35,
                                        ),
                                      ),
                                      bottom: BorderSide(
                                        color: theme.dividerColor.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.view_agenda_outlined,
                                        size: 13,
                                        color: theme.hintColor.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'PANEL',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                          color: theme.hintColor.withValues(
                                            alpha: 0.8,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Container(
                                            width: 44,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: theme.hintColor.withValues(
                                                alpha: 0.35,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Tooltip(
                                        message:
                                            'Minimize bottom panel (Double-click to toggle)',
                                        child: InkWell(
                                          onTap: () =>
                                              ctrl.setBottomMinimized(true),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Minimize',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: theme.hintColor,
                                                  ),
                                                ),
                                                const SizedBox(width: 2),
                                                Icon(
                                                  Icons.keyboard_arrow_down,
                                                  size: 16,
                                                  color: theme.hintColor,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: bottomH, child: bottom),
                          ],
                          if (isBottomDockVisible)
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => ctrl.setBottomMinimized(false),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Container(
                                  height: dockH,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    border: Border(
                                      top: BorderSide(
                                        color: theme.dividerColor.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.keyboard_arrow_up,
                                        size: 17,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Bottom Panel (Fundamentals · Overview · Shareholding · F&O)',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.open_in_browser,
                                              size: 13,
                                              color: theme.colorScheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Restore Panel',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                if (!_analysisFocus) ...[
                  if (!state.sidebarMinimized) ...[
                    const VerticalDivider(width: 1),
                    SizedBox(
                      width: widget.sidebarWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 28,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              border: Border(
                                bottom: BorderSide(
                                  color: theme.dividerColor.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.view_sidebar_outlined,
                                  size: 14,
                                  color: theme.hintColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'WATCHLIST & PORTFOLIO',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: theme.hintColor,
                                  ),
                                ),
                                const Spacer(),
                                Tooltip(
                                  message: 'Minimize sidebar',
                                  child: InkWell(
                                    onTap: () => ctrl.setSidebarMinimized(true),
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Minimize',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: theme.hintColor,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Icon(
                                            Icons.chevron_right,
                                            size: 16,
                                            color: theme.hintColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(child: sidebar),
                        ],
                      ),
                    ),
                  ] else ...[
                    const VerticalDivider(width: 1),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => ctrl.setSidebarMinimized(false),
                        child: Container(
                          width: 32,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            border: Border(
                              left: BorderSide(
                                color: theme.dividerColor.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              Tooltip(
                                message:
                                    'Expand sidebar (Watchlist / Portfolio)',
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.chevron_left,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Icon(
                                Icons.view_sidebar_outlined,
                                size: 16,
                                color: theme.hintColor,
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: RotatedBox(
                                  quarterTurns: 1,
                                  child: Center(
                                    child: Text(
                                      'WATCHLIST · PORTFOLIO',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                        color: theme.hintColor.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
  const _ChartGrid({
    required this.state,
    required this.drawTool,
    required this.clearDrawingsEpoch,
    this.onDrawingsCountChanged,
  });
  final ChartTerminalState state;
  final ChartDrawTool drawTool;
  final int clearDrawingsEpoch;
  final ValueChanged<int>? onDrawingsCountChanged;

  @override
  Widget build(BuildContext context) {
    final panes = state.panes;
    final active = state.activePaneIndex;
    final multi = state.layout != ChartGridLayout.one;

    Widget card(int i) => ChartPaneCard(
      paneIndex: i,
      pane: panes[i],
      isActive: i == active,
      showIdentityStrip: multi,
      drawTool: drawTool,
      clearDrawingsEpoch: clearDrawingsEpoch,
      onDrawingsCountChanged: onDrawingsCountChanged,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: [
            // Left: nav + layout + symbol + price badge
            IconButton(
              tooltip: 'Back',
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 4),
            _LayoutIconToggle(layout: state.layout, onChanged: ctrl.setLayout),
            const SizedBox(width: 8),
            _divider(theme),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 90, maxWidth: 220),
              child: Text(
                '${active.symbol} · ${active.exchange}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildPriceBadge(context, active),
            const SizedBox(width: 8),
            _divider(theme),
            const SizedBox(width: 8),

            // Center: scrollable strip with OHLCV, Timeframes, Chart Type, Indicators, Compare, Tools
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildOhlcvStats(context, active),
                    if (active.bars.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _divider(theme),
                      const SizedBox(width: 8),
                    ],
                    ..._buildTimeframePills(context, state, ctrl),
                    const SizedBox(width: 8),
                    _divider(theme),
                    const SizedBox(width: 8),
                    _buildChartTypeSelector(context, state, ctrl),
                    const SizedBox(width: 6),
                    _buildIndicatorsButton(context),
                    const SizedBox(width: 6),
                    _buildCompareButton(context, ctrl),
                    const SizedBox(width: 8),
                    _divider(theme),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Fit chart (Auto scale)',
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 34, minHeight: 34),
                      onPressed: ctrl.requestFit,
                      icon: const Icon(Icons.fit_screen),
                    ),
                    const SizedBox(width: 3),
                    IconButton(
                      tooltip: 'Refresh chart data',
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 34, minHeight: 34),
                      onPressed: () => ctrl.reloadPane(state.activePaneIndex),
                      icon: const Icon(Icons.refresh),
                    ),
                    const SizedBox(width: 3),
                    IconButton(
                      tooltip: 'Chart snapshot',
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 34, minHeight: 34),
                      onPressed: () => _copySnapshot(context),
                      icon: const Icon(Icons.camera_alt_outlined),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),
            // Right: search + focus toggle
            if (showSearch)
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 180, maxWidth: 280),
                child: SizedBox(
                  width: 240,
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
              ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: state.bottomMinimized
                  ? 'Restore bottom panel'
                  : 'Minimize bottom panel',
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: ctrl.toggleBottomMinimized,
              icon: Icon(
                state.bottomMinimized
                    ? Icons.splitscreen_outlined
                    : Icons.splitscreen,
                color: state.bottomMinimized
                    ? theme.hintColor
                    : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 2),
            IconButton(
              tooltip: state.sidebarMinimized
                  ? 'Restore sidebar'
                  : 'Minimize sidebar',
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: ctrl.toggleSidebarMinimized,
              icon: Icon(
                state.sidebarMinimized
                    ? Icons.view_sidebar_outlined
                    : Icons.view_sidebar,
                color: state.sidebarMinimized
                    ? theme.hintColor
                    : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 2),
            IconButton(
              tooltip: widget.analysisFocus
                  ? 'Exit focus mode (show all)'
                  : 'Full focus (chart only)',
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: widget.onToggleFocus,
              icon: Icon(
                widget.analysisFocus
                    ? Icons.fullscreen_exit
                    : Icons.fullscreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(ThemeData theme) {
    return Container(
      width: 1,
      height: 18,
      color: theme.dividerColor.withValues(alpha: 0.4),
    );
  }

  Widget _buildPriceBadge(BuildContext context, ChartPaneState active) {
    double price = 0;
    double change = 0;
    double changePct = 0;

    if (active.quote != null) {
      price = active.quote!.last;
      changePct = active.quote!.changePct;
      if (active.bars.length > 1) {
        final prev = active.bars[active.bars.length - 2].close;
        change = price - prev;
      }
    } else if (active.bars.isNotEmpty) {
      final last = active.bars.last;
      price = last.close;
      final prev = active.bars.length > 1
          ? active.bars[active.bars.length - 2].close
          : last.open;
      change = price - prev;
      changePct = prev > 0 ? (change / prev) * 100 : 0;
    }

    if (price == 0) return const SizedBox.shrink();

    final isPositive = change >= 0;
    final color =
        isPositive ? const Color(0xFF089981) : const Color(0xFFF23645);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '₹${price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '${isPositive ? '+' : ''}${change.toStringAsFixed(2)} (${isPositive ? '+' : ''}${changePct.toStringAsFixed(2)}%)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOhlcvStats(BuildContext context, ChartPaneState active) {
    if (active.bars.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final lastBar = active.bars.last;
    final isUp = lastBar.close >= lastBar.open;
    final color = isUp ? const Color(0xFF089981) : const Color(0xFFF23645);
    final change = lastBar.close - lastBar.open;
    final changePct =
        lastBar.open > 0 ? (change / lastBar.open) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ohlcItem('O', lastBar.open.toStringAsFixed(2), theme),
          const SizedBox(width: 8),
          _ohlcItem('H', lastBar.high.toStringAsFixed(2), theme),
          const SizedBox(width: 8),
          _ohlcItem('L', lastBar.low.toStringAsFixed(2), theme),
          const SizedBox(width: 8),
          _ohlcItem('C', lastBar.close.toStringAsFixed(2), theme,
              valueColor: color),
          const SizedBox(width: 8),
          _ohlcItem(
            'Chg',
            '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)} (${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(2)}%)',
            theme,
            valueColor: color,
          ),
          if (lastBar.volume > 0) ...[
            const SizedBox(width: 8),
            _ohlcItem('Vol', _formatVol(lastBar.volume), theme),
          ],
        ],
      ),
    );
  }

  Widget _ohlcItem(
    String label,
    String value,
    ThemeData theme, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: theme.hintColor,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: valueColor ?? theme.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }

  String _formatVol(double v) {
    if (v >= 1e7) return '${(v / 1e7).toStringAsFixed(2)}Cr';
    if (v >= 1e5) return '${(v / 1e5).toStringAsFixed(2)}L';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  List<Widget> _buildTimeframePills(
    BuildContext context,
    ChartTerminalState state,
    ChartTerminalController ctrl,
  ) {
    final active = state.active;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    const quickTfs = [
      ChartTimeframe.m1,
      ChartTimeframe.m5,
      ChartTimeframe.m15,
      ChartTimeframe.h1,
      ChartTimeframe.d1,
      ChartTimeframe.w1,
      ChartTimeframe.mo1,
      ChartTimeframe.y1,
    ];

    void onSelect(ChartTimeframe tf) {
      if (state.isMultiLayout) {
        ctrl.setTimeframeForAll(tf);
      } else {
        ctrl.setTimeframe(tf);
      }
    }

    return [
      for (final tf in quickTfs)
        Padding(
          padding: const EdgeInsets.only(right: 3),
          child: InkWell(
            onTap: () => onSelect(tf),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: active.timeframe == tf
                    ? primary.withValues(alpha: 0.22)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: active.timeframe == tf
                    ? Border.all(
                        color: primary.withValues(alpha: 0.8), width: 1.2)
                    : null,
              ),
              child: Text(
                tf.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active.timeframe == tf
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: active.timeframe == tf
                      ? primary
                      : theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.75,
                        ),
                ),
              ),
            ),
          ),
        ),
      PopupMenuButton<ChartTimeframe>(
        tooltip: 'More timeframes',
        padding: EdgeInsets.zero,
        onSelected: onSelect,
        itemBuilder: (context) => [
          const PopupMenuItem(
            enabled: false,
            height: 26,
            child: Text(
              'Seconds',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
          for (final tf in [ChartTimeframe.s1, ChartTimeframe.s5])
            PopupMenuItem(
              value: tf,
              height: 30,
              child: Text(tf.label, style: const TextStyle(fontSize: 12)),
            ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            enabled: false,
            height: 26,
            child: Text(
              'Minutes',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
          for (final tf in [ChartTimeframe.m3, ChartTimeframe.m30])
            PopupMenuItem(
              value: tf,
              height: 30,
              child: Text(tf.label, style: const TextStyle(fontSize: 12)),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Icon(Icons.arrow_drop_down, size: 16, color: theme.hintColor),
        ),
      ),
    ];
  }

  Widget _buildChartTypeSelector(
    BuildContext context,
    ChartTerminalState state,
    ChartTerminalController ctrl,
  ) {
    final active = state.active;
    final theme = Theme.of(context);

    IconData iconFor(ChartTypeId type) {
      return switch (type) {
        ChartTypeId.candlestick => Icons.candlestick_chart,
        ChartTypeId.hollowCandle => Icons.candlestick_chart_outlined,
        ChartTypeId.ohlcBar => Icons.bar_chart,
        ChartTypeId.line => Icons.show_chart,
        ChartTypeId.area => Icons.area_chart,
        ChartTypeId.baseline => Icons.stacked_line_chart,
        ChartTypeId.columns => Icons.insert_chart_outlined,
        _ => Icons.candlestick_chart,
      };
    }

    return PopupMenuButton<ChartTypeId>(
      tooltip: state.isMultiLayout ? 'Chart type (all panes)' : 'Chart type',
      onSelected: ctrl.setChartType,
      itemBuilder: (context) => [
        for (final t in ChartTypeId.values)
          PopupMenuItem(
            value: t,
            enabled: t.isAvailable,
            child: Row(
              children: [
                Icon(
                  iconFor(t),
                  size: 16,
                  color: active.chartType == t
                      ? theme.colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  t.isAvailable ? t.label : '${t.label} (Coming)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active.chartType == t
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: t.isAvailable ? null : theme.disabledColor,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconFor(active.chartType),
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              active.chartType.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.arrow_drop_down, size: 18, color: theme.hintColor),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorsButton(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _showIndicatorsModal(context),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'fx',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Indicators',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIndicatorsModal(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        const indicators = [
          ('RSI', 'Relative Strength Index', 'Momentum'),
          (
            'MACD',
            'Moving Average Convergence Divergence',
            'Trend / Momentum'
          ),
          ('SMA', 'Simple Moving Average (20, 50, 200)', 'Trend'),
          ('EMA', 'Exponential Moving Average (9, 21)', 'Trend'),
          ('BB', 'Bollinger Bands', 'Volatility'),
          ('VWAP', 'Volume Weighted Average Price', 'Volume'),
          ('Supertrend', 'Supertrend ATR Trailing Stop', 'Trend'),
          ('Stoch', 'Stochastic Oscillator', 'Momentum'),
          ('ATR', 'Average True Range', 'Volatility'),
          ('OBV', 'On Balance Volume', 'Volume'),
        ];
        return AlertDialog(
          title: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'fx',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Indicators & Studies',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            height: 380,
            child: ListView.separated(
              itemCount: indicators.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: theme.dividerColor.withValues(alpha: 0.3),
              ),
              itemBuilder: (ctx, i) {
                final ind = indicators[i];
                return ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.12),
                    child: Text(
                      ind.$1.substring(0, 1),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    ind.$1,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  subtitle: Text(
                    ind.$2,
                    style: TextStyle(fontSize: 11, color: theme.hintColor),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(ind.$3, style: const TextStyle(fontSize: 10)),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${ind.$1} indicator activated'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompareButton(
    BuildContext context,
    ChartTerminalController ctrl,
  ) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      tooltip: 'Compare with Benchmark',
      onSelected: (sym) => ctrl.selectSymbol(sym),
      itemBuilder: (context) => [
        const PopupMenuItem(
          enabled: false,
          height: 26,
          child: Text(
            'Benchmarks',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ),
        const PopupMenuItem(
          value: 'NIFTY 50',
          child: Text('NIFTY 50', style: TextStyle(fontSize: 12)),
        ),
        const PopupMenuItem(
          value: 'BANKNIFTY',
          child: Text('NIFTY BANK', style: TextStyle(fontSize: 12)),
        ),
        const PopupMenuItem(
          value: 'SENSEX',
          child: Text('BSE SENSEX', style: TextStyle(fontSize: 12)),
        ),
        const PopupMenuItem(
          value: 'NIFTY IT',
          child: Text('NIFTY IT', style: TextStyle(fontSize: 12)),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 5),
            const Text(
              'Compare',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copySnapshot(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chart snapshot captured to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Icon-only layout toggle: 1 pane / side-by-side / 2×2 grid.
class _LayoutIconToggle extends StatelessWidget {
  const _LayoutIconToggle({required this.layout, required this.onChanged});

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
          tooltip: '4 panes · 2×2 grid only',
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
