import 'dart:convert';
import 'dart:html' as html;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:am_common/core/config/upload_config.dart';
import 'package:am_common/core/utils/logger.dart';
import 'package:am_common/features/attachment/attachment_providers.dart';
import 'package:am_common/features/attachment/internal/services/file_upload_service.dart';
import 'package:am_common/features/attachment/internal/presentation/models/pending_attachment.dart';
import '../attachment_picker_widget.dart' show AttachmentType;
import '../shared/attachment_preview_grid.dart';

/// Web attachment picker with drag-and-drop support
class AttachmentPickerWeb extends ConsumerStatefulWidget {
  const AttachmentPickerWeb({
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
  ConsumerState<AttachmentPickerWeb> createState() =>
      _AttachmentPickerWebState();
}

class _AttachmentPickerWebState extends ConsumerState<AttachmentPickerWeb> {
  final List<AttachmentItem> _attachments = [];
  final List<PendingAttachment> _pendingUploads = [];
  bool _isUploading = false;
  bool _isDragging = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    AppLogger.debug(
      '🎬 AttachmentPickerWeb initState',
      tag: 'AttachmentPickerWeb',
    );
    AppLogger.debug(
      '📋 Initial URLs count: ${widget.initialUrls.length}',
      tag: 'AttachmentPickerWeb',
    );
    for (var i = 0; i < widget.initialUrls.length; i++) {
      final url = widget.initialUrls[i];
      AppLogger.debug('  [$i] URL: $url', tag: 'AttachmentPickerWeb');
      _attachments.add(AttachmentItem.uploaded(url));
    }
    AppLogger.debug(
      '✅ Created ${_attachments.length} attachment items',
      tag: 'AttachmentPickerWeb',
    );
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

        // Drag and Drop Zone
        if (!widget.readOnly) ...[
          if (canAddMore)
            _buildDropZone(theme)
          else
            _buildMaxReachedMessage(theme),

          // Upload pending button
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

  Widget _buildDropZone(ThemeData theme) => GestureDetector(
    onTap: _isUploading ? null : _pickFile,
    child: MouseRegion(
      onEnter: (_) => setState(() => _isDragging = true),
      onExit: (_) => setState(() => _isDragging = false),
      child: DragTarget<List<html.File>>(
        onWillAcceptWithDetails: (_) =>
            !_isUploading && _attachments.length < widget.maxAttachments,
        onAcceptWithDetails: (details) => _handleDroppedFiles(details.data),
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty || _isDragging;

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isHovering
                  ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                  : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              border: Border.all(
                color: isHovering
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  isHovering ? Icons.upload : Icons.cloud_upload_outlined,
                  size: 40,
                  color: isHovering
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Drag & drop files here',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isHovering
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'or click to browse',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getAllowedTypesText(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
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

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result;

      switch (widget.allowedType) {
        case AttachmentType.image:
          result = await FilePicker.platform.pickFiles(
            type: FileType.image,
            allowMultiple: _attachments.length + 1 < widget.maxAttachments,
          );
          break;
        case AttachmentType.document:
          result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: UploadConfig.allowedDocumentTypes,
            allowMultiple: _attachments.length + 1 < widget.maxAttachments,
          );
          break;
        case AttachmentType.video:
          result = await FilePicker.platform.pickFiles(
            type: FileType.video,
            allowMultiple: _attachments.length + 1 < widget.maxAttachments,
          );
          break;
        case AttachmentType.any:
          result = await FilePicker.platform.pickFiles(
            allowMultiple: _attachments.length + 1 < widget.maxAttachments,
          );
          break;
      }

      if (result == null || result.files.isEmpty) return;

      for (final file in result.files) {
        if (_attachments.length >= widget.maxAttachments) break;

        final pending = PendingAttachment(
          fileName: file.name,
          filePath: null,
          fileBytes: file.bytes,
          previewUrl: file.bytes != null
              ? _createBlobUrl(file.bytes!, file.name)
              : null,
        );

        await _handlePickedFile(pending);
      }
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  void _handleDroppedFiles(List<html.File> files) {
    for (final file in files) {
      if (_attachments.length >= widget.maxAttachments) break;

      final reader = html.FileReader();
      reader.onLoadEnd.listen((e) async {
        final bytes = reader.result! as List<int>;
        final pending = PendingAttachment(
          fileName: file.name,
          filePath: null,
          fileBytes: bytes as dynamic,
          previewUrl: _createBlobUrl(bytes as dynamic, file.name),
        );

        await _handlePickedFile(pending);
      });
      reader.readAsArrayBuffer(file);
    }
  }

  String _createBlobUrl(List<int> bytes, String fileName) {
    final blob = html.Blob([bytes]);
    return html.Url.createObjectUrlFromBlob(blob);
  }

  Future<void> _handlePickedFile(PendingAttachment pending) async {
    AppLogger.debug(
      '📋 Handling picked file: ${pending.fileName}',
      tag: 'WebPicker',
    );
    AppLogger.debug(
      '📄 File size: ${pending.fileBytes?.length ?? 0} bytes',
      tag: 'WebPicker',
    );
    AppLogger.debug('📦 Auto-upload: ${widget.autoUpload}', tag: 'WebPicker');

    if (widget.autoUpload) {
      AppLogger.debug('🚀 Starting auto-upload...', tag: 'WebPicker');
      await _uploadFile(pending);
    } else {
      AppLogger.debug(
        '💾 Adding to pending uploads (manual mode)',
        tag: 'WebPicker',
      );
      setState(() {
        _pendingUploads.add(pending);
        _attachments.add(AttachmentItem.pending(pending));
      });
      widget.onPendingAttachmentsChanged?.call(_pendingUploads);
      AppLogger.debug(
        '✅ Added to pending queue. Total pending: ${_pendingUploads.length}',
        tag: 'WebPicker',
      );
    }
  }

  Future<void> _uploadFile(PendingAttachment pending) async {
    AppLogger.info(
      '\n🚀 ========== Starting Upload ==========',
      tag: 'WebUpload',
    );
    AppLogger.debug('📝 Filename: ${pending.fileName}', tag: 'WebUpload');
    AppLogger.debug('📂 Feature: ${widget.featureName}', tag: 'WebUpload');

    if (pending.fileBytes == null) {
      AppLogger.error('❌ Error: No file data available', tag: 'WebUpload');
      _showError('No file data available');
      return;
    }

    AppLogger.debug(
      '📊 File bytes length: ${pending.fileBytes!.length}',
      tag: 'WebUpload',
    );

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      AppLogger.debug('🔧 Getting upload service...', tag: 'WebUpload');
      final uploadService = await ref.read(fileUploadServiceProvider.future);
      final folder = UploadConfig.getFolderForFeature(widget.featureName);
      AppLogger.debug('📂 Target folder: $folder', tag: 'WebUpload');

      // Convert bytes to base64 for upload
      AppLogger.debug('🔐 Converting to base64...', tag: 'WebUpload');
      final base64Content = base64Encode(pending.fileBytes!);
      AppLogger.debug(
        '✅ Base64 length: ${base64Content.length} chars',
        tag: 'WebUpload',
      );

      AppLogger.debug('🎯 Calling uploadFile...', tag: 'WebUpload');
      // Create a temporary file path for the upload service
      // Note: This is a workaround for web - ideally the service should accept bytes directly
      final url = await uploadService.uploadFile(
        pending.fileName, // Using fileName as path placeholder
        folder: '$folder/${DateTime.now().year}',
        metadata: {
          'feature': widget.featureName,
          'type': widget.allowedType.toString(),
          'uploadedAt': DateTime.now().toIso8601String(),
          'fileContent': base64Content, // Pass bytes via metadata
          if (widget.userId != null) 'userId': widget.userId,
        },
      );

      AppLogger.info('✅ Upload successful!', tag: 'WebUpload');
      AppLogger.debug('🔗 URL: $url', tag: 'WebUpload');

      if (mounted) {
        setState(() {
          _attachments.add(AttachmentItem.uploaded(url));
          _uploadProgress = 1.0;
        });

        _notifyUrlsChanged();
        _showSuccess('File uploaded successfully');
        AppLogger.debug('🎉 UI updated, attachment added', tag: 'WebUpload');
      }
    } on FileUploadException catch (e) {
      AppLogger.error('❌ FileUploadException: ${e.message}', tag: 'WebUpload');
      _showError(e.message);
    } catch (e) {
      AppLogger.error('❌ Unexpected error: $e', tag: 'WebUpload');
      AppLogger.debug('🔍 Error type: ${e.runtimeType}', tag: 'WebUpload');
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
        AppLogger.info(
          '🏁 ========== Upload Complete ==========\n',
          tag: 'WebUpload',
        );
      }
    }
  }

  /// Public method to upload all pending files
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
        if (pending.fileBytes == null) continue;

        final base64Content = base64Encode(pending.fileBytes!);

        final url = await uploadService.uploadFile(
          pending.fileName,
          folder: '$folder/${DateTime.now().year}',
          metadata: {
            'feature': widget.featureName,
            'type': widget.allowedType.toString(),
            'uploadedAt': DateTime.now().toIso8601String(),
            'fileContent': base64Content,
            if (widget.userId != null) 'userId': widget.userId,
          },
        );

        if (mounted) {
          setState(() {
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

        // Clean up blob URL
        if (item.pendingAttachment!.previewUrl != null) {
          html.Url.revokeObjectUrl(item.pendingAttachment!.previewUrl!);
        }
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

  String _getAllowedTypesText() {
    switch (widget.allowedType) {
      case AttachmentType.image:
        return 'Supported: JPG, PNG, GIF, WebP';
      case AttachmentType.document:
        return 'Supported: PDF, DOC, DOCX, XLS, XLSX';
      case AttachmentType.video:
        return 'Supported: MP4, AVI, MOV, WebM';
      case AttachmentType.any:
        return 'All file types supported';
    }
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
}
