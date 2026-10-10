import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// Native builds: Email Extractor requires web/OAuth — styled empty state only.
class EmailExtractorView extends StatelessWidget {
  const EmailExtractorView({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.analytics;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          decoration: BoxDecoration(
            color: isDark
                ? context.colors.cardSurface.withValues(alpha: 0.6)
                : context.colors.cardSurface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: accent.withValues(alpha: isDark ? 0.35 : 0.25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.mail_outline_rounded,
                  size: 36,
                  color: accent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Email Extractor',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Available on web. Use Document Processor on mobile to upload broker files.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
