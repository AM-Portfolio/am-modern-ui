import 'dart:async';

import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../domain/models/basket_opportunity.dart';
import '../../../domain/services/basket_currency_formatter.dart';
import '../../shared/basket_item_status_theme.dart';
import 'customize_qty_stepper.dart';

class CustomizeConstituentRowDesktop extends StatefulWidget {
  final BasketItem item;
  final bool hasCalculated;
  final String investedText;
  final double investmentAmount;
  final double? customWeightPercent;
  final double allocatedUnits;
  final double baseTargetQuantity;
  final int gapVsEtf;
  final bool canIncrease;
  final bool canDecrease;
  final bool isExcluded;
  final int originalIdx;
  final VoidCallback onRemove;
  final VoidCallback onAdd;
  final VoidCallback onAddGap;
  final VoidCallback onSubstitute;
  final ValueChanged<double> onQtyChanged;
  final ValueChanged<int>? onTargetQtyChanged;
  final ValueChanged<int>? onDirectTargetQtySet;
  final ValueChanged<int>? onDirectTargetQtyChanged;

  const CustomizeConstituentRowDesktop({
    super.key,
    required this.item,
    required this.hasCalculated,
    required this.investedText,
    required this.investmentAmount,
    this.customWeightPercent,
    required this.allocatedUnits,
    required this.baseTargetQuantity,
    required this.gapVsEtf,
    required this.canIncrease,
    required this.canDecrease,
    required this.isExcluded,
    required this.originalIdx,
    required this.onRemove,
    required this.onAdd,
    required this.onAddGap,
    required this.onSubstitute,
    required this.onQtyChanged,
    this.onTargetQtyChanged,
    this.onDirectTargetQtySet,
    this.onDirectTargetQtyChanged,
  });

  @override
  State<CustomizeConstituentRowDesktop> createState() =>
      _CustomizeConstituentRowDesktopState();
}

class _CustomizeConstituentRowDesktopState
    extends State<CustomizeConstituentRowDesktop> {
  bool _isHovered = false;
  bool _editingTargetQty = false;
  late TextEditingController _targetQtyController;
  Timer? _qtyDebounce;

  @override
  void initState() {
    super.initState();
    _targetQtyController = TextEditingController(
      text: widget.allocatedUnits > 0
          ? widget.allocatedUnits.toInt().toString()
          : '',
    );
  }

  @override
  void didUpdateWidget(covariant CustomizeConstituentRowDesktop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editingTargetQty &&
        oldWidget.allocatedUnits != widget.allocatedUnits) {
      _targetQtyController.text = widget.allocatedUnits > 0
          ? widget.allocatedUnits.toInt().toString()
          : '';
    }
  }

  @override
  void dispose() {
    _qtyDebounce?.cancel();
    _targetQtyController.dispose();
    super.dispose();
  }

  void _commitTargetQtyEdit() {
    final parsed = int.tryParse(_targetQtyController.text.trim()) ?? 0;
    widget.onDirectTargetQtySet?.call(parsed);
    setState(() => _editingTargetQty = false);
  }

  void _onQtyTextChanged(String value) {
    _qtyDebounce?.cancel();
    _qtyDebounce = Timer(const Duration(milliseconds: 300), () {
      final parsed = int.tryParse(value.trim()) ?? 0;
      widget.onDirectTargetQtyChanged?.call(parsed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isMissing = item.status == ItemStatus.missing && !widget.isExcluded;

    final priceOk = item.lastPrice != null && item.lastPrice! > 0;
    final allocated = widget.allocatedUnits;
    final basketValue = allocated * (item.lastPrice ?? 0.0);
    final targetWeight = item.rebalancedWeight ?? item.etfWeight;
    final statusColor = BasketItemStatusTheme.colorFor(
      context,
      item.status,
      isExcluded: widget.isExcluded,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 56,
        color: _isHovered
            ? context.colors.actionPrimaryBg.withValues(alpha: 0.05)
            : Colors.transparent,
        child: Row(children: [
          Expanded(
            flex: 22,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                      item.stockSymbol.isNotEmpty
                          ? item.stockSymbol[0]
                          : '?',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            item.status == ItemStatus.substitute &&
                                    item.userHoldingSymbol != null
                                ? item.userHoldingSymbol!
                                : item.stockSymbol,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: widget.isExcluded
                                    ? context.textTertiary
                                    : context.textPrimary,
                                decoration: widget.isExcluded
                                    ? TextDecoration.lineThrough
                                    : null),
                            overflow: TextOverflow.ellipsis),
                        if (item.status == ItemStatus.held ||
                            item.status == ItemStatus.substitute)
                          Text(
                              '(avg: ${item.heldAveragePrice != null ? BasketCurrencyFormatter.formatInr(item.heldAveragePrice!) : '-'})',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: context.textSecondary)),
                        if (item.status == ItemStatus.substitute &&
                            item.userHoldingSymbol != null)
                          Text('sub for ${item.stockSymbol}',
                              style: TextStyle(
                                  fontSize: 9, color: context.textTertiary))
                        else if (item.underfunded)
                          Container(
                            margin: const EdgeInsets.only(top: 1),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: context.statusWarning
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Min ${BasketCurrencyFormatter.formatInr(item.lastPrice ?? 0)} needed',
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: context.statusWarning),
                            ),
                          ),
                      ]),
                ),
              ]),
            ),
          ),
          Expanded(
            flex: 10,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${targetWeight.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 9,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.customWeightPercent != null
                      ? '${widget.customWeightPercent!.toStringAsFixed(1)}%'
                      : '—',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: widget.isExcluded
                        ? context.textTertiary
                        : context.colors.actionPrimaryBg,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              flex: 16,
              child: ((item.heldQuantity ?? 0) > 0 && item.lastPrice != null)
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${item.heldQuantity!.toInt()} | ${BasketCurrencyFormatter.formatInr(item.heldQuantity! * item.lastPrice!)}',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: context.statusSuccess)),
                        Text(
                            '@ ${item.lastPrice != null ? BasketCurrencyFormatter.formatInr(item.lastPrice!) : '—'}',
                            style: TextStyle(
                                fontSize: 9, color: context.textTertiary)),
                      ],
                    )
                  : Text('—',
                      style: TextStyle(
                          fontSize: 11, color: context.textTertiary))),
          Expanded(
            flex: 16,
            child: (priceOk && (item.heldQuantity ?? 0) > 0)
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        BasketCurrencyFormatter.formatInr(basketValue),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: allocated > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: allocated > 0
                              ? context.textPrimary
                              : context.textTertiary,
                        ),
                      ),
                      if (widget.hasCalculated &&
                          widget.onTargetQtyChanged != null)
                        CustomizeQtyStepper(
                          canIncrease: widget.canIncrease,
                          canDecrease: widget.canDecrease,
                          onDecrease: () => widget.onTargetQtyChanged!(-1),
                          onIncrease: () => widget.onTargetQtyChanged!(1),
                          child: _editingTargetQty &&
                                  widget.onDirectTargetQtySet != null
                              ? SizedBox(
                                  width: 72,
                                  height: 28,
                                  child: TextField(
                                    controller: _targetQtyController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 4),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                    ),
                                    onChanged: _onQtyTextChanged,
                                    onSubmitted: (_) =>
                                        _commitTargetQtyEdit(),
                                    onEditingComplete: _commitTargetQtyEdit,
                                  ),
                                )
                              : GestureDetector(
                                  onTap: widget.onDirectTargetQtySet != null
                                      ? () => setState(
                                          () => _editingTargetQty = true)
                                      : null,
                                  child: Container(
                                    constraints:
                                        const BoxConstraints(minWidth: 72),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: context.colors.surface,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: context.colors.border),
                                    ),
                                    child: Text(
                                      allocated > 0
                                          ? '${allocated.toInt()} units'
                                          : '— units',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: allocated > 0
                                            ? context.textPrimary
                                            : context.textTertiary,
                                      ),
                                    ),
                                  ),
                                ),
                        )
                      else
                        Container(
                          constraints: const BoxConstraints(minWidth: 72),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: context.colors.border
                                    .withValues(alpha: 0.6)),
                          ),
                          child: Text(
                            allocated > 0
                                ? '${allocated.toInt()} units'
                                : '— units',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10, color: context.textTertiary),
                          ),
                        ),
                    ],
                  )
                : Text('—',
                    style:
                        TextStyle(fontSize: 11, color: context.textTertiary)),
          ),
          Expanded(
              flex: 8,
              child: Center(
                child: CustomizeGapPill(
                  gapVsEtf: widget.gapVsEtf,
                  priceOk: priceOk && (item.heldQuantity ?? 0) > 0,
                ),
              )),
          Expanded(
              flex: 13,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: allocated > 0 && item.lastPrice != null
                    ? Text(
                        BasketCurrencyFormatter.formatInr(basketValue),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      )
                    : Text('—',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 11, color: context.textTertiary)),
              )),
          Expanded(
              flex: 9,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isExcluded)
                      InkWell(
                          onTap: widget.onAdd,
                          child: Icon(Icons.undo,
                              size: 18, color: context.textSecondary))
                    else if (isMissing)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        InkWell(
                          onTap: widget.onSubstitute,
                          child: Icon(Icons.swap_horiz,
                              size: 18,
                              color: context.colors.actionPrimaryBg),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: widget.onRemove,
                          child: Icon(Icons.delete_outline,
                              size: 18, color: context.statusError),
                        ),
                      ])
                    else
                      InkWell(
                        onTap: widget.onRemove,
                        child: Icon(Icons.delete_outline,
                            size: 18, color: context.statusError),
                      )
                  ])),
        ]),
      ),
    );
  }
}
