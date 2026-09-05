import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../utils/basket_responsive.dart';

class BdPageHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onShare;
  final VoidCallback? onDownload;
  final VoidCallback? onMore;

  const BdPageHeader({
    super.key,
    this.onBack,
    this.onShare,
    this.onDownload,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = BasketResponsive.isMobile(context);

    if (isMobile) {
      if (onMore == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
        child: Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(Icons.more_horiz),
            visualDensity: VisualDensity.compact,
            onPressed: onMore,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, AppSpacing.md, 16, AppSpacing.sm),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
          Expanded(
            child: Text(
              'Basket Dashboard',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton.icon(
            onPressed: onShare,
            icon: Icon(Icons.share_outlined,
                size: 18, color: ModuleColors.portfolio),
            label: const Text('Share'),
            style: TextButton.styleFrom(
              foregroundColor: ModuleColors.portfolio,
            ),
          ),
          TextButton.icon(
            onPressed: onDownload,
            icon: Icon(Icons.download_outlined,
                size: 18, color: ModuleColors.portfolio),
            label: const Text('Download'),
            style: TextButton.styleFrom(
              foregroundColor: ModuleColors.portfolio,
            ),
          ),
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: onMore),
        ],
      ),
    );
  }
}
