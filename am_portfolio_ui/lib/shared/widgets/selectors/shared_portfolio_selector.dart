import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// A reusable widget for selecting a portfolio, extracted from the Trade Sidebar logic.
/// Designed to be flexible with different portfolio data models via extractors.
class SharedPortfolioSelector<T> extends StatelessWidget {
  const SharedPortfolioSelector({
    required this.currentPortfolioId,
    required this.currentPortfolioName,
    required this.portfolios,
    required this.onPortfolioSelected,
    required this.idExtractor,
    required this.nameExtractor,
    super.key,
    this.isCompact = false,
    this.accentColor,
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

  /// Primary accent color
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Priority: explicit accentColor prop > ModuleColorProvider > Theme primaryColor
    final color = accentColor ?? ModuleColorProvider.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Automatically switch to compact mode if width is constrained or explicitly requested
        final effectiveCompact = isCompact || constraints.maxWidth < 100;

        if (effectiveCompact) {
          if (portfolios.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: PopupMenuButton<String>(
              tooltip: 'Select Portfolio',
              offset: const Offset(40, 0),
              color: isDark ? const Color(0xFF2C2C3E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: color,
                  size: 20,
                ),
              ),
              onSelected: (portfolioId) {
                final portfolio = portfolios.firstWhere(
                  (p) => idExtractor(p) == portfolioId,
                );
                onPortfolioSelected(portfolioId, nameExtractor(portfolio));
              },
              itemBuilder: (context) => portfolios
                  .map(
                    (portfolio) => PopupMenuItem<String>(
                      value: idExtractor(portfolio),
                      child: Text(
                        nameExtractor(portfolio),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        }

        return SidebarSelector(
          accentColor: color,
          isCompact: effectiveCompact,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        size: 14,
                        color: color,
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
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentPortfolioName ?? 'No Portfolio',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
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
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentPortfolioId,
                        isExpanded: true,
                        dropdownColor: isDark
                            ? const Color(0xFF2C2C3E)
                            : Colors.white,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 12,
                        ),
                        hint: Text(
                          'Select Portfolio',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black45,
                            fontSize: 12,
                          ),
                        ),
                        items: portfolios
                            .map(
                              (portfolio) => DropdownMenuItem<String>(
                                value: idExtractor(portfolio),
                                child: Text(
                                  nameExtractor(portfolio),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (portfolioId) {
                          if (portfolioId != null) {
                            final portfolio = portfolios.firstWhere(
                              (p) => idExtractor(p) == portfolioId,
                            );
                            onPortfolioSelected(
                              portfolioId,
                              nameExtractor(portfolio),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
