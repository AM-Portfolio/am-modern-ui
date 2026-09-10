import 'dart:convert';

import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../data/paper_market_client.dart';
import '../../data/quote_models.dart';
import '../paper_oms_cubit.dart';
import '../paper_oms_state.dart';

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
  final _client = PaperMarketClient();
  final _qty = TextEditingController(text: '1');
  final _limit = TextEditingController();
  final _target = TextEditingController();
  final _stop = TextEditingController();
  final _trail = TextEditingController(text: '5');
  final _trigger = TextEditingController();

  late String _side;
  String _orderType = 'SUPER';
  String _entryType = 'LIMIT';
  String _productMode = 'Investing';
  String _exchange = 'NSE';
  bool _useLimit = true;
  bool _useTarget = true;
  bool _useStop = true;
  bool _showTrigger = false;
  bool _bookProfitsOpen = true;
  bool _quoteLoading = false;
  bool _localSubmitting = false;
  QuoteDetail? _quote;
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _side = widget.side.toUpperCase() == 'SELL' ? 'SELL' : 'BUY';
    _displayName = widget.symbol;
    _bookProfitsOpen = !widget.compact;
    if (widget.compact) {
      // Faster mobile default — Market fills without extra SUPER fields.
      _orderType = 'MARKET';
      _useLimit = false;
      _entryType = 'MARKET';
    }
    if (widget.symbol.trim().isNotEmpty) {
      _loadQuote(widget.symbol);
    }
  }

  @override
  void didUpdateWidget(covariant PaperOrderTicket oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.symbol != oldWidget.symbol && widget.symbol.trim().isNotEmpty) {
      _loadQuote(widget.symbol);
    }
    if (widget.side != oldWidget.side) {
      final next = widget.side.toUpperCase() == 'SELL' ? 'SELL' : 'BUY';
      if (next != _side) setState(() => _side = next);
    }
  }

  @override
  void dispose() {
    _qty.dispose();
    _limit.dispose();
    _target.dispose();
    _stop.dispose();
    _trail.dispose();
    _trigger.dispose();
    super.dispose();
  }

  Future<void> _loadQuote(String symbol) async {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return;
    // #region agent log
    http
        .post(
          Uri.parse(
            'http://127.0.0.1:7626/ingest/0d1c8c7b-9f69-4195-beee-fbf3af51620e',
          ),
          headers: {
            'Content-Type': 'application/json',
            'X-Debug-Session-Id': 'c7037f',
          },
          body: jsonEncode({
            'sessionId': 'c7037f',
            'runId': 'post-fix',
            'hypothesisId': 'A',
            'location': 'paper_order_ticket.dart:_loadQuote',
            'message': 'ticket loadQuote with forceRefresh=false (cache)',
            'data': {'symbol': sym},
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }),
        )
        .catchError((_) => http.Response('', 599));
    // #endregion
    setState(() {
      _quoteLoading = true;
      _displayName = sym;
    });
    final detail = await _client.fetchQuoteDetail(
      sym,
      name: _displayName,
      forceRefresh: false,
    );
    if (!mounted) return;
    setState(() {
      _quote = detail;
      _quoteLoading = false;
      if (detail?.name != null && detail!.name!.isNotEmpty) {
        _displayName = detail.name!;
      }
      final ex = (detail?.exchange ?? 'NSE').toUpperCase();
      _exchange = ex == 'BSE' ? 'BSE' : 'NSE';
      _seedPricesFromLtp(force: true);
    });
  }

  void _seedPricesFromLtp({required bool force}) {
    final ltp = _quote?.ltp ?? 0;
    if (ltp <= 0) return;
    final fmt = ltp.toStringAsFixed(2);
    if (force || _limit.text.trim().isEmpty) _limit.text = fmt;
    if (force || _target.text.trim().isEmpty) {
      _target.text = (ltp * 1.025).toStringAsFixed(2);
    }
    if (force || _stop.text.trim().isEmpty) {
      _stop.text = (ltp * 0.975).toStringAsFixed(2);
    }
  }

  void _setSide(String side) {
    setState(() => _side = side);
    widget.onSideChanged?.call(side);
  }

  void _setOrderType(String type) {
    setState(() {
      _orderType = type;
      if (type == 'SUPER') {
        _useLimit = true;
        _entryType = 'LIMIT';
        _seedPricesFromLtp(force: false);
      } else if (type == 'LIMIT') {
        _seedPricesFromLtp(force: false);
      }
    });
  }

  void _bump(TextEditingController c, double delta) {
    final cur = double.tryParse(c.text.trim()) ?? 0;
    c.text = (cur + delta).clamp(0.0, 1e9).toStringAsFixed(2);
    setState(() {});
  }

  void _bumpQty(int delta) {
    final cur = int.tryParse(_qty.text.trim()) ?? 1;
    _qty.text = '${(cur + delta).clamp(1, 1000000)}';
    setState(() {});
  }

  Future<void> _submit() async {
    final sym = widget.symbol.trim().toUpperCase();
    if (sym.isEmpty || _qty.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a symbol and enter quantity')),
      );
      return;
    }
    if (_localSubmitting) return;
    // Do not call onSymbolChanged here — parent setState remounts mid-pane
    // (Equity Insider) and floods the network while the order is in flight.

    setState(() => _localSubmitting = true);
    try {
      // Prefer ticket LTP already on screen; otherwise one live-ltp only
      // (not quotes + live-ltp) so Instant Buy is not stalled by watchlist.
      var ltp = _quote?.ltp ?? 0;
      if (ltp <= 0) {
        ltp = await _client.fetchLiveLtp(sym, forceRefresh: false);
        if (!mounted) return;
        if (ltp > 0) {
          setState(() {
            _quote = QuoteDetail(
              symbol: sym,
              name: _displayName,
              exchange: _quote?.exchange ?? 'NSE',
              ltp: ltp,
              change: _quote?.change ?? 0,
              changePercent: _quote?.changePercent ?? 0,
              open: _quote?.open,
              high: _quote?.high,
              low: _quote?.low,
              previousClose: _quote?.previousClose,
              buyDepth: _quote?.buyDepth ?? const [],
              sellDepth: _quote?.sellDepth ?? const [],
            );
          });
        }
      }
      if (ltp <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live quote unavailable — try again')),
        );
        return;
      }

      final needsLimit = _orderType == 'LIMIT' ||
          (_orderType == 'SUPER' && _useLimit && _entryType == 'LIMIT');
      String? target;
      String? stop;
      if (_orderType == 'SUPER') {
        if (_useTarget && _target.text.trim().isNotEmpty) {
          target = _target.text.trim();
        }
        if (_useStop && _stop.text.trim().isNotEmpty) {
          stop = _stop.text.trim();
        }
        if (target == null && stop == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enable Target and/or Stop Loss for SUPER'),
            ),
          );
          return;
        }
      }

      final order = await context.read<PaperOmsCubit>().placeOrder(
            symbol: sym,
            side: _side,
            orderType: _orderType,
            quantity: _qty.text.trim(),
            limitPrice: needsLimit ? _limit.text.trim() : null,
            targetPrice: target,
            stopLoss: stop,
            trailJump: _orderType == 'TRAIL' ? _trail.text.trim() : null,
            entryType: _orderType == 'SUPER'
                ? (_useLimit ? 'LIMIT' : 'MARKET')
                : null,
            triggerPrice: _showTrigger && _trigger.text.trim().isNotEmpty
                ? _trigger.text.trim()
                : null,
          );
      if (!mounted) return;
      if (order != null && !order.isRejected) {
        widget.onOrderPlaced?.call();
      }
    } finally {
      if (mounted) setState(() => _localSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isBuy = _side == 'BUY';
    final ctaColor =
        isBuy ? colors.marketPositiveIndicator : colors.marketNegativeIndicator;
    final fmt = NumberFormat('#,##0.00');
    final ltp = _quote?.ltp ?? 0;
    final change = _quote?.change ?? 0;
    final changePct = _quote?.changePercent ?? 0;
    final priceColor = change < 0
        ? colors.marketNegativeIndicator
        : change > 0
            ? colors.marketPositiveIndicator
            : colors.textPrimary;
    final sym = widget.symbol.trim().toUpperCase();

    return BlocBuilder<PaperOmsCubit, PaperOmsState>(
      builder: (context, state) {
        final wallet = state.wallet;
        final compact = widget.compact;
        final pad = compact
            ? const EdgeInsets.fromLTRB(12, 6, 12, 4)
            : const EdgeInsets.fromLTRB(14, 12, 14, 8);
        return Material(
          color: colors.scaffoldBackground,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: pad,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeaderBlock(
                        title: sym.isEmpty
                            ? 'Select a stock'
                            : (_displayName.isNotEmpty ? _displayName : sym),
                        loading: _quoteLoading,
                        ltp: ltp,
                        change: change,
                        changePct: changePct,
                        priceColor: priceColor,
                        fmt: fmt,
                        quote: _quote,
                        isBuy: isBuy,
                        compact: compact,
                        exchange: _exchange,
                        onExchangeChanged: (ex) =>
                            setState(() => _exchange = ex),
                        onBuy: () => _setSide('BUY'),
                        onSell: () => _setSide('SELL'),
                        floating: widget.floating,
                        onToggleFloat: widget.onToggleFloat,
                        onCloseFloat: widget.onCloseFloat,
                        onHeaderDragUpdate: widget.onHeaderDragUpdate,
                        onHeaderDragEnd: widget.onHeaderDragEnd,
                      ),
                      if (widget.onOpenFundamentalAnalysis != null &&
                          sym.isNotEmpty) ...[
                        SizedBox(height: compact ? 2 : 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: widget.onOpenFundamentalAnalysis,
                            icon: Icon(
                              Icons.analytics_outlined,
                              size: compact ? 16 : 18,
                            ),
                            label: Text(
                              compact ? 'Fundamentals' : 'Full fundamental analysis',
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: colors.actionPrimaryBg,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ],
                      if (wallet != null) ...[
                        SizedBox(height: compact ? 6 : 10),
                        _BalanceBar(available: wallet.available, compact: compact),
                      ],
                      if (!compact) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _ProductTile(
                                title: 'Trading',
                                subtitle: 'Intraday',
                                selected: _productMode == 'Trading',
                                onTap: () =>
                                    setState(() => _productMode = 'Trading'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ProductTile(
                                title: 'Pay Later',
                                subtitle: 'via MTF',
                                selected: _productMode == 'MTF',
                                onTap: () =>
                                    setState(() => _productMode = 'MTF'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ProductTile(
                                title: 'Investing',
                                subtitle: 'Delivery',
                                selected: _productMode == 'Investing',
                                onTap: () =>
                                    setState(() => _productMode = 'Investing'),
                              ),
                            ),
                          ],
                        ),
                        if (_productMode == 'MTF') ...[
                          const SizedBox(height: 8),
                          Text(
                            'MTF is cosmetic for paper — order still goes to OMS as equity.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: colors.textSecondary,
                                ),
                          ),
                        ],
                      ],
                      SizedBox(height: compact ? 8 : 14),
                      _OrderCard(
                        compact: compact,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                for (final t in const [
                                  ('MARKET', 'Market', 'M', false),
                                  ('LIMIT', 'Limit', 'L', false),
                                  ('SUPER', 'SUPER', 'S', true),
                                  ('TRAIL', 'Trail', 'T', false),
                                ]) ...[
                                  if (t.$1 != 'MARKET')
                                    SizedBox(width: compact ? 4 : 6),
                                  Expanded(
                                    child: _TypeTab(
                                      label: t.$2,
                                      badge: t.$3,
                                      selected: _orderType == t.$1,
                                      superStyle: t.$4,
                                      compact: compact,
                                      onTap: () => _setOrderType(t.$1),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: compact ? 10 : 16),
                            _FieldRow(
                              label: 'Shares',
                              compact: compact,
                              child: _PriceStepper(
                                controller: _qty,
                                onMinus: () => _bumpQty(-1),
                                onPlus: () => _bumpQty(1),
                                keyboardType: TextInputType.number,
                                compact: compact,
                              ),
                            ),
                            if (_orderType == 'LIMIT' ||
                                (_orderType == 'SUPER' && _useLimit)) ...[
                              SizedBox(height: compact ? 8 : 14),
                              if (_orderType == 'SUPER')
                                _FieldRow(
                                  label: 'Limit Price',
                                  compact: compact,
                                  trailing: Switch.adaptive(
                                    value: _useLimit,
                                    activeThumbColor:
                                        colors.marketPositiveIndicator,
                                    activeTrackColor: colors
                                        .marketPositiveIndicator
                                        .withValues(alpha: 0.35),
                                    onChanged: (v) => setState(() {
                                      _useLimit = v;
                                      _entryType = v ? 'LIMIT' : 'MARKET';
                                    }),
                                  ),
                                  child: _useLimit
                                      ? _PriceStepper(
                                          controller: _limit,
                                          onMinus: () =>
                                              _bump(_limit, -0.05),
                                          onPlus: () =>
                                              _bump(_limit, 0.05),
                                          compact: compact,
                                        )
                                      : null,
                                )
                              else
                                _FieldRow(
                                  label: 'Limit Price',
                                  compact: compact,
                                  child: _PriceStepper(
                                    controller: _limit,
                                    onMinus: () => _bump(_limit, -0.05),
                                    onPlus: () => _bump(_limit, 0.05),
                                    compact: compact,
                                  ),
                                ),
                            ],
                            if (_orderType == 'MARKET') ...[
                              SizedBox(height: compact ? 4 : 8),
                              Text(
                                'Executes at live market price.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: colors.textSecondary),
                              ),
                            ],
                            if (_orderType == 'SUPER') ...[
                              const SizedBox(height: 14),
                              _CheckFieldRow(
                                checked: _useTarget,
                                onChecked: (v) =>
                                    setState(() => _useTarget = v),
                                label: 'Target',
                                controller: _target,
                                onMinus: () => _bump(_target, -0.05),
                                onPlus: () => _bump(_target, 0.05),
                              ),
                              const SizedBox(height: 12),
                              _CheckFieldRow(
                                checked: _useStop,
                                onChecked: (v) =>
                                    setState(() => _useStop = v),
                                label: 'Stop Loss',
                                controller: _stop,
                                onMinus: () => _bump(_stop, -0.05),
                                onPlus: () => _bump(_stop, 0.05),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => setState(
                                  () => _showTrigger = !_showTrigger,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: _showTrigger,
                                          activeColor:
                                              colors.marketPositiveIndicator,
                                          onChanged: (v) => setState(
                                            () =>
                                                _showTrigger = v ?? false,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Add trigger price',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_showTrigger) ...[
                                const SizedBox(height: 8),
                                _FieldRow(
                                  label: 'Trigger',
                                  compact: compact,
                                  child: _PriceStepper(
                                    controller: _trigger,
                                    onMinus: () =>
                                        _bump(_trigger, -0.05),
                                    onPlus: () =>
                                        _bump(_trigger, 0.05),
                                    compact: compact,
                                  ),
                                ),
                              ],
                            ],
                            if (_orderType == 'TRAIL') ...[
                              SizedBox(height: compact ? 8 : 14),
                              _FieldRow(
                                label: 'Trail jump',
                                compact: compact,
                                child: _PriceStepper(
                                  controller: _trail,
                                  onMinus: () => _bump(_trail, -0.5),
                                  onPlus: () => _bump(_trail, 0.5),
                                  compact: compact,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_orderType == 'SUPER') ...[
                        SizedBox(height: compact ? 8 : 12),
                        _OrderCard(
                          compact: compact,
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () => setState(
                                  () =>
                                      _bookProfitsOpen = !_bookProfitsOpen,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'On Target: Book Profits',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.marketPositiveBg,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '100% × 1 Leg',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: colors
                                                    .marketPositiveIndicator,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      Icon(
                                        _bookProfitsOpen
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: colors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_bookProfitsOpen) ...[
                                const SizedBox(height: 12),
                                Divider(height: 1, color: colors.divider),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Full Exit 100% at',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Qty ${_qty.text}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      colors.textSecondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 128,
                                      child: _PriceStepper(
                                        controller: _target,
                                        onMinus: () =>
                                            _bump(_target, -0.05),
                                        onPlus: () =>
                                            _bump(_target, 0.05),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'More options to exit',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: colors.textSecondary,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    _LegChip(label: '50% × 2'),
                                    _LegChip(label: '33% × 3'),
                                    _LegChip(label: '25% × 4'),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  compact ? 12 : 14,
                  compact ? 8 : 10,
                  compact ? 12 : 14,
                  compact ? 10 : 14,
                ),
                decoration: BoxDecoration(
                  color: colors.cardSurface,
                  border: Border(top: BorderSide(color: colors.divider)),
                  boxShadow: [
                    BoxShadow(
                      color: colors.textPrimary.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ctaColor,
                    foregroundColor: colors.actionPrimaryFg,
                    minimumSize: Size.fromHeight(compact ? 44 : 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(compact ? 10 : 12),
                    ),
                  ),
                  onPressed: state.submitting ||
                          _localSubmitting ||
                          sym.isEmpty
                      ? null
                      : _submit,
                  child: Text(
                    state.submitting || _localSubmitting
                        ? 'Submitting…'
                        : 'Instant ${isBuy ? 'Buy' : 'Sell'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: compact ? 15 : 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock({
    required this.title,
    required this.loading,
    required this.ltp,
    required this.change,
    required this.changePct,
    required this.priceColor,
    required this.fmt,
    required this.quote,
    required this.isBuy,
    required this.onBuy,
    required this.onSell,
    this.compact = false,
    this.exchange = 'NSE',
    this.onExchangeChanged,
    this.floating = false,
    this.onToggleFloat,
    this.onCloseFloat,
    this.onHeaderDragUpdate,
    this.onHeaderDragEnd,
  });

  final String title;
  final bool loading;
  final double ltp;
  final double change;
  final double changePct;
  final Color priceColor;
  final NumberFormat fmt;
  final QuoteDetail? quote;
  final bool isBuy;
  final VoidCallback onBuy;
  final VoidCallback onSell;
  final bool compact;
  final String exchange;
  final ValueChanged<String>? onExchangeChanged;
  final bool floating;
  final VoidCallback? onToggleFloat;
  final VoidCallback? onCloseFloat;
  final GestureDragUpdateCallback? onHeaderDragUpdate;
  final GestureDragEndCallback? onHeaderDragEnd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final titleRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: (compact
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.titleLarge)
                ?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        ),
        if (!compact && onToggleFloat != null)
          IconButton(
            tooltip: floating ? 'Cycle float position' : 'Float order ticket',
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            onPressed: onToggleFloat,
            icon: Icon(
              floating ? Icons.filter_none : Icons.open_in_full,
              color: colors.textTertiary,
            ),
          ),
        if (onCloseFloat != null)
          IconButton(
            tooltip: floating ? 'Dock order ticket' : 'Close',
            visualDensity: VisualDensity.compact,
            iconSize: compact ? 20 : 18,
            onPressed: onCloseFloat,
            icon: Icon(Icons.close, color: colors.textTertiary),
          )
        else if (!compact)
          Icon(Icons.open_in_new, size: 18, color: colors.textTertiary),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: onHeaderDragUpdate,
          onPanEnd: onHeaderDragEnd,
          child: MouseRegion(
            cursor: onHeaderDragUpdate != null
                ? SystemMouseCursors.move
                : SystemMouseCursors.basic,
            child: titleRow,
          ),
        ),
        SizedBox(height: compact ? 4 : 8),
        if (loading)
          LinearProgressIndicator(
            minHeight: 2,
            color: colors.actionPrimaryBg,
            backgroundColor: colors.divider,
          )
        else if (ltp > 0)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                fmt.format(ltp),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 18 : 22,
                    ),
              ),
              Icon(
                change < 0 ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                color: priceColor,
                size: compact ? 18 : 22,
              ),
              Text(
                '${change >= 0 ? '+' : ''}${fmt.format(change)} (${changePct.toStringAsFixed(2)}%)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: priceColor,
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 12 : null,
                    ),
              ),
              if (!compact)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colors.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Live',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.textTertiary,
                          ),
                    ),
                  ],
                ),
            ],
          )
        else
          Text(
            'Search a stock in the watchlist to load prices',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
        if (!compact && quote != null && ltp > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.marketCardSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.marketBorderMuted),
            ),
            child: Row(
              children: [
                _MiniStat(
                  'Open',
                  quote!.open != null ? fmt.format(quote!.open) : '—',
                ),
                _MiniStat(
                  'High',
                  quote!.high != null ? fmt.format(quote!.high) : '—',
                ),
                _MiniStat(
                  'Low',
                  quote!.low != null ? fmt.format(quote!.low) : '—',
                ),
                _MiniStat(
                  'Prev',
                  quote!.previousClose != null
                      ? fmt.format(quote!.previousClose)
                      : '—',
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: compact ? 8 : 12),
        Row(
          children: [
            _BuySellToggle(isBuy: isBuy, onBuy: onBuy, onSell: onSell),
            const Spacer(),
            _ExchangeToggle(
              exchange: exchange,
              onChanged: onExchangeChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _BalanceBar extends StatelessWidget {
  const _BalanceBar({required this.available, this.compact = false});

  final String available;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: compact ? 14 : 16, color: colors.textSecondary),
          const SizedBox(width: 8),
          Text(
            'Paper cash',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const Spacer(),
          Text(
            '₹$available',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 13 : null,
                ),
          ),
        ],
      ),
    );
  }
}

class _BuySellToggle extends StatelessWidget {
  const _BuySellToggle({
    required this.isBuy,
    required this.onBuy,
    required this.onSell,
  });

  final bool isBuy;
  final VoidCallback onBuy;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.scaffoldBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.marketBorderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Seg(
            label: 'Buy',
            selected: isBuy,
            color: colors.marketPositiveIndicator,
            onTap: onBuy,
          ),
          _Seg(
            label: 'Sell',
            selected: !isBuy,
            color: colors.marketNegativeIndicator,
            onTap: onSell,
          ),
        ],
      ),
    );
  }
}

class _ExchangeToggle extends StatelessWidget {
  const _ExchangeToggle({
    required this.exchange,
    this.onChanged,
  });

  final String exchange;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isNse = exchange.toUpperCase() != 'BSE';
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.scaffoldBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.marketBorderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Seg(
            label: 'NSE',
            selected: isNse,
            color: colors.actionPrimaryBg,
            onTap: () => onChanged?.call('NSE'),
          ),
          _Seg(
            label: 'BSE',
            selected: !isNse,
            color: colors.actionPrimaryBg,
            onTap: () => onChanged?.call('BSE'),
          ),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : context.colors.cardSurface.withValues(alpha: 0),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? context.colors.actionPrimaryFg
                      : context.colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = colors.actionPrimaryBg;
    return Material(
      color: selected ? accent.withValues(alpha: 0.12) : colors.cardSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : colors.marketBorderDefault,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? accent : colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected
                          ? accent.withValues(alpha: 0.85)
                          : colors.textTertiary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.child, this.compact = false});

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(compact ? 10 : 14),
        border: Border.all(color: colors.marketBorderDefault),
        boxShadow: compact
            ? null
            : [
                BoxShadow(
                  color: colors.textPrimary.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _TypeTab extends StatelessWidget {
  const _TypeTab({
    required this.label,
    required this.badge,
    required this.selected,
    required this.onTap,
    this.superStyle = false,
    this.compact = false,
  });

  final String label;
  final String badge;
  final bool selected;
  final bool superStyle;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = superStyle
        ? colors.marketPositiveIndicator
        : colors.actionPrimaryBg;
    return Material(
      color: selected
          ? (superStyle
              ? colors.marketPositiveBg
              : colors.actionPrimaryBg.withValues(alpha: 0.12))
          : colors.cardSurface,
      borderRadius: BorderRadius.circular(compact ? 8 : 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: compact ? 6 : 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 8 : 10),
            border: Border.all(
              color: selected
                  ? accent
                  : colors.divider,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: compact
              ? Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: selected ? accent : colors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                )
              : Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: selected ? 1 : 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: selected
                              ? colors.actionPrimaryFg
                              : accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style:
                          Theme.of(context).textTheme.labelMedium?.copyWith(
                                color:
                                    selected ? accent : colors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    this.child,
    this.trailing,
    this.compact = false,
  });

  final String label;
  final Widget? child;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 13 : null,
                    ),
              ),
            ),
            if (trailing != null) trailing!,
            if (child != null) ...[
              const SizedBox(width: 8),
              SizedBox(width: compact ? 118 : 132, child: child),
            ],
          ],
        ),
      ],
    );
  }
}

class _CheckFieldRow extends StatelessWidget {
  const _CheckFieldRow({
    required this.checked,
    required this.onChecked,
    required this.label,
    required this.controller,
    required this.onMinus,
    required this.onPlus,
  });

  final bool checked;
  final ValueChanged<bool> onChecked;
  final String label;
  final TextEditingController controller;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: checked,
            activeColor: colors.marketPositiveIndicator,
            onChanged: (v) => onChecked(v ?? false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Opacity(
          opacity: checked ? 1 : 0.4,
          child: IgnorePointer(
            ignoring: !checked,
            child: SizedBox(
              width: 132,
              child: _PriceStepper(
                controller: controller,
                onMinus: onMinus,
                onPlus: onPlus,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceStepper extends StatelessWidget {
  const _PriceStepper({
    required this.controller,
    required this.onMinus,
    required this.onPlus,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.compact = false,
  });

  final TextEditingController controller;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final TextInputType keyboardType;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final h = compact ? 36.0 : 42.0;
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: colors.scaffoldBackground,
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(color: colors.marketBorderDefault),
      ),
      child: Row(
        children: [
          _StepBtn(icon: Icons.remove, onTap: onMinus, height: h),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: keyboardType,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 13 : null,
                  ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          _StepBtn(icon: Icons.add, onTap: onPlus, height: h),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.onTap,
    this.height = 42,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 36,
        height: height,
        child: Icon(icon, size: 18, color: context.colors.textSecondary),
      ),
    );
  }
}

class _LegChip extends StatelessWidget {
  const _LegChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(value: false, onChanged: null),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
