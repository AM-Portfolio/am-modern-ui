import 'package:flutter/material.dart';

/// Reusable step indicator widget for multi-step wizards
class StepIndicator extends StatelessWidget {
  const StepIndicator({
    required this.currentStep,
    required this.stepLabels,
    super.key,
    this.activeColor = const Color(0xFFFF9800),
    this.inactiveColor = Colors.grey,
    this.compact = false,
  });
  final int currentStep;
  final List<String> stepLabels;
  final Color activeColor;
  final Color inactiveColor;

  /// Smaller dots/labels for embedded panes (e.g. trade journal workflow).
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (int i = 0; i < stepLabels.length; i++) ...[
        Expanded(child: _buildStepDot(i, stepLabels[i])),
        if (i < stepLabels.length - 1) _buildStepLine(i),
      ],
    ],
  );

  Widget _buildStepDot(int step, String label) {
    final isActive = step <= currentStep;
    final isCurrent = step == currentStep;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dotSize = compact
            ? 22.0
            : (screenWidth * 0.06).clamp(28.0, 40.0);
        final fontSize = compact
            ? 11.0
            : (screenWidth * 0.022).clamp(10.0, 14.0);
        final iconSize = compact
            ? 12.0
            : (dotSize * 0.5).clamp(14.0, 20.0);
        final labelGap = compact ? 4.0 : screenWidth * 0.015;

        return Column(
          children: [
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: isActive ? activeColor : inactiveColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(dotSize / 2),
                border: isCurrent
                    ? Border.all(color: activeColor, width: compact ? 1.5 : 2)
                    : null,
              ),
              child: Center(
                child: isActive && step < currentStep
                    ? Icon(Icons.check, color: Colors.white, size: iconSize)
                    : Text(
                        '${step + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : inactiveColor,
                          fontWeight: FontWeight.bold,
                          fontSize: compact
                              ? 11.0
                              : (fontSize * 0.9).clamp(8.0, 12.0),
                        ),
                      ),
              ),
            ),
            SizedBox(height: labelGap),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = step < currentStep;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final lineWidth = compact
            ? 16.0
            : (screenWidth * 0.04).clamp(16.0, 32.0);
        final bottomMargin = compact
            ? 14.0
            : (screenWidth * 0.035).clamp(15.0, 25.0);

        return Container(
          height: 2,
          width: lineWidth,
          color: isActive ? activeColor : inactiveColor.withOpacity(0.3),
          margin: EdgeInsets.only(bottom: bottomMargin),
        );
      },
    );
  }
}
