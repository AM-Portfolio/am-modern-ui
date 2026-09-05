import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../domain/models/basket_opportunity.dart';
import '../../../domain/services/basket_currency_formatter.dart';

/// Shared − / qty / + control used on desktop, tablet, and the mobile qty sheet.
class CustomizeQtyStepper extends StatelessWidget {
  final bool canIncrease;
  final bool canDecrease;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final Widget child;
  final bool compact;

  const CustomizeQtyStepper({
    super.key,
    required this.canIncrease,
    required this.canDecrease,
    required this.onDecrease,
    required this.onIncrease,
    required this.child,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 16.0 : 18.0;
    final pad = compact ? 2.0 : 4.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: canDecrease ? onDecrease : null,
          child: Padding(
            padding: EdgeInsets.all(pad),
            child: Icon(
              Icons.remove_circle_outline,
              size: iconSize,
              color: canDecrease ? context.textSecondary : context.textTertiary,
            ),
          ),
        ),
        child,
        InkWell(
          onTap: canIncrease ? onIncrease : null,
          child: Padding(
            padding: EdgeInsets.all(pad),
            child: Icon(
              Icons.add_circle_outline,
              size: iconSize,
              color: canIncrease ? context.textSecondary : context.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Colored gap-vs-ETF chip. Shows "—" when price is unusable.
class CustomizeGapPill extends StatelessWidget {
  final int gapVsEtf;
  final bool priceOk;

  const CustomizeGapPill({
    super.key,
    required this.gapVsEtf,
    required this.priceOk,
  });

  @override
  Widget build(BuildContext context) {
    if (!priceOk) {
      return Text(
        '—',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: context.textTertiary),
      );
    }
    final Color color;
    final String label;
    if (gapVsEtf > 0) {
      color = context.statusSuccess;
      label = '+$gapVsEtf';
    } else if (gapVsEtf < 0) {
      color = context.statusWarning;
      label = '$gapVsEtf';
    } else {
      color = context.statusSuccess;
      label = '0';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

Future<void> showCustomizeQtySheet({
  required BuildContext context,
  required BasketItem item,
  required int allocatedUnits,
  required int gapVsEtf,
  required ValueChanged<int> onDelta,
  ValueChanged<int>? onSetQty,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final navReserveFull = PlatformConstants.globalBottomNavReserve(ctx);
      return ValueListenableBuilder<double>(
        valueListenable: GlobalBottomNavVisibility.factor,
        builder: (context, navFactor, _) {
          final t = navFactor.clamp(0.0, 1.0);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + (navReserveFull * t),
            ),
            child: _CustomizeQtySheetBody(
              item: item,
              initialQty: allocatedUnits,
              gapVsEtf: gapVsEtf,
              onDelta: onDelta,
              onSetQty: onSetQty,
            ),
          );
        },
      );
    },
  );
}

class _CustomizeQtySheetBody extends StatefulWidget {
  final BasketItem item;
  final int initialQty;
  final int gapVsEtf;
  final ValueChanged<int> onDelta;
  final ValueChanged<int>? onSetQty;

  const _CustomizeQtySheetBody({
    required this.item,
    required this.initialQty,
    required this.gapVsEtf,
    required this.onDelta,
    this.onSetQty,
  });

  @override
  State<_CustomizeQtySheetBody> createState() => _CustomizeQtySheetBodyState();
}

class _CustomizeQtySheetBodyState extends State<_CustomizeQtySheetBody> {
  late int _qty;
  late final TextEditingController _controller;

  int get _heldMax => (widget.item.heldQuantity ?? 0).toInt();
  bool get _priceOk =>
      widget.item.lastPrice != null && widget.item.lastPrice! > 0;

  @override
  void initState() {
    super.initState();
    _qty = widget.initialQty.clamp(0, _heldMax);
    _controller = TextEditingController(text: _qty.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQty(int next) {
    final clamped = next.clamp(0, _heldMax);
    final delta = clamped - _qty;
    if (delta == 0) return;
    setState(() {
      _qty = clamped;
      _controller.text = clamped.toString();
    });
    if (delta.abs() == 1) {
      widget.onDelta(delta);
    } else {
      widget.onSetQty?.call(clamped);
      if (widget.onSetQty == null) {
        widget.onDelta(delta);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.item.lastPrice ?? 0;
    final symbol = widget.item.status == ItemStatus.substitute &&
            widget.item.userHoldingSymbol != null
        ? widget.item.userHoldingSymbol!
        : widget.item.stockSymbol;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Adjust quantity', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              symbol,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            CustomizeQtyStepper(
              canIncrease: _priceOk && _qty < _heldMax,
              canDecrease: _priceOk && _qty > 0,
              onDecrease: () => _setQty(_qty - 1),
              onIncrease: () => _setQty(_qty + 1),
              child: SizedBox(
                width: 88,
                child: TextField(
                  controller: _controller,
                  enabled: _priceOk,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    suffixText: 'u',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (value) {
                    final parsed = int.tryParse(value.trim()) ?? _qty;
                    _setQty(parsed);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Held: $_heldMax',
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
                CustomizeGapPill(gapVsEtf: widget.gapVsEtf, priceOk: _priceOk),
                Text(
                  _priceOk
                      ? BasketCurrencyFormatter.formatInr(_qty * price)
                      : '—',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
