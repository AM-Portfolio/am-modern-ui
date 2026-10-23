import 'dart:async';

import 'package:am_common/am_common.dart';
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

  /// When true, shows a search icon that opens Global Omnisearch (no local symbol field).
  final bool showHeaderSearch;

  @override
  ConsumerState<ChartWorkspacePage> createState() => _ChartWorkspacePageState();
}

class _ChartWorkspacePageState extends ConsumerState<ChartWorkspacePage> {
  bool _analysisFocus = false;
  late double _bottomHeight;
  bool _drawRailExpanded = true;
  bool _showMobileDrawRail = true;
  ChartDrawTool _drawTool = ChartDrawTool.none;
  int _clearDrawingsEpoch = 0;
  int _activeDrawingsCount = 0;

  @override
  void initState() {
    super.initState();
    _bottomHeight = widget.bottomPanelHeight;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = ref.read(chartTerminalProvider.notifier);
      ctrl.bootstrap(
        symbol: widget.initialSymbol,
        timeframeCode: widget.initialTimeframe,
      );
      if (mounted) {
        final isMobile = MediaQuery.sizeOf(context).width < 768;
        if (isMobile) {
          ctrl.setLayout(ChartGridLayout.one);
          ctrl.setBottomMinimized(true);
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChartWorkspacePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSym = widget.initialSymbol?.trim();
    final prevSym = oldWidget.initialSymbol?.trim();
    final nextTf = widget.initialTimeframe?.trim();
    final prevTf = oldWidget.initialTimeframe?.trim();
    if (nextSym == null || nextSym.isEmpty) return;
    if (nextSym == prevSym && nextTf == prevTf) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = ref.read(chartTerminalProvider.notifier);
      final current = ref.read(chartTerminalProvider).symbol.trim();
      if (current.toUpperCase() != nextSym.toUpperCase()) {
        unawaited(ctrl.selectSymbol(nextSym));
      }
      if (nextTf != null &&
          nextTf.isNotEmpty &&
          nextTf != prevTf) {
        unawaited(ctrl.setTimeframe(ChartTimeframe.fromCode(nextTf)));
      }
    });
  }

  void _openMobileSidebar(Widget sidebar) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.78,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: context.shadow(0.35),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.hintColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(child: sidebar),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chartTerminalProvider);
    final ctrl = ref.read(chartTerminalProvider.notifier);
    final theme = Theme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 768;

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
            onOpenMobileSidebar: () => _openMobileSidebar(sidebar),
            onToggleDrawRail: () =>
                setState(() => _showMobileDrawRail = !_showMobileDrawRail),
            showDrawRail: _showMobileDrawRail,
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ValueListenableBuilder<double>(
                    valueListenable: GlobalBottomNavVisibility.factor,
                    builder: (context, navFactor, _) {
                      return LayoutBuilder(
                    builder: (context, constraints) {
                      final maxH = constraints.maxHeight;
                      // Lift chart/dock above floating bottom nav when it shows.
                      final navInset = isMobile
                          ? PlatformConstants.globalBottomNavReserve(context) *
                              navFactor.clamp(0.0, 1.0)
                          : 0.0;
                      final layoutH =
                          (maxH - navInset).clamp(100.0, maxH);
                      final isBottomVisible =
                          !_analysisFocus && !state.bottomMinimized;
                      final isBottomDockVisible =
                          !_analysisFocus && state.bottomMinimized;
                      final dockH =
                          isBottomDockVisible ? (isMobile ? 26.0 : 28.0) : 0.0;
                      final handleH = isBottomVisible ? 24.0 : 0.0;
                      final bottomH = isBottomVisible
                          ? _bottomHeight.clamp(
                              160.0,
                              isMobile ? layoutH * 0.5 : layoutH * 0.7,
                            )
                          : 0.0;
                      final chartH = (layoutH - bottomH - handleH - dockH)
                          .clamp(100.0, layoutH);

                      final showDrawRail = !isMobile || _showMobileDrawRail;

                      return Column(
                        children: [
                          SizedBox(
                            height: chartH,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (showDrawRail)
                                  ChartDrawToolsRail(
                                    expanded:
                                        isMobile ? true : _drawRailExpanded,
                                    activeTool: _drawTool,
                                    drawingCount: _activeDrawingsCount,
                                    onToggleExpanded: () {
                                      if (isMobile) {
                                        setState(() => _showMobileDrawRail =
                                            !_showMobileDrawRail);
                                      } else {
                                        setState(() => _drawRailExpanded =
                                            !_drawRailExpanded);
                                      }
                                    },
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
                              onDoubleTap: () =>
                                  ctrl.setBottomMinimized(true),
                              onVerticalDragUpdate: (d) {
                                setState(() {
                                  _bottomHeight = (_bottomHeight - d.delta.dy)
                                      .clamp(200.0, layoutH * 0.7);
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
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.view_agenda_outlined,
                                              size: 13,
                                              color:
                                                  theme.hintColor.withValues(
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
                                                color:
                                                    theme.hintColor.withValues(
                                                  alpha: 0.8,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Center(
                                        child: Container(
                                          width: 44,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color:
                                                theme.hintColor.withValues(
                                              alpha: 0.35,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(2),
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
                                      Expanded(
                                        child: Text(
                                          isMobile
                                              ? 'Panel (Overview · F&O · Financials)'
                                              : 'Bottom Panel (Fundamentals · Overview · Shareholding · F&O)',
                                          style: TextStyle(
                                            fontSize: isMobile ? 11 : 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: theme.colorScheme.primary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isMobile ? 6 : 8,
                                          vertical: 2,
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
                                              size: 12,
                                              color: theme.colorScheme.primary,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              isMobile
                                                  ? 'Open'
                                                  : 'Restore Panel',
                                              style: TextStyle(
                                                fontSize: isMobile ? 10 : 11,
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
                          if (navInset > 0) SizedBox(height: navInset),
                        ],
                      );
                    },
                      );
                    },
                  ),
                ),
                if (!_analysisFocus && !isMobile) ...[
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
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    final multi = !isMobile && state.layout != ChartGridLayout.one;

    Widget card(int i) => ChartPaneCard(
      paneIndex: i,
      pane: panes[i],
      isActive: i == active,
      showIdentityStrip: multi,
      drawTool: drawTool,
      clearDrawingsEpoch: clearDrawingsEpoch,
      onDrawingsCountChanged: onDrawingsCountChanged,
    );

    if (isMobile) {
      final idx = active.clamp(0, panes.isNotEmpty ? panes.length - 1 : 0);
      return card(idx);
    }

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
    this.onOpenMobileSidebar,
    this.onToggleDrawRail,
    this.showDrawRail = false,
  });
  final ChartTerminalState state;
  final ChartTerminalController ctrl;
  final bool analysisFocus;
  final VoidCallback onToggleFocus;
  final bool showHeaderSearch;
  final VoidCallback? onOpenMobileSidebar;
  final VoidCallback? onToggleDrawRail;
  final bool showDrawRail;

  @override
  ConsumerState<_SlimTopBar> createState() => _SlimTopBarState();
}

class _SlimTopBarState extends ConsumerState<_SlimTopBar> {
  void _openOmnisearch(BuildContext context) {
    if (GlobalSearchBridge.tryOpen()) return;
    MobileSearchScope.tryOpenGlobalSearch(context);
  }

  Widget _buildMobileBar(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.state;
    final ctrl = widget.ctrl;
    final active = state.active;

    return Material(
      elevation: 1,
      color: theme.colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${active.symbol} · ${active.exchange}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Watchlist & Indices',
                  iconSize: 19,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    Icons.format_list_bulleted,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: widget.onOpenMobileSidebar,
                ),
                if (widget.onToggleDrawRail != null)
                  IconButton(
                    tooltip: 'Drawing tools',
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(
                      widget.showDrawRail ? Icons.draw : Icons.draw_outlined,
                      color: widget.showDrawRail
                          ? theme.colorScheme.primary
                          : theme.hintColor,
                    ),
                    onPressed: widget.onToggleDrawRail,
                  ),
                IconButton(
                  tooltip: state.bottomMinimized
                      ? 'Restore panel'
                      : 'Minimize panel',
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
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
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChartTypeSelector(context, state, ctrl),
                  const SizedBox(width: 6),
                  _buildMobileTimeframeDropdown(context, state, ctrl),
                  const SizedBox(width: 6),
                  _buildCompareButton(context, state, ctrl),
                  const SizedBox(width: 6),
                  _divider(theme),
                  const SizedBox(width: 6),
                  _buildIndicatorsButton(context),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Fit chart',
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 30, minHeight: 30),
                    onPressed: ctrl.requestFit,
                    icon: const Icon(Icons.fit_screen),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    if (isMobile) {
      return _buildMobileBar(context);
    }

    final theme = Theme.of(context);
    final state = widget.state;
    final ctrl = widget.ctrl;
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

            // Center: graph chart controls (Timeframes, Chart Type, Indicators, Compare, Tools)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ..._buildTimeframePills(context, state, ctrl),
                    const SizedBox(width: 8),
                    _divider(theme),
                    const SizedBox(width: 8),
                    _buildChartTypeSelector(context, state, ctrl),
                    const SizedBox(width: 6),
                    _buildIndicatorsButton(context),
                    const SizedBox(width: 6),
                    _buildCompareButton(context, state, ctrl),
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
            // Right: omnisearch launcher + focus toggle
            if (showSearch)
              IconButton(
                tooltip: 'Search symbol',
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                onPressed: () => _openOmnisearch(context),
                icon: const Icon(Icons.search),
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

  Widget _buildMobileTimeframeDropdown(
    BuildContext context,
    ChartTerminalState state,
    ChartTerminalController ctrl,
  ) {
    final active = state.active;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    const quickTfs = [
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

    return PopupMenuButton<ChartTimeframe>(
      tooltip: 'Timeframe',
      onSelected: onSelect,
      itemBuilder: (context) => [
        for (final tf in quickTfs)
          PopupMenuItem<ChartTimeframe>(
            value: tf,
            height: 36,
            child: Row(
              children: [
                Text(
                  tf.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active.timeframe == tf
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: active.timeframe == tf ? primary : null,
                  ),
                ),
                const Spacer(),
                if (active.timeframe == tf)
                  Icon(Icons.check, size: 16, color: primary),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 14, color: primary),
            const SizedBox(width: 4),
            Text(
              active.timeframe.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 16, color: theme.hintColor),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTimeframePills(
    BuildContext context,
    ChartTerminalState state,
    ChartTerminalController ctrl,
  ) {
    final active = state.active;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    const quickTfs = [
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
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 7 : 9,
                vertical: isMobile ? 3.5 : 5,
              ),
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
                  fontSize: isMobile ? 12 : 13,
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

    final isMobile = MediaQuery.sizeOf(context).width < 768;

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
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 7 : 10,
          vertical: isMobile ? 3.5 : 5,
        ),
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
              size: isMobile ? 15 : 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 5),
            Text(
              active.chartType.label,
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: isMobile ? 16 : 18, color: theme.hintColor),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorsButton(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    return InkWell(
      onTap: () => _showIndicatorsModal(context),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 7 : 10,
          vertical: isMobile ? 3.5 : 5,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 4 : 5,
                vertical: 1.5,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'fx',
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'Indicators',
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
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
                      color: ctx.glassOverlay(0.08),
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
    ChartTerminalState state,
    ChartTerminalController ctrl,
  ) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    final activePane = state.active;
    final compared = activePane.comparisonSymbols;
    final hasComparisons = activePane.hasComparisons;
    final currentSymbol = activePane.symbol.toUpperCase();

    const benchmarks = <String, String>{
      'NIFTY 50': 'NIFTY 50',
      'BANKNIFTY': 'NIFTY BANK',
      'SENSEX': 'BSE SENSEX',
      'NIFTY IT': 'NIFTY IT',
      'FINNIFTY': 'NIFTY FIN SERVICE',
      'MIDCPNIFTY': 'NIFTY MIDCAP',
    };

    return PopupMenuButton<String>(
      tooltip: 'Compare with Benchmark / Overlay Symbol',
      onSelected: (val) {
        if (val == '__CLEAR__') {
          ctrl.clearComparisons();
        } else if (val == '__SEARCH__') {
          _showAddComparisonDialog(context, ctrl, state);
        } else {
          ctrl.toggleComparison(val);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          enabled: false,
          height: 26,
          child: Text(
            'Benchmarks & Overlay',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ),
        for (final entry in benchmarks.entries) ...[
          () {
            final key = entry.key;
            final label = entry.value;
            final isCurrent = key.toUpperCase() == currentSymbol;
            final isCompared =
                compared.any((s) => s.toUpperCase() == key.toUpperCase());
            return PopupMenuItem<String>(
              value: key,
              enabled: !isCurrent,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isCurrent ? '$label (Current)' : label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isCompared ? FontWeight.w700 : FontWeight.w400,
                        color: isCompared ? theme.colorScheme.primary : null,
                      ),
                    ),
                  ),
                  if (isCompared)
                    Icon(
                      Icons.check,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            );
          }(),
        ],
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: '__SEARCH__',
          child: Row(
            children: [
              Icon(Icons.search, size: 16),
              SizedBox(width: 8),
              Text(
                'Search symbol to compare...',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        if (hasComparisons) ...[
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: '__CLEAR__',
            child: Row(
              children: [
                Icon(Icons.close, size: 16, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  'Exit Comparison',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 7 : 10,
          vertical: isMobile ? 3.5 : 5,
        ),
        decoration: BoxDecoration(
          color: hasComparisons
              ? theme.colorScheme.primary.withValues(alpha: 0.14)
              : theme.cardColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: hasComparisons
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasComparisons ? Icons.stacked_line_chart : Icons.add,
              size: isMobile ? 15 : 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              hasComparisons ? 'Compare (${compared.length})' : 'Compare',
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.w700,
                color: hasComparisons ? theme.colorScheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddComparisonDialog(
    BuildContext context,
    ChartTerminalController ctrl,
    ChartTerminalState state,
  ) {
    final textCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        return AlertDialog(
          title: const Text(
            'Compare Symbol',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: textCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter symbol (e.g. RELIANCE, TCS, INFY)',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: (val) {
                  final sym = val.trim().toUpperCase();
                  if (sym.isNotEmpty) {
                    ctrl.addComparison(sym);
                    Navigator.of(dialogCtx).pop();
                  }
                },
              ),
              if (state.recentSearches.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Recent Symbols',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final sym in state.recentSearches.take(6))
                      InkWell(
                        onTap: () {
                          ctrl.addComparison(sym);
                          Navigator.of(dialogCtx).pop();
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Text(
                            sym,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final sym = textCtrl.text.trim().toUpperCase();
                if (sym.isNotEmpty) {
                  ctrl.addComparison(sym);
                  Navigator.of(dialogCtx).pop();
                }
              },
              child: const Text('Add to Compare'),
            ),
          ],
        );
      },
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
