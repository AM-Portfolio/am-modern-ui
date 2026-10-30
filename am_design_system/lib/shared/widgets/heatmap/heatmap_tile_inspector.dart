import 'package:flutter/material.dart';
import 'package:am_design_system/core/utils/string_utils.dart';

import '../../models/heatmap/heatmap_tile_data.dart';

/// Compact docked inspector for a hovered/pinned heatmap leaf.
class HeatmapTileInspector extends StatelessWidget {
  const HeatmapTileInspector({
    required this.tile,
    super.key,
  });

  final HeatmapTileData tile;

  static const _bg = Color(0xFF161A22);
  static const _border = Color(0xFF2A3140);

  @override
  Widget build(BuildContext context) {
    final meta = tile.metadata ?? const <String, dynamic>{};
    final symbol = (meta['symbol'] as String?) ??
        (tile.displayName.isNotEmpty ? tile.displayName : tile.name);
    final monogram = symbol.isNotEmpty ? symbol[0].toUpperCase() : '?';
    final price = _asDouble(meta['lastPrice']);
    final value = tile.value;
    final quantity = _asDouble(meta['quantity']);
    final weight = _asDouble(meta['weightPortfolioPct']) ?? tile.weightage;
    final change = tile.performance;
    final up = change >= 0;
    final changeColor = up ? const Color(0xFF26A69A) : const Color(0xFFEF5350);
    final changeText =
        '${up ? '+' : ''}${change.toStringAsFixed(2)}%';

    return Material(
      color: _bg,
      elevation: 12,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 40,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  monogram,
                  style: TextStyle(
                    color: changeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  symbol,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.1,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (quantity != null && quantity > 0)
                        _chip('Qty ${_qtyLabel(quantity)}'),
                      if (value != null) ...[
                        if (quantity != null && quantity > 0)
                          const SizedBox(width: 4),
                        _chip(
                          StringUtils.formatCurrency(value),
                          emphasize: true,
                        ),
                      ],
                      if (price != null) ...[
                        const SizedBox(width: 4),
                        _chip('LTP ${StringUtils.formatCurrency(price)}'),
                      ],
                      const SizedBox(width: 4),
                      _chip('${weight.toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  changeText,
                  style: TextStyle(
                    color: changeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _chip(String text, {bool emphasize = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: emphasize
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Colors.white.withValues(alpha: emphasize ? 0.14 : 0.08),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: emphasize ? Colors.white : Colors.white70,
          fontSize: 10,
          fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
          height: 1.1,
        ),
      ),
    );
  }

  static String _qtyLabel(double quantity) {
    return quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(2);
  }

  static double? _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
