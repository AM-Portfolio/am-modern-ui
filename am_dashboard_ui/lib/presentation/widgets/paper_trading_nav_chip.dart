import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// Compact top-nav CTA: flask + "Paper trading" + "Try" badge.
///
/// Opens the paper desk when tapped. Fits the Dashboard glass pill track.
class PaperTradingNavChip extends StatelessWidget {
  const PaperTradingNavChip({
    required this.onTap,
    this.compact = false,
    super.key,
  });

  final VoidCallback onTap;

  /// Icon + "Try" only (very narrow widths).
  final bool compact;

  static const _accent = Color(0xFF38BDF8); // sky / lab feel

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final narrow = compact || MediaQuery.sizeOf(context).width < 380;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 36,
          padding: EdgeInsets.only(
            left: 8,
            right: narrow ? 6 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _accent.withValues(alpha: isDark ? 0.22 : 0.14),
                ModuleColors.dashboard.withValues(alpha: isDark ? 0.18 : 0.10),
              ],
            ),
            border: Border.all(
              color: _accent.withValues(alpha: isDark ? 0.55 : 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: isDark ? 0.18 : 0.10),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.science_outlined,
                size: 16,
                color: _accent,
              ),
              if (!narrow) ...[
                const SizedBox(width: 6),
                Text(
                  'Paper trading',
                  style: TextStyle(
                    color: isDark ? Colors.white : context.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: isDark ? 0.28 : 0.20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _accent.withValues(alpha: 0.65),
                  ),
                ),
                child: Text(
                  'Try',
                  style: TextStyle(
                    color: isDark ? Colors.white : _accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
