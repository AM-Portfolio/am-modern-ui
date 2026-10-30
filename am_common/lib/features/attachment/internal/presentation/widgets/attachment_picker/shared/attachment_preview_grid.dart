import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:am_common/core/config/upload_config.dart';
import 'package:am_common/am_common.dart';
import 'package:am_common/features/attachment/internal/presentation/models/pending_attachment.dart';

/// Shared preview grid for displaying attachments (both uploaded and pending)
class AttachmentPreviewGrid extends StatelessWidget {
  const AttachmentPreviewGrid({
    required this.attachments,
    this.onRemove,
    this.readOnly = false,
    super.key,
  });

  final List<AttachmentItem> attachments;
  final Function(int index)? onRemove;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    AppLogger.debug(
      '📊 Building preview grid with ${attachments.length} attachments',
      tag: 'AttachmentPreview',
    );
    for (var i = 0; i < attachments.length; i++) {
      final item = attachments[i];
      AppLogger.debug(
        '  [$i] isUploaded: ${item.isUploaded}, url: ${item.uploadedUrl}',
        tag: 'AttachmentPreview',
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(
        attachments.length,
        (index) => _buildThumbnail(context, attachments[index], index),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, AttachmentItem item, int index) {
    final theme = Theme.of(context);
    final isStub = item.isUploaded &&
        item.uploadedUrl != null &&
        UploadConfig.isStubOrPlaceholderUrl(item.uploadedUrl!);
    final isImage = !isStub && _isImage(item);
    final canViewImage = isImage && item.isUploaded;

    AppLogger.debug(
      '🖼️ Building thumbnail $index: isImage=$isImage, stub=$isStub, canView=$canViewImage',
      tag: 'AttachmentPreview',
    );
    AppLogger.debug(
      '   readOnly=$readOnly, onRemove=${onRemove != null}',
      tag: 'AttachmentPreview',
    );

    return GestureDetector(
      onTap: canViewImage
          ? () {
              AppLogger.debug(
                '👆 Thumbnail $index clicked!',
                tag: 'AttachmentPreview',
              );
              _viewFullImage(context, item);
            }
          : null,
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: canViewImage
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isStub
                      ? theme.colorScheme.error.withOpacity(0.55)
                      : item.isUploaded
                          ? theme.colorScheme.outline.withOpacity(0.3)
                          : theme.colorScheme.primary.withOpacity(0.5),
                  width: item.isUploaded ? 1 : 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: isStub
                        ? _buildStubPreview(theme)
                        : isImage
                            ? _buildImagePreview(item)
                            : _buildFileIcon(theme, item),
                  ),
                  if (!item.isUploaded)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.pending,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  // Add hover effect for clickable images
                  if (canViewImage)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!readOnly && onRemove != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    onPressed: () => onRemove!(index),
                  ),
                ),
              ),
            if (!item.isUploaded)
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Pending',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStubPreview(ThemeData theme) {
    return ColoredBox(
      color: theme.colorScheme.errorContainer.withOpacity(0.35),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hide_image_outlined,
                size: 28,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 6),
              Text(
                'Re-upload',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewFullImage(BuildContext context, AttachmentItem item) {
    AppLogger.debug(
      '🖼️ Attempting to view full image',
      tag: 'AttachmentPreview',
    );
    AppLogger.debug(
      '📋 Item isUploaded: ${item.isUploaded}',
      tag: 'AttachmentPreview',
    );
    AppLogger.debug(
      '🔗 Item uploadedUrl: ${item.uploadedUrl}',
      tag: 'AttachmentPreview',
    );

    if (item.uploadedUrl == null) {
      AppLogger.error(
        '⚠️ Cannot view image - uploadedUrl is null',
        tag: 'AttachmentPreview',
      );
      return;
    }

    if (UploadConfig.isStubOrPlaceholderUrl(item.uploadedUrl!)) {
      AppLogger.warning(
        '⚠️ Refusing to open stub/placeholder URL',
        tag: 'AttachmentPreview',
      );
      return;
    }

    AppLogger.info(
      '✅ Opening image dialog for URL: ${item.uploadedUrl}',
      tag: 'AttachmentPreview',
    );

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  item.uploadedUrl!,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.white54,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(AttachmentItem item) {
    if (item.isUploaded && item.uploadedUrl != null) {
      // Defense in depth — never paint Phase-1 stub URLs as real images.
      if (UploadConfig.isStubOrPlaceholderUrl(item.uploadedUrl!)) {
        return Builder(
          builder: (context) => _buildStubPreview(Theme.of(context)),
        );
      }
      return Image.network(
        item.uploadedUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
      );
    } else if (item.pendingAttachment != null) {
      // For pending attachments
      if (kIsWeb && item.pendingAttachment!.previewUrl != null) {
        // Web: Use blob URL
        return Image.network(
          item.pendingAttachment!.previewUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Center(child: Icon(Icons.image, color: Colors.grey)),
        );
      } else if (!kIsWeb && item.pendingAttachment!.filePath != null) {
        // Mobile/Desktop: Use file path
        return Image.file(
          File(item.pendingAttachment!.filePath!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Center(child: Icon(Icons.image, color: Colors.grey)),
        );
      }
    }

    return const Center(child: Icon(Icons.image, color: Colors.grey));
  }

  Widget _buildFileIcon(ThemeData theme, AttachmentItem item) {
    final extension = _getExtension(item);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFileIconData(extension),
            size: 32,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 4),
          Text(extension.toUpperCase(), style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }

  bool _isImage(AttachmentItem item) {
    if (item.isUploaded && item.uploadedUrl != null) {
      return UploadConfig.looksLikeImageUrl(item.uploadedUrl!);
    }
    if (item.pendingAttachment != null) {
      final ext = item.pendingAttachment!.extension.toLowerCase();
      if (UploadConfig.isImageExtension(ext)) return true;
      // Pending web blobs / extension-less picks in journal are usually images.
      if (ext.isEmpty) return true;
    }
    return false;
  }

  String _getExtension(AttachmentItem item) {
    if (item.isUploaded && item.uploadedUrl != null) {
      final ext = UploadConfig.extensionFromUrl(item.uploadedUrl!);
      if (ext.isNotEmpty) return ext;
      return 'file';
    } else if (item.pendingAttachment != null) {
      return item.pendingAttachment!.extension;
    }
    return '';
  }

  IconData _getFileIconData(String extension) {
    if (UploadConfig.isDocumentExtension(extension)) {
      return Icons.description;
    } else if (UploadConfig.isVideoExtension(extension)) {
      return Icons.video_file;
    }
    return Icons.insert_drive_file;
  }
}

