import 'package:flutter/material.dart';

/// Reusable step indicator widget for multi-step wizards
class StepIndicator extends StatelessWidget {
  const StepIndicator({
    required this.currentStep,
    required this.stepLabels,
    super.key,
    this.activeColor = const Color(0xFFFF9800),
    this.inactiveColor = Colors.grey,
  });
  final int currentStep;
  final List<String> stepLabels;
  final Color activeColor;
  final Color inactiveColor;

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
        final dotSize = (screenWidth * 0.06).clamp(28.0, 40.0);
        final fontSize = (screenWidth * 0.022).clamp(10.0, 14.0);
        final iconSize = (dotSize * 0.5).clamp(14.0, 20.0);

        return Column(
          children: [
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: isActive ? activeColor : inactiveColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(dotSize / 2),
                border: isCurrent
                    ? Border.all(color: activeColor, width: 2)
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
                          fontSize: (fontSize * 0.9).clamp(8.0, 12.0),
                        ),
                      ),
              ),
            ),
            SizedBox(height: screenWidth * 0.015),
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
        final lineWidth = (screenWidth * 0.04).clamp(16.0, 32.0);
        final bottomMargin = (screenWidth * 0.035).clamp(15.0, 25.0);

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
