import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../shared/models/am_mover_item.dart';
import 'am_mover_tile.dart';

// ============================================================================
// AmTopMoversPanel — Shared Design System Component
// ============================================================================
//
// A glassmorphic panel showing market gainers and losers in a responsive layout:
//   • Desktop (≥ breakpoint): side-by-side Gainers | Losers columns
//   • Mobile  (< breakpoint): segmented toggle bar + AnimatedSwitcher list
//
// ## Minimal usage (market dashboard)
// ```dart
// AmTopMoversPanel(
//   gainers: gainers.map((s) => AmMoverItem(
//     symbol: s.symbol,
//     price: s.lastPrice,
//     priceLabel: '₹${s.lastPrice.toStringAsFixed(2)}',
//     changePercent: s.changePercent,
//   )).toList(),
//   losers: losers.map(/* same */).toList(),
//   isLoading: isLoadingMovers,
// )
// ```
//
// ## Customised usage (portfolio module)
// ```dart
// AmTopMoversPanel(
//   title: 'Portfolio Movers',
//   headerIcon: Icons.show_chart_rounded,
//   positiveColor: const Color(0xFF00B894),   // portfolio green
//   negativeColor: const Color(0xFFFF7675),   // portfolio red
//   gainers: ...,
//   losers: ...,
// )
// ```
//
// ## Design notes
// • Colors default to theme-adaptive values via Theme.of(context).
//   Pass positiveColor / negativeColor to apply module-specific branding.
// • No dependency on MarketColors — safe to import from any module.
// • Portfolio's MoversWidget is unaffected; this is a separate shared widget.
// ============================================================================

class AmTopMoversPanel extends StatefulWidget {
  const AmTopMoversPanel({
    super.key,
    required this.gainers,
    required this.losers,
    this.isLoading = false,
    this.error,

    // ── Customisation ────────────────────────────────────────────────────────
    this.title = 'Top Movers',
    this.headerIcon = Icons.auto_graph_rounded,

    /// Override the teal accent used for the header icon background.
    /// Defaults to a teal #00C896 that works on both themes.
    this.headerAccent,

    /// Override the color used for gainer tiles, pill, and glow.
    /// Defaults to green (#00B894 dark / #00956B light) from AppColors.
    this.positiveColor,

    /// Override the color used for loser tiles, pill, and glow.
    /// Defaults to red (#FF7675 dark / #DC2626 light) from AppColors.
    this.negativeColor,

    /// Card corner radius. Default: 18.
    this.borderRadius = 18.0,

    /// Maximum stock tiles per Gainers/Losers column. Default: 5.
    this.maxItemsPerColumn = 5,

    /// Width below which the widget switches to mobile segmented-toggle layout.
    this.mobileBreakpoint = 600.0,

    /// Optional "See All" callback — renders a button in the header when set.
    this.onViewAll,
    this.headerTrailing,
  });

  final List<AmMoverItem> gainers;
  final List<AmMoverItem> losers;
  final bool isLoading;
  final String? error;

  final String title;
  final IconData headerIcon;
  final Color? headerAccent;
  final Color? positiveColor;
  final Color? negativeColor;
  final double borderRadius;
  final int maxItemsPerColumn;
  final double mobileBreakpoint;
  final VoidCallback? onViewAll;

  /// Optional widget shown on the right of the header (e.g. selected index chip).
  final Widget? headerTrailing;

  @override
  State<AmTopMoversPanel> createState() => _AmTopMoversPanelState();
}

class _AmTopMoversPanelState extends State<AmTopMoversPanel> {
  /// Mobile toggle state — true = show Gainers, false = show Losers.
  bool _showGainers = true;

  // ── Resolved colors (theme-adaptive defaults with override support) ────────

  Color _positiveColor(bool isDark) =>
      widget.positiveColor ??
      (isDark ? const Color(0xFF00B894) : const Color(0xFF00956B));

  Color _negativeColor(bool isDark) =>
      widget.negativeColor ??
      (isDark ? const Color(0xFFFF7675) : const Color(0xFFDC2626));

  Color _headerAccent() =>
      widget.headerAccent ?? const Color(0xFF00C896);

  // ── Card border color via theme ───────────────────────────────────────────
  Color _borderColor(bool isDark) =>
      isDark ? const Color(0xFF2A3347) : const Color(0xFFCBD5E1);

  double _borderWidth(bool isDark) => isDark ? 1.0 : 1.5;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _headerAccent();

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            // Gradient: dark = navy tones, light = white/light-slate
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0F1117).withOpacity(0.92),
                      const Color(0xFF1A1F2E).withOpacity(0.85),
                    ]
                  : [
                      Colors.white.withOpacity(0.95),
                      const Color(0xFFF8FAFC).withOpacity(0.90),
                    ],
            ),
            border: Border.all(
              color: _borderColor(isDark),
              width: _borderWidth(isDark),
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, accent, isDark),
              const SizedBox(height: 16),
              _buildContent(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, Color accent, bool isDark) {
    final titleColor = isDark ? Colors.white.withOpacity(0.92) : const Color(0xFF0F172A);

    return Row(
      children: [
        // Accent icon badge
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(widget.headerIcon, color: accent, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            widget.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: -0.3,
              color: titleColor,
            ),
          ),
        ),
        if (widget.headerTrailing != null) ...[
          const SizedBox(width: 8),
          widget.headerTrailing!,
        ],
        // Optional "See All" button
        if (widget.onViewAll != null)
          TextButton(
            onPressed: widget.onViewAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: accent.withOpacity(0.10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              'See All',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
      ],
    );
  }

  // ── Content: loading / error / empty / responsive layout ──────────────────
  Widget _buildContent(BuildContext context, bool isDark) {
    // ── Loading ──
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

    // ── Error ──
    if (widget.error != null) {
      final errColor = _negativeColor(isDark);
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: errColor, size: 48),
              const SizedBox(height: 8),
              Text(
                'Failed to load movers data',
                style: TextStyle(color: errColor, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                widget.error!,
                style: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.45)
                        : const Color(0xFF94A3B8),
                    fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // ── Empty ──
    if (widget.gainers.isEmpty && widget.losers.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.data_usage_outlined,
                color: isDark
                    ? Colors.white.withOpacity(0.35)
                    : const Color(0xFF94A3B8),
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'No movers data available',
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.45)
                      : const Color(0xFF94A3B8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < widget.mobileBreakpoint;

    if (isMobile) {
      return _buildMobileLayout(context, isDark);
    }
    return _buildDesktopLayout(context, isDark);
  }

  // ── Mobile layout: segmented toggle + AnimatedSwitcher ────────────────────
  Widget _buildMobileLayout(BuildContext context, bool isDark) {
    final posColor = _positiveColor(isDark);
    final negColor = _negativeColor(isDark);
    final mutedColor = isDark
        ? Colors.white.withOpacity(0.40)
        : const Color(0xFF94A3B8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Segmented toggle bar
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
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
                      color: _showGainers
                          ? posColor.withOpacity(isDark ? 0.15 : 0.12)
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
                          color: _showGainers ? posColor : mutedColor,
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
                      color: !_showGainers
                          ? negColor.withOpacity(isDark ? 0.14 : 0.10)
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
                          color: !_showGainers ? negColor : mutedColor,
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
        // Fades between Gainers and Losers lists
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showGainers
              ? _buildColumn(
                  context, 'Gainers', widget.gainers, true, isDark,
                  key: const ValueKey('gainers'))
              : _buildColumn(
                  context, 'Losers', widget.losers, false, isDark,
                  key: const ValueKey('losers')),
        ),
      ],
    );
  }

  // ── Desktop layout: side-by-side columns ──────────────────────────────────
  Widget _buildDesktopLayout(BuildContext context, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildColumn(context, 'Gainers', widget.gainers, true, isDark),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildColumn(context, 'Losers', widget.losers, false, isDark),
        ),
      ],
    );
  }

  // ── Column: section label + tile list ─────────────────────────────────────
  Widget _buildColumn(
    BuildContext context,
    String label,
    List<AmMoverItem> items,
    bool isGainers,
    bool isDark, {
    Key? key,
  }) {
    final color = isGainers ? _positiveColor(isDark) : _negativeColor(isDark);
    final displayItems = items.take(widget.maxItemsPerColumn).toList();

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column header: trend icon + label + count
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
              '$label (${items.length})',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Tile list or empty state
        if (displayItems.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Text(
                'No ${isGainers ? 'gainers' : 'losers'} found',
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.40)
                      : const Color(0xFF94A3B8),
                  fontSize: 13,
                ),
              ),
            ),
          )
        else
          ...displayItems.map(
            (item) => AmMoverTile(
              item: item,
              positiveColor: _positiveColor(isDark),
              negativeColor: _negativeColor(isDark),
              isDark: isDark,
            ),
          ),
      ],
    );
  }
}
