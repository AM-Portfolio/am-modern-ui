import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/am_design_system.dart';

/// Web-specific portfolio holdings page with template-based architecture
class PortfolioHoldingsWebPage extends StatelessWidget {
  const PortfolioHoldingsWebPage({
    required this.userId,
    required this.portfolioId,
    super.key,
    this.portfolioName,
  });

  final String userId;
  final String portfolioId;
  final String? portfolioName;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.construction, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          Text(
            portfolioName != null
                ? '$portfolioName Holdings'
                : 'Portfolio Holdings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Holdings view is being refactored',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms),
  );

  void _showHoldingDetails(BuildContext context, holding) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(holding.symbol ?? 'Holding Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Symbol', holding.symbol ?? 'N/A'),
              _buildDetailRow(
                'Quantity',
                holding.quantity?.toString() ?? 'N/A',
              ),
              _buildDetailRow(
                'Market Value',
                '\$${holding.marketValue?.toStringAsFixed(2) ?? 'N/A'}',
              ),
              _buildDetailRow(
                'Cost Basis',
                '\$${holding.costBasis?.toStringAsFixed(2) ?? 'N/A'}',
              ),
              _buildDetailRow(
                'Total Gain/Loss',
                '\$${holding.totalGainLoss?.toStringAsFixed(2) ?? 'N/A'}',
              ),
              _buildDetailRow(
                'Daily Change',
                '\$${holding.dailyChange?.toStringAsFixed(2) ?? 'N/A'}',
              ),
              _buildDetailRow('Sector', holding.sector ?? 'N/A'),
              _buildDetailRow(
                'Weight',
                '${holding.weight?.toStringAsFixed(2) ?? 'N/A'}%',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(value, style: const TextStyle(fontSize: 14)),
      ],
    ),
  );
}
