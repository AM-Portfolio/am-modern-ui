import 'package:flutter/material.dart';
import '../../../../../core/app_logic/domain/entities/portfolio/portfolio_summary.dart';

class PortfolioIOSScreen extends StatelessWidget {
  const PortfolioIOSScreen({
    required this.portfolioSummaryFuture,
    required this.refreshPortfolio,
    required this.userId,
    super.key,
  });
  final Future<PortfolioSummary> portfolioSummaryFuture;
  final Future<void> Function() refreshPortfolio;
  final String userId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Portfolio - iOS')),
    body: FutureBuilder<PortfolioSummary>(
      future: portfolioSummaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final summary = snapshot.data;
        if (summary == null) {
          return const Center(child: Text('No data available'));
        }

        return const Center(
          child: Text('iOS Portfolio View - Implementation needed'),
        );
      },
    ),
  );
}
