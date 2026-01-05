import 'package:flutter/material.dart';

import 'package:am_common/am_common.dart';

/// Wrapper component for journal-specific attachment handling.
///
/// This component wraps [SharedAttachmentSection] with journal-specific defaults.
/// Use this in journal forms and pages for a consistent attachment experience.
///
/// For other features, use [SharedAttachmentSection] directly with custom parameters.
class JournalAttachmentSection extends StatelessWidget {
  const JournalAttachmentSection({
    required this.imageUrls,
    required this.onAttachmentsChanged,
    required this.featureName,
    required this.userId,
    required this.isEditMode,
    super.key,
    this.label,
    this.maxAttachments = 10,
  });

  final List<String> imageUrls;
  final ValueChanged<List<String>> onAttachmentsChanged;
  final String featureName;
  final String userId;
  final bool isEditMode;
  final String? label;
  final int maxAttachments;

  @override
  Widget build(BuildContext context) => SharedAttachmentSection(
    imageUrls: imageUrls,
    onAttachmentsChanged: onAttachmentsChanged,
    featureName: featureName,
    userId: userId,
    isEditMode: isEditMode,
    label: label ?? 'Supporting Evidence',
    maxAttachments: maxAttachments,
  );
}
