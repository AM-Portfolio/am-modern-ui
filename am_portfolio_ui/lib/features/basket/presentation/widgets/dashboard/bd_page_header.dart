import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, AppSpacing.md, 16, AppSpacing.sm),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
          Expanded(
            child: Text(
              'Basket Dashboard',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text('Share'),
          ),
          TextButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Download'),
          ),
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: onMore),
        ],
      ),
    );
  }
}
