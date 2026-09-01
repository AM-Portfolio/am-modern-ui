import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../domain/models/basket_opportunity.dart';
import '../basket_item_status_theme.dart';

class BasketStatusBadge extends StatelessWidget {
  final ItemStatus? status;
  final bool isExcluded;

  const BasketStatusBadge({
    super.key,
    this.status,
    this.isExcluded = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = BasketItemStatusTheme.labelFor(status, isExcluded: isExcluded);
    if (label.isEmpty) return const SizedBox.shrink();
    final color =
        BasketItemStatusTheme.colorFor(context, status, isExcluded: isExcluded);
    return _pill(label, color);
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class BasketStatusDot extends StatelessWidget {
  final ItemStatus? status;
  final bool isExcluded;

  const BasketStatusDot({
    super.key,
    this.status,
    this.isExcluded = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        BasketItemStatusTheme.colorFor(context, status, isExcluded: isExcluded);
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
