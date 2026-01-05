import 'package:flutter/material.dart';
import '../../../models/pending_attachment.dart';
import '../attachment_picker_widget.dart' show AttachmentType;

/// Stub component for Web Picker to prevent dart:html imports on mobile
class AttachmentPickerWeb extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // This should never be reached as AttachmentPicker checks kIsWeb
    return const SizedBox.shrink();
  }
}
