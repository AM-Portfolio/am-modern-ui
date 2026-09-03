import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// Info banner shown when the user is viewing the shared demo portfolio.
///
/// The demo stays visible until the user uploads or links a real portfolio.
/// "Start Fresh" opens the upload / doc-intel flow — it does not dismiss the demo.
class DemoPortfolioBanner extends StatelessWidget {
  const DemoPortfolioBanner({super.key, this.onUploadPortfolio});

  /// Opens brokerage upload / doc-intel. When null, the CTA is hidden.
  final VoidCallback? onUploadPortfolio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ModuleColors.portfolio.withValues(alpha: 0.15),
            ModuleColors.portfolio.withValues(alpha: 0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ModuleColors.portfolio.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 20,
            color: ModuleColors.portfolio,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome! This is a demo portfolio.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Upload your trades or link a broker to replace it with your real portfolio.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          if (onUploadPortfolio != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: onUploadPortfolio,
              style: TextButton.styleFrom(
                foregroundColor: ModuleColors.portfolio,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: ModuleColors.portfolio.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: const Text('Upload portfolio'),
            ),
          ],
        ],
      ),
    );
  }
}
