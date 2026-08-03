import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// Reusable Analysis Metrics Panel with AspectRatio layout.
class AnalysisMetricsPanel extends StatelessWidget {
  const AnalysisMetricsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AppCard(
        child: Column(
          children: const [
            Text('Risk Return Metrics Curve', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Placeholder(),
            ),
          ],
        ),
      ),
    );
  }
}
