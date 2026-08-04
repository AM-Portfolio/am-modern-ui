import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// Reusable Analysis Overview Panel.
class AnalysisOverviewPanel extends StatelessWidget {
  const AnalysisOverviewPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Quantitative Portfolio Analysis',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Divider(),
            SizedBox(height: 12),
            Text('Sharpe Ratio: 1.84'),
            Text('Max Drawdown: -8.2%'),
            Text('Alpha: +4.2%'),
          ],
        ),
      ),
    );
  }
}
