import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:am_common/core/config/upload_config.dart';
import 'package:am_common/features/attachment/attachment_providers.dart';
import 'package:am_common/features/attachment/internal/services/file_upload_service.dart';

enum AttachmentType { image, document, video, any }

/// Generic attachment picker widget for uploading files
///
/// Can be used across all features: journal, portfolio, documents, etc.
class AttachmentPickerWidget extends ConsumerStatefulWidget {
  // Optional: for metadata

  const AttachmentPickerWidget({
    required this.attachmentUrls,
    required this.onAttachmentsChanged,
    required this.featureName,
    super.key,
    this.maxAttachments = 5,
    this.allowedType = AttachmentType.image,
    this.showPreview = true,
    this.label,
    this.userId,
  });
  final List<String> attachmentUrls;
  final Function(List<String>) onAttachmentsChanged;
  final String featureName; // For folder organization
  final int maxAttachments;
  final AttachmentType allowedType;
  final bool showPreview;
  final String? label;
  final String? userId;

  @override
  ConsumerState<AttachmentPickerWidget> createState() =>
      _AttachmentPickerWidgetState();
}

class _AttachmentPickerWidgetState
    extends ConsumerState<AttachmentPickerWidget> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAddMore = widget.attachmentUrls.length < widget.maxAttachments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with count
        Row(
          children: [
            if (widget.label != null)
              Text(
                widget.label!,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text(
                'Attachments',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(width: 8),
            Text(
              '(${widget.attachmentUrls.length}/${widget.maxAttachments})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Preview Grid
        if (widget.showPreview && widget.attachmentUrls.isNotEmpty) ...[
          _buildPreviewGrid(),
          const SizedBox(height: 12),
        ],

        // Upload Button
        if (canAddMore)
          _buildUploadButton()
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Maximum ${widget.maxAttachments} attachments reached',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),

        // Progress Indicator
        if (_isUploading) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(value: _uploadProgress),
          const SizedBox(height: 4),
          Text(
            'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewGrid() => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: List.generate(
      widget.attachmentUrls.length,
      (index) => _buildThumbnail(widget.attachmentUrls[index], index),
    ),
  );

  Widget _buildThumbnail(String url, int index) {
    final isImage = _isImageUrl(url);
    final theme = Theme.of(context);

    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isImage
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getFileIcon(url),
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getFileExtension(url).toUpperCase(),
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.white),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              onPressed: () => _removeAttachment(index),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton() => OutlinedButton.icon(
    onPressed: _isUploading ? null : _pickAndUploadFile,
    icon: Icon(_getPickerIcon()),
    label: Text(_getPickerLabel()),
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );

  Future<void> _pickAndUploadFile() async {
    try {
      String? filePath;

      switch (widget.allowedType) {
        case AttachmentType.image:
          filePath = await _pickImage();
          break;
        case AttachmentType.document:
          filePath = await _pickDocument();
          break;
        case AttachmentType.video:
          filePath = await _pickVideo();
          break;
        case AttachmentType.any:
          filePath = await _pickAnyFile();
          break;
      }

      if (filePath == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      final uploadService = await ref.read(fileUploadServiceProvider.future);
      final folder = UploadConfig.getFolderForFeature(widget.featureName);

      final url = await uploadService.uploadFile(
        filePath,
        folder: '$folder/${DateTime.now().year}',
        metadata: {
          'feature': widget.featureName,
          'type': widget.allowedType.toString(),
          'uploadedAt': DateTime.now().toIso8601String(),
          if (widget.userId != null) 'userId': widget.userId,
        },
      );

      if (mounted) {
        setState(() {
          final updatedUrls = <String>[...widget.attachmentUrls, url];
          widget.onAttachmentsChanged(updatedUrls);
          _uploadProgress = 1.0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ File uploaded successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on FileUploadException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Upload failed: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<String?> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: UploadConfig.imageMaxWidth.toDouble(),
      maxHeight: UploadConfig.imageMaxHeight.toDouble(),
      imageQuality: UploadConfig.imageQuality,
    );
    return image?.path;
  }

  Future<String?> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: UploadConfig.allowedDocumentTypes,
    );
    return result?.files.single.path;
  }

  Future<String?> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    return video?.path;
  }

  Future<String?> _pickAnyFile() async {
    final result = await FilePicker.platform.pickFiles();
    return result?.files.single.path;
  }

  Future<void> _removeAttachment(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Attachment'),
        content: const Text('Delete this file permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final uploadService = await ref.read(fileUploadServiceProvider.future);
      await uploadService.deleteFile(widget.attachmentUrls[index]);

      if (mounted) {
        setState(() {
          final updatedUrls = [...widget.attachmentUrls];
          updatedUrls.removeAt(index);
          widget.onAttachmentsChanged(updatedUrls);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ File deleted successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ Failed to delete file from server'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  IconData _getPickerIcon() {
    switch (widget.allowedType) {
      case AttachmentType.image:
        return Icons.add_photo_alternate_outlined;
      case AttachmentType.document:
        return Icons.attach_file;
      case AttachmentType.video:
        return Icons.video_library_outlined;
      case AttachmentType.any:
        return Icons.upload_file;
    }
  }

  String _getPickerLabel() {
    switch (widget.allowedType) {
      case AttachmentType.image:
        return 'Add Image';
      case AttachmentType.document:
        return 'Add Document';
      case AttachmentType.video:
        return 'Add Video';
      case AttachmentType.any:
        return 'Add File';
    }
  }

  IconData _getFileIcon(String url) {
    final ext = _getFileExtension(url).toLowerCase();
    if (UploadConfig.isDocumentExtension(ext)) {
      return Icons.description;
    } else if (UploadConfig.isVideoExtension(ext)) {
      return Icons.video_file;
    }
    return Icons.insert_drive_file;
  }

  String _getFileExtension(String url) => url.split('.').last.split('?').first;

  bool _isImageUrl(String url) {
    final ext = _getFileExtension(url).toLowerCase();
    return UploadConfig.isImageExtension(ext);
  }
}
