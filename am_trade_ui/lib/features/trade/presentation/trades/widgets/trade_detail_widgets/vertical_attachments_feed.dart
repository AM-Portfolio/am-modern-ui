import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/trade_holding_view_model.dart';

class VerticalAttachmentsFeed extends StatefulWidget {
  const VerticalAttachmentsFeed({required this.trade, super.key});

  final TradeHoldingViewModel trade;

  @override
  State<VerticalAttachmentsFeed> createState() => _VerticalAttachmentsFeedState();
}

class _VerticalAttachmentsFeedState extends State<VerticalAttachmentsFeed> {
  int? _hoveredIndex;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attachments = (widget.trade.attachments ?? [])
        .where((att) => att.fileUrl != null && att.fileUrl!.isNotEmpty)
        .toList();

    if (attachments.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.image_rounded, size: 24, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Evidence & Analysis',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.3),
                  ),
                  Text(
                    '${attachments.length} ${attachments.length == 1 ? 'image' : 'images'} attached',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Compact Grid of Attachments (3-4 images per row)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: attachments.length,
            itemBuilder: (context, index) {
              final attachment = attachments[index];
              return _buildCompactImageTile(context, attachment, index, attachments);
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Builds a compact image tile for the grid layout (3-4 per row)
  Widget _buildCompactImageTile(BuildContext context, attachment, int index, List<dynamic> allAttachments) =>
      MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: GestureDetector(
          onTap: () => _showFullImageDialog(context, index, allAttachments),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    attachment.fileUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Theme.of(context).colorScheme.surface,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Center(
                        child: Icon(Icons.broken_image_rounded, color: Theme.of(context).colorScheme.error, size: 32),
                      ),
                    ),
                  ),
                ),

                // Hover overlay with full info
                if (_hoveredIndex == index)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              'View',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Index badge (always visible)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildEmptyState(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: Theme.of(context).primaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Images Attached',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Attach images to this trade to see them here',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          ),
        ],
      ),
    ),
  );

  void _showFullImageDialog(BuildContext context, int startIndex, List<dynamic> attachments) {
    showDialog(
      context: context,
      builder: (context) => _FullScreenImageViewer(attachments: attachments, initialIndex: startIndex),
    );
  }
}

/// Full-screen image viewer with left/right navigation
class _FullScreenImageViewer extends StatefulWidget {
  const _FullScreenImageViewer({required this.attachments, required this.initialIndex});

  final List<dynamic> attachments;
  final int initialIndex;

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attachment = widget.attachments[_currentIndex];
    final fileName = attachment.fileName ?? 'Image ${_currentIndex + 1}';
    final description = attachment.description ?? '';
    final uploadedAtStr = attachment.uploadedAt ?? '';

    DateTime? uploadDate;
    try {
      if (uploadedAtStr.isNotEmpty) {
        uploadDate = DateTime.parse(uploadedAtStr);
      }
    } catch (e) {
      // Date parsing failed
    }

    final formattedDate = uploadDate != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(uploadDate) : 'Date unknown';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // PageView for image navigation
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: widget.attachments.length,
            itemBuilder: (context, index) {
              final att = widget.attachments[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  att.fileUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          const Text('Image failed to load'),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Left/Right tap zones for navigation
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 80,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _currentIndex > 0
                    ? () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      )
                    : null,
                hoverColor: Colors.white.withOpacity(_currentIndex > 0 ? 0.1 : 0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _currentIndex > 0 ? Colors.white.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white.withOpacity(_currentIndex > 0 ? 0.8 : 0.3),
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 80,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _currentIndex < widget.attachments.length - 1
                    ? () =>
                          _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                    : null,
                hoverColor: Colors.white.withOpacity(_currentIndex < widget.attachments.length - 1 ? 0.1 : 0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _currentIndex < widget.attachments.length - 1
                          ? Colors.white.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withOpacity(_currentIndex < widget.attachments.length - 1 ? 0.8 : 0.3),
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Close Button
          Positioned(
            top: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),

          // Bottom Navigation Buttons
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _currentIndex > 0
                        ? () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white.withOpacity(_currentIndex > 0 ? 0.9 : 0.4),
                      ),
                    ),
                  ),
                ),

                // Image counter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.attachments.length}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),

                // Next button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _currentIndex < widget.attachments.length - 1
                        ? () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withOpacity(_currentIndex < widget.attachments.length - 1 ? 0.9 : 0.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info at Top
          Positioned(
            top: 60,
            left: 16,
            right: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(formattedDate, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
