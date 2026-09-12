import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../paper_oms_cubit.dart';
import '../../paper_oms_state.dart';
import 'mobile/paper_order_ticket_mobile.dart';
import 'order_ticket_controller.dart';
import 'web/paper_order_ticket_web.dart';

/// Groww-like order panel — theme / market tokens only; places via PaperOmsCubit.
class PaperOrderTicket extends StatefulWidget {
  const PaperOrderTicket({
    super.key,
    required this.symbol,
    this.side = 'BUY',
    this.onSymbolChanged,
    this.onSideChanged,
    this.onOrderPlaced,
    this.onOpenFundamentalAnalysis,
    this.compact = false,
    this.floating = false,
    this.onToggleFloat,
    this.onCloseFloat,
    this.onHeaderDragUpdate,
    this.onHeaderDragEnd,
  });

  final String symbol;
  final String side;
  final ValueChanged<String>? onSymbolChanged;
  final ValueChanged<String>? onSideChanged;

  /// Called after a successful place (filled or working), before toast.
  final VoidCallback? onOrderPlaced;

  /// Opens full fundamental analysis (Desk → Overview) for the ticket symbol.
  final VoidCallback? onOpenFundamentalAnalysis;

  /// Mobile half-sheet: denser layout, fewer chrome blocks.
  final bool compact;

  /// When true, show float/close controls and enable header drag.
  final bool floating;
  final VoidCallback? onToggleFloat;
  final VoidCallback? onCloseFloat;
  final GestureDragUpdateCallback? onHeaderDragUpdate;
  final GestureDragEndCallback? onHeaderDragEnd;

  @override
  State<PaperOrderTicket> createState() => _PaperOrderTicketState();
}

class _PaperOrderTicketState extends State<PaperOrderTicket> {
  late final OrderTicketController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OrderTicketController();
    _syncCallbacks();
    _controller.init(
      compact: widget.compact,
      side: widget.side,
      symbol: widget.symbol,
    );
  }

  @override
  void didUpdateWidget(covariant PaperOrderTicket oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncCallbacks();
    _controller.syncFromWidget(symbol: widget.symbol, side: widget.side);
  }

  void _syncCallbacks() {
    _controller.onSideChanged = widget.onSideChanged;
    _controller.onOrderPlaced = widget.onOrderPlaced;
  }

  @override
  void dispose() {
    _controller.dispose();
    _controller.disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaperOmsCubit, PaperOmsState>(
      builder: (context, state) {
        return ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (widget.compact) {
              return PaperOrderTicketMobile(
                controller: _controller,
                symbol: widget.symbol,
                wallet: state.wallet,
                submitting: state.submitting,
                onOpenFundamentalAnalysis: widget.onOpenFundamentalAnalysis,
                onCloseFloat: widget.onCloseFloat,
              );
            }
            return PaperOrderTicketWeb(
              controller: _controller,
              symbol: widget.symbol,
              wallet: state.wallet,
              submitting: state.submitting,
              onOpenFundamentalAnalysis: widget.onOpenFundamentalAnalysis,
              floating: widget.floating,
              onToggleFloat: widget.onToggleFloat,
              onCloseFloat: widget.onCloseFloat,
              onHeaderDragUpdate: widget.onHeaderDragUpdate,
              onHeaderDragEnd: widget.onHeaderDragEnd,
            );
          },
        );
      },
    );
  }
}
