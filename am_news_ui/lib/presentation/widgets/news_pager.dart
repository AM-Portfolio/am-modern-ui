import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// Previous / Next footer for Market Intelligence lists.
class NewsPager extends StatelessWidget {
  const NewsPager({
    super.key,
    required this.page,
    required this.pageCount,
    this.onPrevious,
    this.onNext,
  });

  final int page;
  final int pageCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.dashboard;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        children: [
          TextButton(
            onPressed: onPrevious,
            style: TextButton.styleFrom(
              foregroundColor: accent,
              disabledForegroundColor:
                  context.colors.textSecondary.withValues(alpha: 0.4),
            ),
            child: const Text('Previous'),
          ),
          Expanded(
            child: Text(
              'Page ${page + 1} of $pageCount',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Inter',
                color: context.colors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: onNext,
            style: TextButton.styleFrom(
              foregroundColor: accent,
              disabledForegroundColor:
                  context.colors.textSecondary.withValues(alpha: 0.4),
            ),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}
