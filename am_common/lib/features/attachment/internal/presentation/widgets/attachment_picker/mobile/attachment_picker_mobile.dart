import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:am_common/core/config/upload_config.dart';
import 'package:am_common/features/attachment/attachment_providers.dart';
import 'package:am_common/features/attachment/internal/services/file_upload_service.dart';
import 'package:am_common/features/attachment/internal/presentation/models/pending_attachment.dart';
import '../attachment_picker_widget.dart' show AttachmentType;
import '../shared/attachment_preview_grid.dart';

/// Mobile attachment picker with gallery and file picker support
class AttachmentPickerMobile extends ConsumerStatefulWidget {
  const AttachmentPickerMobile({
    required this.onAttachmentsChanged,
    required this.featureName,
    super.key,
    this.initialUrls = const [],
    this.maxAttachments = 5,
    this.allowedType = AttachmentType.image,
    this.showPreview = true,
    this.label,
    this.userId,
    this.autoUpload = true,
    this.onPendingAttachmentsChanged,
    this.readOnly = false,
  });

  final List<String> initialUrls;
  final Function(List<String> uploadedUrls) onAttachmentsChanged;
  final Function(List<PendingAttachment> pending)? onPendingAttachmentsChanged;
  final String featureName;
  final int maxAttachments;
  final AttachmentType allowedType;
  final bool showPreview;
  final String? label;
  final String? userId;
  final bool autoUpload;
  final bool readOnly;

  @override
  ConsumerState<AttachmentPickerMobile> createState() =>
      _AttachmentPickerMobileState();
}

class _AttachmentPickerMobileState
    extends ConsumerState<AttachmentPickerMobile> {
  final List<AttachmentItem> _attachments = [];
  final List<PendingAttachment> _pendingUploads = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    // Initialize with existing uploaded URLs
    for (final url in widget.initialUrls) {
      _attachments.add(AttachmentItem.uploaded(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAddMore = _attachments.length < widget.maxAttachments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with count
        if (!widget.readOnly || _attachments.isNotEmpty)
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
                widget.readOnly
                    ? '(${_attachments.length})'
                    : '(${_attachments.length}/${widget.maxAttachments})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              if (_pendingUploads.isNotEmpty &&
                  !widget.autoUpload &&
                  !widget.readOnly) ...[
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    '${_pendingUploads.length} pending',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ],
          ),

        const SizedBox(height: 12),

        // Preview Grid
        if (widget.showPreview && _attachments.isNotEmpty) ...[
          AttachmentPreviewGrid(
            attachments: _attachments,
            onRemove: widget.readOnly ? null : _removeAttachment,
            readOnly: widget.readOnly,
          ),
          const SizedBox(height: 12),
        ],

        // Upload Buttons
        if (!widget.readOnly) ...[
          if (canAddMore)
            _buildUploadButtons()
          else
            _buildMaxReachedMessage(theme),

          // Upload pending button (only shown if autoUpload is false)
          if (!widget.autoUpload && _pendingUploads.isNotEmpty) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isUploading ? null : uploadPendingFiles,
              icon: const Icon(Icons.cloud_upload),
              label: Text('Upload ${_pendingUploads.length} file(s)'),
            ),
          ],

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
      ],
    );
  }

  Widget _buildUploadButtons() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      if (widget.allowedType == AttachmentType.image)
        OutlinedButton.icon(
          onPressed: _isUploading ? null : _pickFromGallery,
          icon: const Icon(Icons.photo_library),
          label: const Text('Gallery'),
        ),
      OutlinedButton.icon(
        onPressed: _isUploading ? null : _pickFile,
        icon: Icon(_getPickerIcon()),
        label: Text(_getPickerLabel()),
      ),
    ],
  );

  Widget _buildMaxReachedMessage(ThemeData theme) => Container(
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
  );

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: UploadConfig.imageMaxWidth.toDouble(),
        maxHeight: UploadConfig.imageMaxHeight.toDouble(),
        imageQuality: UploadConfig.imageQuality,
      );

      if (image == null) return;

      final pending = PendingAttachment(
        fileName: image.name,
        filePath: image.path,
        previewUrl: image.path,
      );

      await _handlePickedFile(pending);
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result;

      switch (widget.allowedType) {
        case AttachmentType.image:
          result = await FilePicker.platform.pickFiles(type: FileType.image);
          break;
        case AttachmentType.document:
          result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: UploadConfig.allowedDocumentTypes,
          );
          break;
        case AttachmentType.video:
          result = await FilePicker.platform.pickFiles(type: FileType.video);
          break;
        case AttachmentType.any:
          result = await FilePicker.platform.pickFiles();
          break;
      }

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final pending = PendingAttachment(
        fileName: file.name,
        filePath: file.path,
        previewUrl: file.path,
      );

      await _handlePickedFile(pending);
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  Future<void> _handlePickedFile(PendingAttachment pending) async {
    if (widget.autoUpload) {
      await _uploadFile(pending);
    } else {
      setState(() {
        _pendingUploads.add(pending);
        _attachments.add(AttachmentItem.pending(pending));
      });
      widget.onPendingAttachmentsChanged?.call(_pendingUploads);
    }
  }

  Future<void> _uploadFile(PendingAttachment pending) async {
    if (pending.filePath == null) {
      _showError('No file path available');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final uploadService = await ref.read(fileUploadServiceProvider.future);
      final folder = UploadConfig.getFolderForFeature(widget.featureName);

      final url = await uploadService.uploadFile(
        pending.filePath!,
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
          _attachments.add(AttachmentItem.uploaded(url));
          _uploadProgress = 1.0;
        });

        _notifyUrlsChanged();
        _showSuccess('File uploaded successfully');
      }
    } on FileUploadException catch (e) {
      _showError('Upload failed: ${e.message}');
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  /// Public method to upload all pending files (called by parent)
  Future<void> uploadPendingFiles() async {
    if (_pendingUploads.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final uploadService = await ref.read(fileUploadServiceProvider.future);
      final folder = UploadConfig.getFolderForFeature(widget.featureName);
      final totalFiles = _pendingUploads.length;

      for (var i = 0; i < _pendingUploads.length; i++) {
        final pending = _pendingUploads[i];
        if (pending.filePath == null) continue;

        final url = await uploadService.uploadFile(
          pending.filePath!,
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
            // Replace pending with uploaded
            final index = _attachments.indexWhere(
              (a) => a.pendingAttachment == pending,
            );
            if (index != -1) {
              _attachments[index] = AttachmentItem.uploaded(url);
            }
            _uploadProgress = (i + 1) / totalFiles;
          });
        }
      }

      if (mounted) {
        setState(_pendingUploads.clear);
        widget.onPendingAttachmentsChanged?.call([]);
        _notifyUrlsChanged();
        _showSuccess('All files uploaded successfully');
      }
    } catch (e) {
      _showError('Upload failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _removeAttachment(int index) async {
    final item = _attachments[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Attachment'),
        content: Text(
          item.isUploaded
              ? 'Delete this file permanently?'
              : 'Remove this pending file?',
        ),
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
      if (item.isUploaded && item.uploadedUrl != null) {
        final uploadService = await ref.read(fileUploadServiceProvider.future);
        await uploadService.deleteFile(item.uploadedUrl!);
      } else if (item.pendingAttachment != null) {
        _pendingUploads.remove(item.pendingAttachment);
        widget.onPendingAttachmentsChanged?.call(_pendingUploads);
      }

      if (mounted) {
        setState(() {
          _attachments.removeAt(index);
        });
        _notifyUrlsChanged();
        _showSuccess(
          item.isUploaded
              ? 'File deleted successfully'
              : 'Pending file removed',
        );
      }
    } catch (e) {
      _showError('Failed to delete file');
    }
  }

  void _notifyUrlsChanged() {
    final uploadedUrls = _attachments
        .where((a) => a.isUploaded)
        .map((a) => a.uploadedUrl!)
        .toList();
    widget.onAttachmentsChanged(uploadedUrls);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $message'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
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
        return 'Browse';
      case AttachmentType.document:
        return 'Document';
      case AttachmentType.video:
        return 'Video';
      case AttachmentType.any:
        return 'File';
    }
  }
}
