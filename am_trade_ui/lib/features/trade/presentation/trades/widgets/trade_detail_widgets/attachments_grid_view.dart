import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../models/trade_holding_view_model.dart';

class AttachmentsGridView extends StatefulWidget {
  const AttachmentsGridView({required this.trade, super.key});

  final TradeHoldingViewModel trade;

  @override
  State<AttachmentsGridView> createState() => _AttachmentsGridViewState();
}

class _AttachmentsGridViewState extends State<AttachmentsGridView> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
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
        // Section Header with Icon
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
                        'Attachments',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.3),
                      ),
                      Text(
                        '${attachments.length} ${attachments.length == 1 ? 'image' : 'images'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Swipe Indicator Badge
              if (attachments.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 14, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Swipe',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Carousel View with PageView
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: attachments.length,
            itemBuilder: (context, index) {
              final attachment = attachments[index];
              return _buildCarouselItem(context, attachment, index);
            },
          ),
        ),

        // Pagination Indicator with Counter
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dots Indicator
              if (attachments.length > 1)
                Row(
                  children: List.generate(
                    attachments.length,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child:
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width: _currentIndex == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentIndex == index
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ).animate().scale(
                            begin: const Offset(0.8, 0.8),
                            delay: Duration(milliseconds: index * 30),
                          ),
                    ),
                  ),
                ),
              // Counter Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                ),
                child: Text(
                  '${_currentIndex + 1}/${attachments.length}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCarouselItem(BuildContext context, attachment, int index) {
    final fileUrl = attachment.fileUrl ?? '';
    final fileName = attachment.fileName ?? 'Image ${index + 1}';
    final description = attachment.description ?? '';
    final uploadedAtStr = attachment.uploadedAt ?? '';

    // Parse date
    DateTime? uploadDate;
    try {
      if (uploadedAtStr.isNotEmpty) {
        uploadDate = DateTime.parse(uploadedAtStr);
      }
    } catch (e) {
      // Date parsing failed
    }

    final formattedDate = uploadDate != null ? DateFormat('MMM dd, yyyy').format(uploadDate) : 'Unknown';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () => _showFullImageDialog(context, fileUrl, fileName, description, formattedDate),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  Image.network(
                    fileUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                        ),
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                        ),
                      );
                    },
                  ),

                  // Gradient Overlay (top to bottom for text readability)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),

                  // Left/Right navigation tap zones
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 40,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _currentIndex > 0
                            ? () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                            : null,
                        hoverColor: Colors.white.withOpacity(_currentIndex > 0 ? 0.15 : 0),
                        child: _currentIndex > 0
                            ? Center(
                                child: Icon(Icons.chevron_left_rounded, color: Colors.white.withOpacity(0.7), size: 24),
                              )
                            : const SizedBox.expand(),
                      ),
                    ),
                  ),

                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 40,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap:
                            _currentIndex <
                                3 // Assuming max 4 items visible
                            ? () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                            : null,
                        hoverColor: Colors.white.withOpacity(_currentIndex < 3 ? 0.15 : 0),
                        child: _currentIndex < 3
                            ? Center(
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 24,
                                ),
                              )
                            : const SizedBox.expand(),
                      ),
                    ),
                  ),

                  // Content Overlay
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Section: Index Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Text(
                                'Image ${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                            // View Button
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fullscreen_rounded, size: 14, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'View',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Bottom Section: Info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // File Name
                            Text(
                              fileName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Date
                            Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white.withOpacity(0.7)),
                                const SizedBox(width: 4),
                                Text(
                                  formattedDate,
                                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                                ),
                              ],
                            ),
                            // Description (if available)
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                description,
                                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8), height: 1.3),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate().fadeIn(duration: const Duration(milliseconds: 400)).scale(begin: const Offset(0.95, 0.95)),
    );
  }

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
            'No Attachments',
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

  void _showFullImageDialog(
    BuildContext context,
    String imageUrl,
    String fileName,
    String description,
    String formattedDate,
  ) {
    final attachments = (widget.trade.attachments ?? [])
        .where((att) => att.fileUrl != null && att.fileUrl!.isNotEmpty)
        .toList();

    var currentImageIndex = attachments.indexWhere((att) => att.fileUrl == imageUrl);
    if (currentImageIndex == -1) currentImageIndex = 0;

    showDialog(
      context: context,
      builder: (context) => _FullScreenImageViewer(
        attachments: attachments,
        initialIndex: currentImageIndex,
        onClose: () => Navigator.pop(context),
      ),
    );
  }
}

/// Full-screen image viewer with left/right navigation
class _FullScreenImageViewer extends StatefulWidget {
  const _FullScreenImageViewer({required this.attachments, required this.initialIndex, required this.onClose});

  final List<dynamic> attachments;
  final int initialIndex;
  final VoidCallback onClose;

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
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextImage() {
    if (_currentIndex < widget.attachments.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.black.withOpacity(0.95),
    insetPadding: EdgeInsets.zero,
    child: Stack(
      children: [
        // Full-screen PageView
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          itemCount: widget.attachments.length,
          itemBuilder: (context, index) {
            final attachment = widget.attachments[index];
            final fileUrl = attachment.fileUrl ?? '';
            final fileName = attachment.fileName ?? 'Image ${index + 1}';
            final description = attachment.description ?? '';
            final uploadedAtStr = attachment.uploadedAt ?? '';

            DateTime? uploadDate;
            try {
              if (uploadedAtStr.isNotEmpty) {
                uploadDate = DateTime.parse(uploadedAtStr);
              }
            } catch (e) {
              // ignore
            }

            final formattedDate = uploadDate != null
                ? DateFormat('MMM dd, yyyy • hh:mm a').format(uploadDate)
                : 'Date unknown';

            return GestureDetector(
              onTapUp: (details) {
                final screenWidth = MediaQuery.of(context).size.width;
                // Right side tap - next image
                if (details.globalPosition.dx > screenWidth / 2) {
                  _nextImage();
                } else {
                  // Left side tap - previous image
                  _previousImage();
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  Image.network(
                    fileUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported_outlined, size: 64, color: Colors.white.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'Image failed to load',
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                        ),
                      );
                    },
                  ),

                  // Left/Right Navigation Hints
                  Positioned(
                    left: 24,
                    top: 50,
                    child: Opacity(
                      opacity: _currentIndex > 0 ? 1.0 : 0.3,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ),

                  Positioned(
                    right: 24,
                    top: 50,
                    child: Opacity(
                      opacity: _currentIndex < widget.attachments.length - 1 ? 1.0 : 0.3,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ),

                  // Info at Bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fileName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 13,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          formattedDate,
                                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Image Counter
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Text(
                                  '${_currentIndex + 1}/${widget.attachments.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Description
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              description,
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.5),
                              maxLines: 3,
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
          },
        ),

        // Close Button (Top Right)
        Positioned(
          top: 24,
          right: 24,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onClose,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
        ),

        // Bottom Navigation Buttons
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _previousImage,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _currentIndex > 0 ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ),

              // Next Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _nextImage,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _currentIndex < widget.attachments.length - 1
                          ? Colors.white.withOpacity(0.2)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
