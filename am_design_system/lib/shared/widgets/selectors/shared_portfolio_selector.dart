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
    required this.idExtractor,
    required this.nameExtractor,
    this.isCompact = false,
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

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      if (portfolios.isEmpty) return const SizedBox.shrink();
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: PopupMenuButton<String>(
          tooltip: 'Select Portfolio',
          offset: const Offset(40, 0),
          color: const Color(0xFF2C2C3E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5DD3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.account_balance_wallet, color: Color(0xFF6C5DD3), size: 20),
          ),
          onSelected: (portfolioId) {
            final portfolio = portfolios.firstWhere((p) => idExtractor(p) == portfolioId);
            onPortfolioSelected(portfolioId, nameExtractor(portfolio));
          },
          itemBuilder: (context) => portfolios.map((portfolio) => PopupMenuItem<String>(
            value: idExtractor(portfolio),
            child: Text(
              nameExtractor(portfolio),
              style: const TextStyle(color: Colors.white),
            ),
          )).toList(),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
                  color: const Color(0xFF6C5DD3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 14,
                  color: Color(0xFF6C5DD3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Portfolio',
                      style: TextStyle(
                        color: Color(0xFF6C5DD3),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentPortfolioName ?? 'No Portfolio',
                      style: const TextStyle(
                        color: Colors.white,
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
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currentPortfolioId,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF2C2C3E),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.white70,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  hint: const Text(
                    'Select Portfolio',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  items: portfolios.map((portfolio) => DropdownMenuItem<String>(
                    value: idExtractor(portfolio),
                    child: Text(
                      nameExtractor(portfolio),
                      overflow: TextOverflow.ellipsis,
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
