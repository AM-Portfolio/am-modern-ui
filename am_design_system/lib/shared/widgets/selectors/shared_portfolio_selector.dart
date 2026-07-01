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
    final cardBorderColor = isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);

    String displayName = 'Select Portfolio';
    if (currentPortfolioName != null) {
      displayName = currentPortfolioName!;
    } else if (currentPortfolioId != null && portfolios.isNotEmpty) {
      try {
        final portfolio = portfolios.firstWhere((p) => idExtractor(p) == currentPortfolioId);
        displayName = nameExtractor(portfolio);
      } catch (_) {}
    }

    if (isCompact) {
      if (portfolios.isEmpty) return const SizedBox.shrink();
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
            final portfolio = portfolios.firstWhere((p) => idExtractor(p) == portfolioId);
            onPortfolioSelected(portfolioId, nameExtractor(portfolio));
          },
          itemBuilder: (context) => portfolios.map((portfolio) => PopupMenuItem<String>(
            value: idExtractor(portfolio),
            child: Text(
              nameExtractor(portfolio),
              style: TextStyle(color: textColor),
            ),
          )).toList(),
        ),
      );
    }

    // Cleaner, flatter design for "Header-like" feel
    // Match the screenshot: A simple rounded outline box with "Current Portfolio" above it
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
          PopupMenuButton<String>(
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
              final portfolio = portfolios.firstWhere((p) => idExtractor(p) == portfolioId);
              onPortfolioSelected(portfolioId, nameExtractor(portfolio));
            },
            itemBuilder: (context) => portfolios.map((portfolio) {
              final pId = idExtractor(portfolio);
              final isSelected = pId == currentPortfolioId;
              return PopupMenuItem<String>(
                value: pId,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        nameExtractor(portfolio),
                        style: TextStyle(
                          color: isSelected ? effectiveAccent : textColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check, size: 16, color: effectiveAccent),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.transparent : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
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
        ],
      ),
    );
  }
}

