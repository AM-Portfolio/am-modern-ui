import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:am_market_common/models/top_mover_stock.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';

/// Unified Top Movers card — Gainers & Losers in one panel.
///
/// Layout:
///   - Desktop (≥ 600 px): side-by-side Gainers | Losers columns
///   - Mobile  (< 600 px): segmented toggle + AnimatedSwitcher single list
///
/// Design references:
///   - Card structure & mobile toggle → Portfolio MoversWidget (read-only reference)
///   - Color tokens                  → MarketColors
///   - Hover animation               → MonthlyPerformanceCard compact table mode
///     (AnimatedScale 1.12, 250 ms, easeOutCubic + glow shadow opacity 0.6)
class TopMoversWidgetV2 extends StatefulWidget {
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
  State<TopMoversWidgetV2> createState() => _TopMoversWidgetV2State();
}

class _TopMoversWidgetV2State extends State<TopMoversWidgetV2> {
  // Mobile toggle state — default: show Gainers
  bool _showGainers = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Glassmorphic outer shell (structure mirrors Portfolio MoversWidget) ──
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      // Dark: pageBg → cardSurface (Market tokens)
                      const Color(0xFF0F1117).withOpacity(0.92),
                      const Color(0xFF1A1F2E).withOpacity(0.85),
                    ]
                  : [
                      // Light: pure white → very light slate
                      Colors.white.withOpacity(0.95),
                      const Color(0xFFF8FAFC).withOpacity(0.90),
                    ],
            ),
            border: Border.all(
              // MarketColors: dark → #2A3347, light → #CBD5E1
              color: MarketColors.borderDefault(context),
              width: MarketColors.borderWidth(context), // 1.0 dark / 1.5 light
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildContent(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header: accent icon + "Top Movers" title ──────────────────────────────
  Widget _buildHeader(BuildContext context) {
    // MarketColors.borderSelected — same in both themes (#00C896)
    const accent = Color(0xFF00C896);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.auto_graph_rounded,
            color: accent,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Top Movers',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: -0.3,
            color: MarketColors.textPrimary(context),
          ),
        ),
      ],
    );
  }

  // ── Content: loading / error / empty / responsive layout ─────────────────
  Widget _buildContent(BuildContext context) {
    // Loading state
    if (widget.isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00C896),
            strokeWidth: 2,
          ),
        ),
      );
    }

    // Error state
    if (widget.error != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  color: MarketColors.negative(context), size: 48),
              const SizedBox(height: 8),
              Text(
                'Failed to load movers data',
                style: TextStyle(
                    color: MarketColors.negative(context), fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                widget.error!,
                style: TextStyle(
                    color: MarketColors.textMuted(context), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (widget.gainers.isEmpty && widget.losers.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.data_usage_outlined,
                  color: MarketColors.textMuted(context), size: 48),
              const SizedBox(height: 8),
              Text(
                'No movers data available',
                style: TextStyle(
                    color: MarketColors.textMuted(context), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Mobile: segmented toggle + single animated list ──
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented toggle container
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              // dark: subtle black overlay; light: light slate overlay
              color: isDark
                  ? Colors.black.withOpacity(0.20)
                  : const Color(0xFFCBD5E1).withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Gainers tab
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showGainers = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        // Active: positiveBg; Inactive: transparent
                        color: _showGainers
                            ? MarketColors.positiveBg(context)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Gainers (${widget.gainers.length})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _showGainers
                                ? FontWeight.bold
                                : FontWeight.w500,
                            // Active: positive accent; Inactive: muted
                            color: _showGainers
                                ? MarketColors.positive(context)
                                : MarketColors.textMuted(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Losers tab
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showGainers = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        // Active: negativeBg; Inactive: transparent
                        color: !_showGainers
                            ? MarketColors.negativeBg(context)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Losers (${widget.losers.length})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: !_showGainers
                                ? FontWeight.bold
                                : FontWeight.w500,
                            // Active: negative accent; Inactive: muted
                            color: !_showGainers
                                ? MarketColors.negative(context)
                                : MarketColors.textMuted(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // AnimatedSwitcher fades between the two lists
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showGainers
                ? _buildColumn(
                    context, 'Gainers', widget.gainers, true,
                    key: const ValueKey('gainers'))
                : _buildColumn(
                    context, 'Losers', widget.losers, false,
                    key: const ValueKey('losers')),
          ),
        ],
      );
    }

    // ── Desktop: Gainers left | Losers right ──
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildColumn(context, 'Gainers', widget.gainers, true),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildColumn(context, 'Losers', widget.losers, false),
        ),
      ],
    );
  }

  // ── Column: section header + tile list ───────────────────────────────────
  Widget _buildColumn(
    BuildContext context,
    String title,
    List<TopMoverStock> stocks,
    bool isGainers, {
    Key? key,
  }) {
    final color = isGainers
        ? MarketColors.positive(context)
        : MarketColors.negative(context);

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column header: trend icon + "Gainers (N)" / "Losers (N)"
        Row(
          children: [
            Icon(
              isGainers
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: color,
              size: 15,
            ),
            const SizedBox(width: 5),
            Text(
              '$title (${stocks.length})',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Tiles (max 5) or empty state
        if (stocks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Text(
                'No ${isGainers ? 'gainers' : 'losers'} found',
                style: TextStyle(
                  color: MarketColors.textMuted(context),
                  fontSize: 13,
                ),
              ),
            ),
          )
        else
          ...stocks.take(5).map(
                (stock) => _MarketMoverTile(
                  stock: stock,
                  isGainer: isGainers,
                ),
              ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual mover tile
// Animation: inspired by MonthlyPerformanceCard compact-table style
//   → AnimatedContainer + Matrix4.scale(1.03), 250 ms, Curves.easeOutCubic
//     (Matrix4 transform scales paint only — layout stays fixed, no overflow)
//   → boxShadow glow: accentColor.withOpacity(0.6), blurRadius 12, spreadRadius 1
//   → % pill: on hover uses stronger fill + border so it pops against tile bg
// ─────────────────────────────────────────────────────────────────────────────
class _MarketMoverTile extends StatefulWidget {
  final TopMoverStock stock;
  final bool isGainer;

  const _MarketMoverTile({
    required this.stock,
    required this.isGainer,
  });

  @override
  State<_MarketMoverTile> createState() => _MarketMoverTileState();
}

class _MarketMoverTileState extends State<_MarketMoverTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve MarketColors tokens for this tile
    final accentColor = widget.isGainer
        ? MarketColors.positive(context)   // dark:#00C896 / light:#00956B
        : MarketColors.negative(context);  // dark:#F87171 / light:#DC2626
    final bgColor = widget.isGainer
        ? MarketColors.positiveBg(context) // dark:#00C896@15% / light:#00956B@12%
        : MarketColors.negativeBg(context);// dark:#F87171@14% / light:#DC2626@10%

    final stock = widget.stock;

    // Pill colors: on hover use higher opacity to stand out against tinted tile bg
    final pillBg = _isHovered
        ? accentColor.withOpacity(isDark ? 0.28 : 0.18)  // stronger fill on hover
        : bgColor;                                         // subtle tint at rest
    final pillBorderColor = _isHovered
        ? accentColor.withOpacity(0.70)  // vivid border on hover
        : accentColor.withOpacity(0.35); // subtle at rest
    final pillTextColor = _isHovered
        ? (isDark ? Colors.white : accentColor) // high contrast on hover
        : accentColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        // ── Scale via Matrix4 transform: layout size stays fixed (no overflow) ──
        // Scale 1.03 — subtle pop without spilling out of the card
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: _isHovered
            ? (Matrix4.identity()..scale(1.03))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          // Tile background: accent-tinted on hover, near-transparent at rest
          color: _isHovered
              ? bgColor
              : (isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.025)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? accentColor.withOpacity(0.50)
                : accentColor.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: _isHovered
              ? [
                  // Glow: accentColor at 0.6, blur 12, spread 1 (MonthlyPerformanceCard spec)
                  BoxShadow(
                    color: accentColor.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // ── Squircle directional icon (28×28, radius 7) ──────────────
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                widget.isGainer
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 14,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 8),

            // ── Ticker symbol (bold, 13 px) ──────────────────────────────
            Expanded(
              child: Text(
                stock.symbol,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: MarketColors.textPrimary(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ── Last price ───────────────────────────────────────────────
            Text(
              '₹${stock.lastPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                // textPrimary: dark → #E2E8F0 (near-white), light → #0F172A (near-black)
                color: MarketColors.textPrimary(context),
              ),
            ),
            const SizedBox(width: 8),

            // ── Percentage pill ─────────────────────────────────────────
            // On hover: pill bg and border strengthen so it pops against
            // the tinted tile background (prevents blending/invisibility).
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: pillBorderColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(_isHovered ? 0.35 : 0.15),
                    blurRadius: 6,
                    spreadRadius: -1,
                  ),
                ],
              ),
              child: Text(
                '${stock.changePercent >= 0 ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: pillTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
