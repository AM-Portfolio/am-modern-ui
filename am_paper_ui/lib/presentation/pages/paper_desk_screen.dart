import 'dart:async';

import 'package:am_chart_ui/am_chart_ui.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../config/paper_chart_trade_ui_config.dart';
import '../../data/oms_models.dart';
import '../paper_oms_cubit.dart';
import '../paper_oms_state.dart';
import '../widgets/paper_chart_embed.dart';
import '../widgets/paper_chart_trade_lines_controller.dart';
import '../widgets/paper_order_ticket.dart';
import '../widgets/paper_order_ticket_sheet.dart';
import '../widgets/paper_orders_pane.dart';
import '../widgets/paper_positions_pnl_pane.dart';
import '../widgets/paper_wallet_pane.dart';
import '../widgets/paper_watchlist_pane.dart';

enum _MidTab { wallet, orders, chart, positions }

class PaperDeskScreen extends StatefulWidget {
  const PaperDeskScreen({super.key});

  @override
  State<PaperDeskScreen> createState() => _PaperDeskScreenState();
}

class _PaperDeskScreenState extends State<PaperDeskScreen> {
  static const _wideBreakpoint = 1100.0;
  static const _watchlistMinWidth = 240.0;
  static const _watchlistMaxWidth = 520.0;
  static const _watchlistDefaultWidth = 300.0;
  static const _ticketDockMaxHeight = 320.0;
  static const _ticketDockMinHeight = 220.0;

  String _symbol = '';
  /// Order ticket symbol — independent of chart `_symbol` so B/S does not remount the chart.
  String _ticketSymbol = '';
  String _side = 'BUY';
  _MidTab _midTab = _MidTab.wallet;
  bool _orderOpen = false;
  double _watchlistWidth = _watchlistDefaultWidth;

  PaperChartTradeUiConfig _tradeUiConfig = PaperChartTradeUiConfig.defaults();
  PaperChartTradeLinesController? _tradeLines;

  /// Narrow layout: show Desk (FA / orders) without Watchlist|Desk tabs.
  final _narrowTabs = GlobalKey<_NarrowDeskBodyState>();
  bool _narrowShowDesk = false;

  bool get _hasSymbol => _symbol.trim().isNotEmpty;
  bool get _hasTicketSymbol => _ticketSymbol.trim().isNotEmpty;

  String get _midTabKey => switch (_midTab) {
        _MidTab.wallet => 'wallet',
        _MidTab.orders => 'orders',
        _MidTab.chart => 'chart',
        _MidTab.positions => 'positions',
      };

  bool get _showWatchlistBuySell => _tradeUiConfig.showBuySell(
        PaperBuySellSurface.watchlist,
        midTab: _midTabKey,
      );

  bool get _showPositionsBuySell =>
      _tradeUiConfig.showBuySell(PaperBuySellSurface.positions);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_bootstrapTradeUi());
    });
  }

  Future<void> _bootstrapTradeUi() async {
    final cfg = await PaperChartTradeUiConfig.loadAsset();
    if (!mounted) return;
    final cubit = context.read<PaperOmsCubit>();
    final ctrl = PaperChartTradeLinesController(
      config: cfg,
      placeOrder: ({
        required String symbol,
        required String side,
        required String orderType,
        required String quantity,
        String? limitPrice,
        String? triggerPrice,
        String? targetPrice,
        String? stopLoss,
        String? trailJump,
        String? entryType,
      }) =>
          cubit.placeOrder(
            symbol: symbol,
            side: side,
            orderType: orderType,
            quantity: quantity,
            limitPrice: limitPrice,
            triggerPrice: triggerPrice,
            targetPrice: targetPrice,
            stopLoss: stopLoss,
            trailJump: trailJump,
            entryType: entryType,
          ),
      cancelOrder: cubit.cancel,
    );
    setState(() {
      _tradeUiConfig = cfg;
      _tradeLines = ctrl;
    });
  }

  @override
  void dispose() {
    _tradeLines?.dispose();
    super.dispose();
  }

  void _openChart(String symbol) {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return;
    setState(() {
      _symbol = sym;
      _midTab = _MidTab.chart;
      _orderOpen = false;
      _narrowShowDesk = true;
    });
    _narrowTabs.currentState?.showDesk();
  }

  bool _isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= _wideBreakpoint;

  void _selectSymbol(String symbol) {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return;
    setState(() {
      _symbol = sym;
      if (_midTab == _MidTab.wallet) {
        _midTab = _MidTab.chart;
      }
    });
  }

  void _openFundamentalAnalysis([String? symbol]) {
    // Overview lives in the Chart bottom panel now.
    _openChart(symbol ?? _symbol);
  }

  Future<void> _buySell(String symbol, String side) async {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return;
    final nextSide = side.toUpperCase() == 'SELL' ? 'SELL' : 'BUY';

    final tl = _tradeLines;
    final useTradeLine = _isWide(context) &&
        _midTab == _MidTab.chart &&
        tl != null &&
        _tradeUiConfig.tradeLinesEnabled &&
        _tradeUiConfig.placeFromWatchlistBuySell;

    if (useTradeLine) {
      final fav = context
          .read<PaperOmsCubit>()
          .state
          .orderTypeFavorite
          .trim()
          .toUpperCase();
      var orderType = fav;
      if (orderType.isEmpty ||
          orderType == 'MARKET' ||
          !_tradeUiConfig.enabledOrderTypes.contains(orderType)) {
        orderType = _tradeUiConfig.resolveDefaultOrderType();
        if (orderType == 'MARKET') orderType = 'LIMIT';
      }
      setState(() {
        _symbol = sym;
        _midTab = _MidTab.chart;
      });
      tl.armPending(
        symbol: sym,
        side: nextSide == 'SELL'
            ? ChartTradeLineSide.sell
            : ChartTradeLineSide.buy,
        orderType: orderType,
        quantity: _tradeUiConfig.resolveDefaultQuantity(),
      );
      return;
    }

    if (!_isWide(context)) {
      setState(() {
        _ticketSymbol = sym;
        _side = nextSide;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showPaperOrderTicketSheet(
          context: context,
          symbol: sym,
          side: nextSide,
          onSymbolChanged: (s) {
            final next = s.trim().toUpperCase();
            if (next.isEmpty) return;
            setState(() => _ticketSymbol = next);
          },
          onSideChanged: (s) => setState(() => _side = s),
          onOrderPlaced: _onOrderPlaced,
        );
      });
      return;
    }

    setState(() {
      _ticketSymbol = sym;
      _side = nextSide;
      _orderOpen = true;
    });
  }

  void _reorderOrder(OmsOrder order) {
    _buySell(order.symbol, order.side);
  }

  void _closeOrderPopup() {
    setState(() => _orderOpen = false);
  }

  void _onOrderPlaced() {
    setState(() {
      _midTab = _MidTab.orders;
      _orderOpen = false;
      _narrowShowDesk = true;
    });
    _narrowTabs.currentState?.showDesk();
  }

  Widget _ticket() {
    return PaperOrderTicket(
      symbol: _ticketSymbol,
      side: _side,
      onSymbolChanged: (s) {
        final sym = s.trim().toUpperCase();
        if (sym.isEmpty) return;
        setState(() => _ticketSymbol = sym);
      },
      onSideChanged: (s) => setState(() => _side = s),
      onOrderPlaced: _onOrderPlaced,
      compact: true,
      floating: false,
      onCloseFloat: _closeOrderPopup,
    );
  }

  Widget _dockedTicket(BuildContext context, double maxHeight) {
    final colors = context.colors;
    final h = maxHeight
        .clamp(_ticketDockMinHeight, _ticketDockMaxHeight)
        .toDouble();
    return SizedBox(
      height: h,
      child: Material(
        color: colors.scaffoldBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 1,
              color: colors.divider,
            ),
            SizedBox(
              height: 10,
              child: Center(
                child: Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Expanded(child: _ticket()),
          ],
        ),
      ),
    );
  }

  Widget _framed(Widget child) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
    );
  }

  Widget _midPane(BuildContext context, {VoidCallback? onBack}) {
    final colors = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final showDock = _orderOpen && _hasTicketSymbol;
        final dockCap = (constraints.maxHeight * 0.32)
            .clamp(_ticketDockMinHeight, _ticketDockMaxHeight)
            .toDouble();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: colors.surface,
              child: Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      tooltip: 'Back to watchlist',
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                      visualDensity: VisualDensity.compact,
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final t in const [
                            (_MidTab.wallet, 'Wallet'),
                            (_MidTab.orders, 'Orders'),
                            (_MidTab.chart, 'Chart'),
                            (_MidTab.positions, 'Positions'),
                          ])
                            _MidTabChip(
                              label: t.$2,
                              selected: _midTab == t.$1,
                              onTap: () => setState(() => _midTab = t.$1),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.divider),
            Expanded(child: _midBody(context)),
            if (showDock) _dockedTicket(context, dockCap),
          ],
        );
      },
    );
  }

  Widget _midBody(BuildContext context) {
    final index = switch (_midTab) {
      _MidTab.wallet => 0,
      _MidTab.orders => 1,
      _MidTab.chart => 2,
      _MidTab.positions => 3,
    };
    return IndexedStack(
      index: index,
      sizing: StackFit.expand,
      children: [
        const PaperWalletPane(),
        PaperOrdersPane(onReorder: _reorderOrder),
        if (_hasSymbol)
          PaperChartEmbed(
            symbol: _symbol,
            tradeLinesController: _tradeLines,
          )
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Select a symbol from the watchlist',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
              ),
            ),
          ),
        PaperPositionsPnlPane(
          onBuySell: _showPositionsBuySell ? _buySell : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PaperChartTradeUiScope(
      config: _tradeUiConfig,
      child: MultiBlocListener(
        listeners: [
          BlocListener<PaperOmsCubit, PaperOmsState>(
            listenWhen: (p, c) => c.toast != null && c.toast != p.toast,
            listener: (context, state) {
              final toast = state.toast;
              if (toast == null) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(toast)));
            },
          ),
          BlocListener<PaperOmsCubit, PaperOmsState>(
            listenWhen: (p, c) => p.orders != c.orders,
            listener: (context, state) {
              _tradeLines?.syncFromOrders(state.orders, _symbol);
            },
          ),
        ],
        child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _wideBreakpoint;
          if (!wide) {
            return _NarrowDeskBody(
              key: _narrowTabs,
              symbol: _symbol,
              hasSymbol: _hasSymbol,
              midTab: _midTab,
              showDesk: _narrowShowDesk,
              onShowDeskChanged: (v) => setState(() => _narrowShowDesk = v),
              onSelectSymbol: _selectSymbol,
              onBuySell: _buySell,
              onOpenFundamentals: _openFundamentalAnalysis,
              onOpenChart: _openChart,
              showBuySell: _showWatchlistBuySell,
              midTabBar: (ctx) => _midPane(
                ctx,
                onBack: () => setState(() => _narrowShowDesk = false),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: _watchlistWidth,
                        child: _framed(
                          PaperWatchlistPane(
                            selectedSymbol: _symbol,
                            onSelectSymbol: _selectSymbol,
                            onBuySell: _buySell,
                            onOpenFundamentals: _openFundamentalAnalysis,
                            onOpenChart: _openChart,
                            showSearch: false,
                            showBuySell: _showWatchlistBuySell,
                          ),
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeColumn,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragUpdate: (details) {
                            setState(() {
                              _watchlistWidth =
                                  (_watchlistWidth + details.delta.dx).clamp(
                                _watchlistMinWidth,
                                _watchlistMaxWidth,
                              );
                            });
                          },
                          child: SizedBox(
                            width: 6,
                            child: Center(
                              child: Container(
                                width: 2,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: context.colors.divider,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _framed(_midPane(context)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}

enum _NarrowSurface { watchlist, positions }

/// Narrow: Watchlist | Positions always reachable; desk mid-pane opens for FA/orders.
class _NarrowDeskBody extends StatefulWidget {
  const _NarrowDeskBody({
    super.key,
    required this.symbol,
    required this.hasSymbol,
    required this.midTab,
    required this.showDesk,
    required this.onShowDeskChanged,
    required this.onSelectSymbol,
    required this.onBuySell,
    required this.onOpenFundamentals,
    required this.onOpenChart,
    required this.midTabBar,
    this.showBuySell = true,
  });

  final String symbol;
  final bool hasSymbol;
  final _MidTab midTab;
  final bool showDesk;
  final ValueChanged<bool> onShowDeskChanged;
  final ValueChanged<String> onSelectSymbol;
  final void Function(String symbol, String side) onBuySell;
  final ValueChanged<String> onOpenFundamentals;
  final ValueChanged<String> onOpenChart;
  final Widget Function(BuildContext context) midTabBar;
  final bool showBuySell;

  @override
  State<_NarrowDeskBody> createState() => _NarrowDeskBodyState();
}

class _NarrowDeskBodyState extends State<_NarrowDeskBody> {
  _NarrowSurface _surface = _NarrowSurface.watchlist;

  void showDesk() {
    widget.onShowDeskChanged(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = ModuleColors.market;
    final showChart = widget.midTab == _MidTab.chart;

    Widget body;
    if (widget.showDesk) {
      body = widget.midTabBar(context);
    } else if (_surface == _NarrowSurface.positions) {
      body = PaperPositionsPnlPane(
        onBuySell: widget.showBuySell ? widget.onBuySell : null,
      );
    } else {
      body = PaperWatchlistPane(
        selectedSymbol: widget.symbol,
        onSelectSymbol: widget.onSelectSymbol,
        onBuySell: widget.onBuySell,
        onOpenFundamentals: widget.onOpenFundamentals,
        onOpenChart: widget.onOpenChart,
        compactChrome: true,
        showSearch: false,
        showBuySell: widget.showBuySell,
      );
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              body,
              if (widget.hasSymbol)
                Offstage(
                  offstage: true,
                  child: TickerMode(
                    enabled: !showChart || !widget.showDesk,
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width,
                      height: MediaQuery.sizeOf(context).height,
                      child: PaperChartEmbed(symbol: widget.symbol),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (!widget.showDesk)
          Material(
            color: colors.surface,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: _NarrowSurfaceChip(
                      label: 'Watchlist',
                      selected: _surface == _NarrowSurface.watchlist,
                      accent: accent,
                      onTap: () => setState(
                        () => _surface = _NarrowSurface.watchlist,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _NarrowSurfaceChip(
                      label: 'Positions',
                      selected: _surface == _NarrowSurface.positions,
                      accent: accent,
                      onTap: () => setState(
                        () => _surface = _NarrowSurface.positions,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _NarrowSurfaceChip extends StatelessWidget {
  const _NarrowSurfaceChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colors.divider),
            bottom: BorderSide(
              color: selected ? accent : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? accent : colors.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _MidTabChip extends StatelessWidget {
  const _MidTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Paper lives under Market — match sidebar / Equity Insider cyan.
    final accent = ModuleColors.market;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? accent : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? accent : colors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
