import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/models/top_mover_stock.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';

/// Market-module adapter for [AmTopMoversPanel].
///
/// Converts the market-specific [TopMoverStock] model to the design-system's
/// [AmMoverItem] and passes it to the shared [AmTopMoversPanel] widget.
///
/// ## Why a wrapper?
/// [AmTopMoversPanel] lives in `am_design_system` and knows nothing about
/// [TopMoverStock]. This wrapper is the single mapping point — if [TopMoverStock]
/// fields ever change, only this file needs updating.
///
/// ## Usage in user_dashboard_page.dart
/// ```dart
/// TopMoversWidgetV2(
///   gainers: topGainers,
///   losers: topLosers,
///   isLoading: isLoadingMovers,
/// )
/// ```
///
/// ## Want to use the panel directly in another page?
/// Import `am_design_system` and use [AmTopMoversPanel] + [AmMoverItem] directly.
/// See `am_top_movers_panel.dart` for the full customisation API.
class TopMoversWidgetV2 extends StatelessWidget {
  final List<TopMoverStock> gainers;
  final List<TopMoverStock> losers;
  final bool isLoading;
  final String? error;

  const TopMoversWidgetV2({
    required this.gainers,
    required this.losers,
    this.isLoading = false,
    this.error,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Resolve MarketColors tokens here — they need BuildContext.
    // Passed as overrides into AmTopMoversPanel so the shared widget
    // renders with the market UI's exact green/red palette.
    final positiveColor = MarketColors.positive(context);
    final negativeColor = MarketColors.negative(context);
    final headerAccent  = MarketColors.borderSelected(context);

    return AmTopMoversPanel(
      gainers: gainers.map(_toAmItem).toList(),
      losers: losers.map(_toAmItem).toList(),
      isLoading: isLoading,
      error: error,
      positiveColor: positiveColor,
      negativeColor: negativeColor,
      headerAccent: headerAccent,
    );
  }

  /// Maps [TopMoverStock] → [AmMoverItem].
  /// Centralised here so any field-name change in [TopMoverStock] is caught
  /// in one place and not scattered across multiple widget files.
  static AmMoverItem _toAmItem(TopMoverStock s) => AmMoverItem(
        symbol: s.symbol,
        subtitle: s.companyName.isNotEmpty ? s.companyName : null,
        price: s.lastPrice,
        priceLabel: '₹${s.lastPrice.toStringAsFixed(2)}',
        changePercent: s.changePercent,
      );
}
