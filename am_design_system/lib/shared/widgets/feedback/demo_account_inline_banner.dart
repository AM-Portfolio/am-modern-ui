import 'package:flutter/material.dart';

import '../../../core/module/module_config.dart';
import 'demo_account_badge.dart';

/// Single-row demo chrome: badge + short welcome + optional one Upload CTA.
///
/// Use this in page headers so badge and banner copy share one line and do not
/// duplicate an Upload action already provided by the parent (pass [onUploadPortfolio]
/// only when this strip owns the CTA).
class DemoAccountInlineBanner extends StatelessWidget {
  const DemoAccountInlineBanner({
    super.key,
    this.onUploadPortfolio,
  });

  /// When set, shows a single "Upload portfolio" button in this strip.
  final VoidCallback? onUploadPortfolio;

  static const _message =
      'Welcome! Upload trades or link a broker to replace this demo portfolio.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Row(
      children: [
        const DemoAccountBadge(),
        const SizedBox(width: 10),
        Icon(
          Icons.auto_awesome_outlined,
          size: 16,
          color: ModuleColors.portfolio,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            _message,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: onSurface.withValues(alpha: 0.75),
              height: 1.2,
            ),
          ),
        ),
        if (onUploadPortfolio != null) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: onUploadPortfolio,
            style: TextButton.styleFrom(
              foregroundColor: ModuleColors.portfolio,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              visualDensity: VisualDensity.compact,
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
    );
  }
}
