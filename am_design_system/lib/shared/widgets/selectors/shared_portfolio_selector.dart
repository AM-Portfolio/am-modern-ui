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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(8), // Reduced padding
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C3E) : Colors.transparent, // Transparent in Light Mode
        borderRadius: BorderRadius.circular(12),
        // subtle border only in dark mode or if needed
        border: isDarkMode ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Icon + Portfolio Name + Dropdown Arrow
          InkWell(
            onTap: () {}, // Could act as a trigger, but we use the Dropdown below
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                // Icon Box
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.black26 : effectiveAccent, // Filled in light mode
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: 16,
                    color: isDarkMode ? effectiveAccent : Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Titles
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Portfolio', // "Institute of Account" equivalent
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      
                      // Dropdown embedded as the main title
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: currentPortfolioId,
                          isDense: true,
                          isExpanded: true,
                          dropdownColor: cardBgColor,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: textColor,
                          ),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter', // Ensure premium font
                          ),
                          items: portfolios.map((portfolio) => DropdownMenuItem<String>(
                            value: idExtractor(portfolio),
                            child: Text(
                              nameExtractor(portfolio),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: textColor),
                            ),
                          )).toList(),
                          onChanged: (portfolioId) {
                            if (portfolioId != null) {
                              final portfolio =
                                  portfolios.firstWhere((p) => idExtractor(p) == portfolioId);
                              onPortfolioSelected(portfolioId, nameExtractor(portfolio));
                            }
                          },
                          selectedItemBuilder: (context) {
                            return portfolios.map((portfolio) {
                              return Text(
                                nameExtractor(portfolio),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
