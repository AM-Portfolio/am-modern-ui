import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/pending_attachment.dart';
import 'attachment_picker_widget.dart' show AttachmentType;
import 'mobile/attachment_picker_mobile.dart' show AttachmentPickerMobile;
import 'web/attachment_picker_web.dart'
    if (dart.library.io) 'web/attachment_picker_web_stub.dart'
    show AttachmentPickerWeb;

export 'attachment_picker_widget.dart' show AttachmentType;

/// Platform-aware attachment picker that automatically uses the appropriate implementation
///
/// - Web: Drag-and-drop support + file picker
/// - Mobile: Gallery picker + file picker
///
/// Usage:
/// ```dart
/// // Auto upload (default)
/// AttachmentPicker(
///   onAttachmentsChanged: (urls) => print('Uploaded: $urls'),
///   featureName: 'journal',
/// )
///
/// // Manual upload control
/// AttachmentPicker(
///   autoUpload: false,
///   onAttachmentsChanged: (urls) => print('Uploaded: $urls'),
///   onPendingAttachmentsChanged: (pending) => print('Pending: ${pending.length}'),
///   featureName: 'journal',
/// )
/// // Then call uploadPendingFiles() when ready
/// ```
class AttachmentPicker extends StatelessWidget {
  const AttachmentPicker({
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

  /// If true, files are uploaded immediately after selection
  /// If false, caller must explicitly trigger upload by calling uploadPendingFiles()
  final bool autoUpload;

  /// If true, shows attachments in read-only mode (no add/remove, clickable to view)
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return AttachmentPickerWeb(
        initialUrls: initialUrls,
        onAttachmentsChanged: onAttachmentsChanged,
        onPendingAttachmentsChanged: onPendingAttachmentsChanged,
        featureName: featureName,
        maxAttachments: maxAttachments,
        allowedType: allowedType,
        showPreview: showPreview,
        label: label,
        userId: userId,
        autoUpload: autoUpload,
        readOnly: readOnly,
      );
    } else {
      return AttachmentPickerMobile(
        initialUrls: initialUrls,
        onAttachmentsChanged: onAttachmentsChanged,
        onPendingAttachmentsChanged: onPendingAttachmentsChanged,
        featureName: featureName,
        maxAttachments: maxAttachments,
        allowedType: allowedType,
        showPreview: showPreview,
        label: label,
        userId: userId,
        autoUpload: autoUpload,
        readOnly: readOnly,
      );
    }
  }
}
