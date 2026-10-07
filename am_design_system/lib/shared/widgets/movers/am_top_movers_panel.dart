import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/theme/color_extensions.dart';
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

    /// Maximum stock tiles per Gainers/Losers column. Default: 4.
    this.maxItemsPerColumn = 4,

    /// Width below which the widget switches to mobile segmented-toggle layout.
    this.mobileBreakpoint = 600.0,

    /// Optional "See All" callback — renders a button in the header when set.
    this.onViewAll,
    this.headerTrailing,

    /// When true, panel sizes to its content (no `height: infinity` / `Expanded`).
    /// Use inside a parent [SingleChildScrollView] to avoid unbounded flex errors.
    this.scrollEmbedded = false,
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

  /// Scroll-safe layout for embedding in unbounded vertical parents.
  final bool scrollEmbedded;

  @override
  State<AmTopMoversPanel> createState() => _AmTopMoversPanelState();
}

class _AmTopMoversPanelState extends State<AmTopMoversPanel> {
  /// Mobile toggle state — true = show Gainers, false = show Losers.
  bool _showGainers = true;

  // ── Resolved colors (theme-adaptive defaults with override support) ────────

  Color _positiveColor(BuildContext context) =>
      widget.positiveColor ?? context.colors.marketPositiveIndicator;

  Color _negativeColor(BuildContext context) =>
      widget.negativeColor ?? context.colors.marketNegativeIndicator;

  Color _headerAccent([BuildContext? context]) {
    if (widget.headerAccent != null) return widget.headerAccent!;
    if (context != null) return context.colors.marketPositiveIndicator;
    return const Color(0xFF00C896);
  }

  // ── Card border color via theme ───────────────────────────────────────────
  Color _borderColor(BuildContext context, bool isDark) =>
      context.colors.border;

  double _borderWidth(bool isDark) => isDark ? 1.0 : 1.5;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _headerAccent(context);

    final embedded = widget.scrollEmbedded;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: embedded ? null : double.infinity,
          decoration: BoxDecoration(
            // Dynamic theme-adaptive gradient using centralized cardSurface and surface tokens
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      context.colors.cardSurface.withValues(alpha: 0.85),
                      context.colors.surface.withValues(alpha: 0.75),
                    ]
                  : [
                      context.colors.cardSurface.withValues(alpha: 0.95),
                      context.colors.surface.withValues(alpha: 0.90),
                    ],
            ),
            border: Border.all(
              color: _borderColor(context, isDark),
              width: _borderWidth(isDark),
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: embedded ? MainAxisSize.min : MainAxisSize.max,
            children: [
              _buildHeader(context, accent, isDark),
              const SizedBox(height: 10),
              if (embedded)
                _buildContent(context, isDark)
              else
                Expanded(child: _buildContent(context, isDark)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, Color accent, bool isDark) {
    final titleColor = context.colors.textPrimary;

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
      return Center(
        child: CircularProgressIndicator(
          color: _headerAccent(context),
          strokeWidth: 2,
        ),
      );
    }

    // ── Error ──
    if (widget.error != null) {
      final errColor = _negativeColor(context);
      return Center(
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
                  color: context.colors.textTertiary,
                  fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // ── Empty ──
    if (widget.gainers.isEmpty && widget.losers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.data_usage_outlined,
              color: context.colors.textTertiary,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'No movers data available',
              style: TextStyle(
                color: context.colors.textTertiary,
                fontSize: 14,
              ),
            ),
          ],
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
    final posColor = _positiveColor(context);
    final negColor = _negativeColor(context);
    final mutedColor = context.colors.textTertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Segmented toggle bar
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.colors.surface.withValues(alpha: isDark ? 0.55 : 0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.border),
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
        const SizedBox(height: 12),
        // Fades between Gainers and Losers lists
        if (widget.scrollEmbedded)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showGainers
                ? _buildColumn(
                    context, 'Gainers', widget.gainers, true, isDark,
                    key: const ValueKey('gainers'))
                : _buildColumn(
                    context, 'Losers', widget.losers, false, isDark,
                    key: const ValueKey('losers')),
          )
        else
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showGainers
                  ? _buildColumn(
                      context, 'Gainers', widget.gainers, true, isDark,
                      key: const ValueKey('gainers'))
                  : _buildColumn(
                      context, 'Losers', widget.losers, false, isDark,
                      key: const ValueKey('losers')),
            ),
          ),
      ],
    );
  }

  // ── Desktop layout: side-by-side columns ──────────────────────────────────
  Widget _buildDesktopLayout(BuildContext context, bool isDark) {
    return Row(
      crossAxisAlignment: widget.scrollEmbedded
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _buildColumn(context, 'Gainers', widget.gainers, true, isDark),
        ),
        const SizedBox(width: 12),
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
    final color = isGainers ? _positiveColor(context) : _negativeColor(context);
    final displayItems = items.take(widget.maxItemsPerColumn).toList();
    final embedded = widget.scrollEmbedded;

    final listBody = displayItems.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No ${isGainers ? 'gainers' : 'losers'} found',
              style: TextStyle(
                color: context.colors.textTertiary,
                fontSize: 13,
              ),
            ),
          )
        : (embedded
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final item in displayItems)
                    AmMoverTile(
                      item: item,
                      positiveColor: _positiveColor(context),
                      negativeColor: _negativeColor(context),
                      isDark: isDark,
                    ),
                ],
              )
            : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: displayItems.length,
                itemBuilder: (context, index) => AmMoverTile(
                  item: displayItems[index],
                  positiveColor: _positiveColor(context),
                  negativeColor: _negativeColor(context),
                  isDark: isDark,
                ),
              ));

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: embedded ? MainAxisSize.min : MainAxisSize.max,
      children: [
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
        const SizedBox(height: 8),
        if (embedded) listBody else Expanded(child: listBody),
      ],
    );
  }
}
