
import 'package:flutter/material.dart';
import 'dart:ui';
import 'basket_gauge_painter.dart';

class BasketHeroCard extends StatelessWidget {
  final String etfName;
  final double matchScore;
  final int? missingStockCount;

  const BasketHeroCard({
    Key? key,
    required this.etfName,
    required this.matchScore,
    this.missingStockCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Gauge
                AnimatedRadialGauge(
                  percentage: matchScore,
                  size: 180,
                  fillColor: _getColorForScore(matchScore),
                ),
                const SizedBox(height: 24),
                
                // ETF Name
                Text(
                  etfName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Gap Summary
                if (missingStockCount != null && missingStockCount! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      'You are $missingStockCount stock${missingStockCount! > 1 ? 's' : ''} away from completing this basket',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.orange[200],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      'Perfect Match! You hold all required stocks.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.green[200],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForScore(double score) {
    if (score >= 90) {
      return Colors.greenAccent;
    } else if (score >= 75) {
      return Colors.tealAccent;
    } else if (score >= 60) {
      return Colors.orangeAccent;
    } else {
      return Colors.redAccent;
    }
  }
}
