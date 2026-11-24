import 'package:flutter/material.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';
import 'package:am_design_system/core/utils/string_utils.dart';

import '../../models/heatmap/heatmap_tile_data.dart';

/// Compact docked inspector for a hovered/pinned heatmap leaf.
///
/// Sizes to content (not full page width). Host should wrap with a responsive
/// [maxWidth] — roughly 360 on phones, ~420 on web.
class HeatmapTileInspector extends StatelessWidget {
  const HeatmapTileInspector({
    required this.tile,
    super.key,
  });

  final HeatmapTileData tile;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final meta = tile.metadata ?? const <String, dynamic>{};
    final symbol = _inspectorLabel(tile, meta);
    final monogram = symbol.isNotEmpty ? symbol[0].toUpperCase() : '?';
    final price = _asDouble(meta['lastPrice']);
    final value = tile.value;
    final quantity = _asDouble(meta['quantity']);
    final weight = _asDouble(meta['weightPortfolioPct']) ?? tile.weightage;
    final change = tile.performance;
    final up = change >= 0;
    final changeColor = up ? context.marketPositive : context.marketNegative;
    final changeText = _dayChangeLabel(meta, change);
    final ink = colors.textPrimary;
    final mutedInk = colors.textSecondary;
    final chipFill = ink.withValues(alpha: context.isDark ? 0.08 : 0.06);
    final chipBorder = ink.withValues(alpha: context.isDark ? 0.14 : 0.10);

    final lookthroughNote = meta['lookthroughNote']?.toString().trim();
    final chips = <Widget>[
      if (quantity != null && quantity > 0)
        _chip(
          'Qty ${_qtyLabel(quantity)}',
          fill: chipFill,
          border: chipBorder,
          textColor: mutedInk,
        ),
      if (value != null)
        _chip(
          StringUtils.formatCurrency(value),
          fill: chipFill,
          border: chipBorder,
          textColor: ink,
          emphasize: true,
        ),
      if (price != null)
        _chip(
          '${_priceLabel(meta)} ${StringUtils.formatCurrency(price)}',
          fill: chipFill,
          border: chipBorder,
          textColor: mutedInk,
        ),
      _chip(
        '${weight.toStringAsFixed(1)}%',
        fill: chipFill,
        border: chipBorder,
        textColor: mutedInk,
      ),
      if (lookthroughNote != null && lookthroughNote.isNotEmpty)
        _chip(
          lookthroughNote,
          fill: chipFill,
          border: chipBorder,
          textColor: mutedInk,
        ),
    ];

    return Material(
      color: colors.cardSurface,
      elevation: 12,
      shadowColor: context.shadow(0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
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
                  fontSize: 10,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 7),
            ConstrainedBox(
              // Same compact ticker width as equities (TCS / NIFTYBEES).
              // Long MF names ellipsis — do not widen the pill.
              constraints: const BoxConstraints(maxWidth: 72),
              child: Text(
                symbol,
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.1,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < chips.length; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      chips[i],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: changeColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                changeText,
                style: TextStyle(
                  color: changeColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _chip(
    String text, {
    required Color fill,
    required Color border,
    required Color textColor,
    bool emphasize = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
          height: 1.1,
        ),
      ),
    );
  }

  /// Equity/ETF: trading symbol. MF schemes: fund display name (never INF* ISIN).
  static String _inspectorLabel(
    HeatmapTileData tile,
    Map<String, dynamic> meta,
  ) {
    final raw = ((meta['symbol'] as String?) ?? '').trim();
    final display =
        tile.displayName.trim().isNotEmpty ? tile.displayName.trim() : tile.name.trim();
    final upper = raw.toUpperCase();
    final looksLikeIsin = RegExp(r'^INF[A-Z0-9]{9}$').hasMatch(upper);
    if (looksLikeIsin && display.isNotEmpty) {
      return display;
    }
    if (raw.isNotEmpty) {
      return upper;
    }
    return display;
  }

  /// EOD AMFI NAV schemes use NAV; equity/ETF tiles keep LTP.
  static String _priceLabel(Map<String, dynamic> meta) {
    final source = (meta['priceSource'] as String?)?.trim().toUpperCase();
    if (source == 'EOD_NAV') return 'NAV';
    return 'LTP';
  }

  /// Flat 0% without a prior close is not a measured day move.
  static String _dayChangeLabel(Map<String, dynamic> meta, double change) {
    final prev = meta['previousClose'];
    final hasPrev = prev is num && prev > 0;
    final isStock = meta['type'] == 'stock';
    if (isStock && !hasPrev && change.abs() < 0.005) {
      return '—';
    }
    final up = change >= 0;
    return '${up ? '+' : ''}${change.toStringAsFixed(2)}%';
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
