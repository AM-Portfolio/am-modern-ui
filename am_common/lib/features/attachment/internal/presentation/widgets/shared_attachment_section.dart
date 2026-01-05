import 'package:flutter/material.dart';

import 'attachment_picker/attachment_picker.dart';

/// Unified attachment component for all features (Journal, AddTrade, etc.)
///
/// This is the single source of truth for attachment handling across the app.
/// Features wrap this component with feature-specific defaults via wrapper components.
///
/// Usage:
/// ```dart
/// SharedAttachmentSection(
///   imageUrls: attachments,
///   onAttachmentsChanged: (urls) => setState(() => attachments = urls),
///   featureName: 'journal',
///   userId: userId,
///   isEditMode: true,
///   label: 'Evidence',
///   maxAttachments: 10,
/// )
/// ```
///
/// Required parameters:
/// - [imageUrls]: Current list of attachment URLs
/// - [onAttachmentsChanged]: Callback when attachments are added/removed
/// - [featureName]: Feature identifier (e.g., 'journal', 'trade', 'documents')
/// - [userId]: User identifier for cloud storage organization
/// - [isEditMode]: Whether attachments can be added/removed
///
/// Optional parameters:
/// - [label]: Display label (default: 'Attachments')
/// - [maxAttachments]: Maximum number of attachments (default: unlimited)
/// - [allowedType]: Restrict file types (default: all types allowed)
/// - [showPreview]: Show attachment previews (default: true)
/// - [readOnly]: Prevent user interaction (default: false)
class SharedAttachmentSection extends StatelessWidget {
  const SharedAttachmentSection({
    required this.imageUrls,
    required this.onAttachmentsChanged,
    required this.featureName,
    required this.userId,
    required this.isEditMode,
    super.key,
    this.label,
    this.maxAttachments,
    this.allowedType,
    this.showPreview = true,
    this.readOnly = false,
  });

  final List<String> imageUrls;
  final ValueChanged<List<String>> onAttachmentsChanged;
  final String featureName;
  final String userId;
  final bool isEditMode;
  final String? label;
  final int? maxAttachments;
  final String? allowedType;
  final bool showPreview;
  final bool readOnly;

  @override
  Widget build(BuildContext context) => AttachmentPicker(
    initialUrls: imageUrls,
    onAttachmentsChanged: onAttachmentsChanged,
    featureName: featureName,
    userId: userId,
    readOnly: readOnly || !isEditMode,
  );
}
