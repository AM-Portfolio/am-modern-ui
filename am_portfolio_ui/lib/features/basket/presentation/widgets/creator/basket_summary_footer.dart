
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../domain/models/custom_basket.dart';

class BasketSummaryFooter extends StatelessWidget {
  final CustomBasket basket;
  final VoidCallback onBuildBasket;

  const BasketSummaryFooter({
    Key? key,
    required this.basket,
    required this.onBuildBasket,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.6),
          ],
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Summary Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat(
                        context,
                        'Stocks',
                        '${basket.stocks.length}',
                        Icons.trending_up,
                        Colors.blue,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      _buildStat(
                        context,
                        'Investment',
                        '₹${_formatAmount(basket.investmentAmount)}',
                        Icons.account_balance_wallet,
                        Colors.green,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      _buildStat(
                        context,
                        'Projected CAGR',
                        basket.projectedCAGR != null
                            ? '${basket.projectedCAGR!.toStringAsFixed(1)}%'
                            : '--',
                        Icons.show_chart,
                        Colors.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Build Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: basket.stocks.isEmpty ? null : onBuildBasket,
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: basket.stocks.isEmpty
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF00D4AA),
                                    Color(0xFF00A3CC),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.rocket_launch, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                basket.stocks.isEmpty
                                    ? 'Add Stocks to Build'
                                    : 'Build Basket',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)} K';
    }
    return amount.toStringAsFixed(0);
  }
}
