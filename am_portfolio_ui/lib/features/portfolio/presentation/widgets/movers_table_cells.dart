// Unused backup of table cell widgets. Do not delete.
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import 'movers_join.dart';

class MoverSymbolAvatar extends StatelessWidget {
  const MoverSymbolAvatar({
    super.key,
    required this.symbol,
    required this.size,
  });

  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hue = (symbol.hashCode.abs() % 360).toDouble();
    final bg = HSVColor.fromAHSV(1, hue, 0.52, 0.42).toColor();
    final mark = _mark(symbol);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        mark,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: mark.length > 1 ? size * 0.32 : size * 0.42,
        ),
      ),
    );
  }

  static String _mark(String symbol) {
    final cleaned = symbol.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (cleaned.isEmpty) return '?';
    return cleaned.substring(0, 1).toUpperCase();
  }
}

class MoverPnlChip extends StatelessWidget {
  const MoverPnlChip({
    super.key,
    required this.amount,
    required this.percent,
    this.compact = false,
    this.minWidth = 96,
  });

  final double? amount;
  final double? percent;
  final bool compact;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    if (amount == null) {
      return Align(
        alignment: Alignment.centerRight,
        child: Text('—', style: TextStyle(color: muted, fontSize: 12)),
      );
    }
    final positive = amount! > 0.005;
    final negative = amount! < -0.005;
    final color = positive
        ? context.colors.marketPositiveIndicator
        : negative
            ? context.colors.marketNegativeIndicator
            : muted;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth, maxWidth: 108),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: compact ? 4 : 5,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatSignedInr(amount!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 11 : 12,
                ),
              ),
              if (percent != null)
                Text(
                  formatSignedPct(percent!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String formatMoverQty(double qty) {
  if (qty == qty.roundToDouble()) return qty.toInt().toString();
  return qty.toStringAsFixed(2);
}
