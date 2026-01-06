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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBorderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: effectiveAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  size: 14,
                  color: effectiveAccent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Portfolio',
                      style: TextStyle(
                        color: effectiveAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentPortfolioName ?? 'No Portfolio',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (portfolios.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cardBorderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currentPortfolioId,
                  isExpanded: true,
                  dropdownColor: cardBgColor,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: subTextColor,
                  ),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                  ),
                  hint: Text(
                    'Select Portfolio',
                    style: TextStyle(color: subTextColor, fontSize: 12),
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
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
