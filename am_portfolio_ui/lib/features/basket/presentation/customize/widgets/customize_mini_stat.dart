import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

class CustomizeMiniStat extends StatelessWidget {
  final String label;
  final String value;

  const CustomizeMiniStat({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 9, color: context.textTertiary)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textPrimary)),
      ],
    );
  }
}
