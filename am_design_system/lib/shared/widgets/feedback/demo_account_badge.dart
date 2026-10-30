import 'package:flutter/material.dart';

/// Compact inline pill: status dot + "Demo Account".
///
/// Prefer this over [DemoPortfolioBanner] when space is tight (e.g. dashboard
/// title row). Upload CTA stays on existing Add Portfolio actions.
class DemoAccountBadge extends StatelessWidget {
  const DemoAccountBadge({
    super.key,
    this.compact = false,
  });

  /// Dot-only so tight toolbars do not overflow.
  final bool compact;

  static const _accent = Color(0xFFE0B93A);
  static const _dot = Color(0xFFF0D060);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Demo Account',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 12,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _accent.withValues(alpha: 0.7), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(color: _dot, shape: BoxShape.circle),
              child: SizedBox(width: 7, height: 7),
            ),
            if (!compact) ...[
              const SizedBox(width: 7),
              const Text(
                'Demo Account',
                style: TextStyle(
                  color: _accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
