import 'package:flutter/material.dart';

/// A reusable widget for selecting a portfolio, extracted from the Trade Sidebar logic.
/// Designed to be flexible with different portfolio data models via extractors.
class SharedPortfolioSelector<T> extends StatelessWidget {
  const SharedPortfolioSelector({
    super.key,
    required this.currentPortfolioId,
    required this.currentPortfolioName,
    required this.portfolios,
    required this.onPortfolioSelected,
    required this.nameExtractor,
    required this.idExtractor,
    this.onRenamePortfolio,
    this.isCompact = false,
    this.accentColor,
    this.isDark,
  });

  /// The ID of the currently selected portfolio
  final String? currentPortfolioId;

  /// The name of the currently selected portfolio
  final String? currentPortfolioName;

  /// List of portfolio objects
  final List<T> portfolios;

  /// Callback when a portfolio is selected
  final Function(String id, String name) onPortfolioSelected;

  /// Function to extract ID from the portfolio object
  final String Function(T) idExtractor;

  /// Function to extract Name from the portfolio object
  final String Function(T) nameExtractor;

  /// Optional callback to trigger when rename is requested
  final void Function(String id, String currentName)? onRenamePortfolio;

  /// Whether to show in compact mode (icon only)
  final bool isCompact;

  /// Accent color for the selector (defaults to Primary)
  final Color? accentColor;

  /// Whether to render in dark mode (defaults to context theme)
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    // Determine theme mode
    final isDarkMode = isDark ?? Theme.of(context).brightness == Brightness.dark;

    // Determine accent color (default to current primary or purple fallback)
    final effectiveAccent = accentColor ?? const Color(0xFF6C5DD3);

    // Text colors
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = isDarkMode ? Colors.white54 : Colors.black54;

    // Background color for the card
    final cardBgColor = isDarkMode ? const Color(0xFF2C2C3E) : Colors.white;
    final cardBorderColor =
        isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);

    String displayName = 'Select Portfolio';
    if (currentPortfolioName != null) {
      displayName = currentPortfolioName!;
    } else if (currentPortfolioId != null && portfolios.isNotEmpty) {
      try {
        final portfolio =
            portfolios.firstWhere((p) => idExtractor(p) == currentPortfolioId);
        displayName = nameExtractor(portfolio);
      } catch (_) {}
    }

    ThemeData menuTheme(BuildContext context) => Theme.of(context).copyWith(
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: effectiveAccent.withOpacity(0.12),
          popupMenuTheme: PopupMenuThemeData(
            color: cardBgColor,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cardBorderColor),
            ),
          ),
        );

    List<PopupMenuEntry<String>> buildItems(BuildContext context) => portfolios
        .map((portfolio) {
          final pId = idExtractor(portfolio);
          final isSelected = pId == currentPortfolioId;
          return PopupMenuItem<String>(
            value: pId,
            padding: EdgeInsets.zero,
            child: _HoverablePortfolioMenuRow(
              label: nameExtractor(portfolio),
              isSelected: isSelected,
              accent: effectiveAccent,
              textColor: textColor,
              subTextColor: subTextColor,
              onRename: onRenamePortfolio == null
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      onRenamePortfolio!(pId, nameExtractor(portfolio));
                    },
            ),
          );
        })
        .toList();

    if (isCompact) {
      if (portfolios.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Theme(
          data: menuTheme(context),
          child: PopupMenuButton<String>(
            tooltip: 'Select Portfolio',
            offset: const Offset(40, 0),
            color: cardBgColor,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: effectiveAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.account_balance_wallet, color: effectiveAccent, size: 20),
            ),
            onSelected: (portfolioId) {
              final portfolio =
                  portfolios.firstWhere((p) => idExtractor(p) == portfolioId);
              onPortfolioSelected(portfolioId, nameExtractor(portfolio));
            },
            itemBuilder: buildItems,
          ),
        ),
      );
    }

    // Cleaner, flatter design for "Header-like" feel
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Current Portfolio',
            style: TextStyle(
              color: subTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Theme(
            data: menuTheme(context),
            child: PopupMenuButton<String>(
              tooltip: 'Select Portfolio',
              offset: const Offset(0, 48),
              color: cardBgColor,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cardBorderColor),
              ),
              elevation: 8,
              onSelected: (portfolioId) {
                final portfolio =
                    portfolios.firstWhere((p) => idExtractor(p) == portfolioId);
                onPortfolioSelected(portfolioId, nameExtractor(portfolio));
              },
              itemBuilder: buildItems,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.transparent : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: subTextColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Menu row with module-accent hover text + soft highlight.
class _HoverablePortfolioMenuRow extends StatefulWidget {
  const _HoverablePortfolioMenuRow({
    required this.label,
    required this.isSelected,
    required this.accent,
    required this.textColor,
    required this.subTextColor,
    this.onRename,
  });

  final String label;
  final bool isSelected;
  final Color accent;
  final Color textColor;
  final Color subTextColor;
  final VoidCallback? onRename;

  @override
  State<_HoverablePortfolioMenuRow> createState() =>
      _HoverablePortfolioMenuRowState();
}

class _HoverablePortfolioMenuRowState extends State<_HoverablePortfolioMenuRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || widget.isSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: _hovered
              ? widget.accent.withOpacity(0.16)
              : (widget.isSelected
                  ? widget.accent.withOpacity(0.08)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: widget.accent.withOpacity(0.22),
                    blurRadius: 10,
                    spreadRadius: -2,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                style: TextStyle(
                  color: widget.textColor,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (widget.onRename != null)
              GestureDetector(
                onTap: widget.onRename,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 4.0),
                  child: Icon(
                    Icons.edit,
                    size: 16,
                    color: _hovered ? widget.accent : widget.subTextColor,
                  ),
                ),
              ),
            if (widget.isSelected)
              Icon(Icons.check, size: 16, color: widget.accent),
          ],
        ),
      ),
    );
  }
}
