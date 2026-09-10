import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../paper_oms_cubit.dart';
import '../paper_oms_state.dart';
import '../widgets/paper_analyser_pane.dart';
import '../widgets/paper_holdings_pane.dart';
import '../widgets/paper_order_ticket.dart';
import '../widgets/paper_orders_pane.dart';
import '../widgets/paper_positions_pnl_pane.dart';
import '../widgets/paper_wallet_pane.dart';
import '../widgets/paper_watchlist_pane.dart';

enum _TicketPlacement {
  floatTopRight,
  floatBottomNearWatchlist,
  free,
}

enum _MidTab { wallet, overview, orders, holdings, positions }

class PaperDeskScreen extends StatefulWidget {
  const PaperDeskScreen({super.key});

  @override
  State<PaperDeskScreen> createState() => _PaperDeskScreenState();
}

class _PaperDeskScreenState extends State<PaperDeskScreen> {
  static const _ticketWidth = 340.0;

  String _symbol = '';
  String _side = 'BUY';
  _MidTab _midTab = _MidTab.wallet;
  bool _orderOpen = false;
  _TicketPlacement _placement = _TicketPlacement.floatTopRight;
  Offset _ticketOffset = Offset.zero;
  Size _deskSize = Size.zero;

  /// Narrow layout: sync Trade tab when B/S opens order.
  final _narrowTabs = GlobalKey<_NarrowDeskTabsState>();

  bool get _hasSymbol => _symbol.trim().isNotEmpty;

  void _selectSymbol(String symbol) {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return;
    setState(() {
      _symbol = sym;
      _midTab = _MidTab.overview;
    });
  }

  void _buySell(String symbol, String side) {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return;
    setState(() {
      _symbol = sym;
      _side = side.toUpperCase() == 'SELL' ? 'SELL' : 'BUY';
      _orderOpen = true;
      if (_ticketOffset == Offset.zero && _deskSize != Size.zero) {
        _placement = _TicketPlacement.floatTopRight;
        _ticketOffset = _snapTopRight(_deskSize);
      } else if (_deskSize != Size.zero &&
          _placement == _TicketPlacement.floatTopRight) {
        _ticketOffset = _snapTopRight(_deskSize);
      }
    });
    _narrowTabs.currentState?.goToTrade();
  }

  void _closeOrderPopup() {
    setState(() => _orderOpen = false);
  }

  void _cycleFloat() {
    if (!_orderOpen || !_hasSymbol) return;
    setState(() {
      switch (_placement) {
        case _TicketPlacement.floatTopRight:
          _placement = _TicketPlacement.floatBottomNearWatchlist;
          _ticketOffset = _snapBottomNearWatchlist(_deskSize);
        case _TicketPlacement.floatBottomNearWatchlist:
          _placement = _TicketPlacement.floatTopRight;
          _ticketOffset = _snapTopRight(_deskSize);
        case _TicketPlacement.free:
          _placement = _TicketPlacement.floatTopRight;
          _ticketOffset = _snapTopRight(_deskSize);
      }
    });
  }

  Offset _snapTopRight(Size size) {
    if (size.width <= 0 || size.height <= 0) return const Offset(12, 12);
    return Offset(
      (size.width - _ticketWidth - 12).clamp(0, size.width),
      12,
    );
  }

  Offset _snapBottomNearWatchlist(Size size) {
    if (size.width <= 0 || size.height <= 0) return const Offset(12, 12);
    const watchlistWidth = 300.0;
    const ticketApproxHeight = 520.0;
    final left = 12.0;
    final top =
        (size.height - ticketApproxHeight - 12).clamp(12.0, size.height);
    return Offset(left.clamp(0, watchlistWidth), top);
  }

  Offset _clampOffset(Offset raw, Size size) {
    if (size.width <= 0 || size.height <= 0) return raw;
    const minVisible = 48.0;
    final maxX = (size.width - minVisible).clamp(0.0, size.width);
    final maxY = (size.height - minVisible).clamp(0.0, size.height);
    return Offset(
      raw.dx.clamp(0.0, maxX),
      raw.dy.clamp(0.0, maxY),
    );
  }

  void _onHeaderDragUpdate(DragUpdateDetails details) {
    setState(() {
      _placement = _TicketPlacement.free;
      _ticketOffset = _clampOffset(_ticketOffset + details.delta, _deskSize);
    });
  }

  void _onOrderPlaced() {
    setState(() {
      _midTab = _MidTab.orders;
      // Keep popup open so user sees confirmation toast; they can close it.
    });
  }

  Widget _ticket({required bool floating}) {
    return PaperOrderTicket(
      symbol: _symbol,
      side: _side,
      onSymbolChanged: (s) {
        final sym = s.trim().toUpperCase();
        if (sym.isEmpty) return;
        setState(() => _symbol = sym);
      },
      onSideChanged: (s) => setState(() => _side = s),
      onOrderPlaced: _onOrderPlaced,
      floating: floating,
      onToggleFloat: floating ? _cycleFloat : null,
      onCloseFloat: floating ? _closeOrderPopup : null,
      onHeaderDragUpdate: floating ? _onHeaderDragUpdate : null,
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

  Widget _midPane(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: colors.surface,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final t in const [
                  (_MidTab.wallet, 'Wallet'),
                  (_MidTab.overview, 'Overview'),
                  (_MidTab.orders, 'Orders'),
                  (_MidTab.holdings, 'Holdings'),
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
        Divider(height: 1, color: colors.divider),
        Expanded(child: _midBody(context)),
      ],
    );
  }

  Widget _midBody(BuildContext context) {
    switch (_midTab) {
      case _MidTab.wallet:
        return const PaperWalletPane();
      case _MidTab.overview:
        if (!_hasSymbol) {
          return Center(
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
          );
        }
        return PaperAnalyserPane(symbol: _symbol);
      case _MidTab.orders:
        return const PaperOrdersPane();
      case _MidTab.holdings:
        return const PaperHoldingsPane();
      case _MidTab.positions:
        return const PaperPositionsPnlPane();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaperOmsCubit, PaperOmsState>(
      listenWhen: (p, c) => c.toast != null && c.toast != p.toast,
      listener: (context, state) {
        final toast = state.toast;
        if (toast == null) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(toast)));
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1100;
          if (!wide) {
            return _NarrowDeskTabs(
              key: _narrowTabs,
              header: _header(context),
              symbol: _symbol,
              hasSymbol: _hasSymbol,
              onSelectSymbol: _selectSymbol,
              onBuySell: _buySell,
              ticket: _hasSymbol
                  ? _ticket(floating: false)
                  : Center(
                      child: Text(
                        'Select a symbol from the watchlist',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                      ),
                    ),
              midTabBar: _midPane,
            );
          }

          return Column(
            children: [
              _header(context),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: LayoutBuilder(
                    builder: (context, deskConstraints) {
                      final deskSize = Size(
                        deskConstraints.maxWidth,
                        deskConstraints.maxHeight,
                      );
                      if (deskSize != _deskSize) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          setState(() {
                            _deskSize = deskSize;
                            if (!_orderOpen) return;
                            if (_placement ==
                                _TicketPlacement.floatTopRight) {
                              _ticketOffset = _snapTopRight(deskSize);
                            } else if (_placement ==
                                _TicketPlacement.floatBottomNearWatchlist) {
                              _ticketOffset =
                                  _snapBottomNearWatchlist(deskSize);
                            } else if (_placement == _TicketPlacement.free) {
                              _ticketOffset =
                                  _clampOffset(_ticketOffset, deskSize);
                            }
                          });
                        });
                      }

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: 300,
                                child: _framed(
                                  PaperWatchlistPane(
                                    selectedSymbol: _symbol,
                                    onSelectSymbol: _selectSymbol,
                                    onBuySell: _buySell,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _framed(_midPane(context)),
                              ),
                            ],
                          ),
                          if (_orderOpen && _hasSymbol)
                            Positioned(
                              left: _ticketOffset.dx,
                              top: _ticketOffset.dy,
                              width: _ticketWidth,
                              height: (deskSize.height * 0.92)
                                  .clamp(320.0, deskSize.height),
                              child: Material(
                                elevation: 12,
                                borderRadius: BorderRadius.circular(10),
                                clipBehavior: Clip.antiAlias,
                                color: context.colors.scaffoldBackground,
                                child: _ticket(floating: true),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context) {
    return BlocBuilder<PaperOmsCubit, PaperOmsState>(
      builder: (context, state) {
        final w = state.wallet;
        return Material(
          color: context.colors.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text(
                  'Paper desk',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(width: 16),
                if (w != null)
                  Expanded(
                    child: Text(
                      'Virtual cash ₹${w.available} (reserved ₹${w.reserved}) · not live money',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Narrow: Watchlist | Trade | Desk (Wallet/Overview/…)
class _NarrowDeskTabs extends StatefulWidget {
  const _NarrowDeskTabs({
    super.key,
    required this.header,
    required this.symbol,
    required this.hasSymbol,
    required this.onSelectSymbol,
    required this.onBuySell,
    required this.ticket,
    required this.midTabBar,
  });

  final Widget header;
  final String symbol;
  final bool hasSymbol;
  final ValueChanged<String> onSelectSymbol;
  final void Function(String symbol, String side) onBuySell;
  final Widget ticket;
  final Widget Function(BuildContext context) midTabBar;

  @override
  State<_NarrowDeskTabs> createState() => _NarrowDeskTabsState();
}

class _NarrowDeskTabsState extends State<_NarrowDeskTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void goToTrade() {
    if (_tabs.index != 1) _tabs.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widget.header,
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Watchlist'),
            Tab(text: 'Trade'),
            Tab(text: 'Desk'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              PaperWatchlistPane(
                selectedSymbol: widget.symbol,
                onSelectSymbol: widget.onSelectSymbol,
                onBuySell: widget.onBuySell,
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: widget.ticket,
              ),
              widget.midTabBar(context),
            ],
          ),
        ),
      ],
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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? colors.actionPrimaryBg : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? colors.actionPrimaryBg : colors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
