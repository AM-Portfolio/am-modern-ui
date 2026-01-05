import 'package:flutter/material.dart';

import 'package:am_common/am_common.dart';

/// Wrapper component for trade-specific attachment handling.
///
/// This component wraps [SharedAttachmentSection] with trade-specific defaults.
/// Use this in trade forms for a consistent attachment experience.
///
/// For other features, use [SharedAttachmentSection] directly with custom parameters.
class TradeAttachmentSection extends StatelessWidget {
  const TradeAttachmentSection({
    required this.imageUrls,
    required this.onAttachmentsChanged,
    required this.userId,
    required this.isEditMode,
    super.key,
    this.label,
    this.maxAttachments = 15,
  });

  final List<String> imageUrls;
  final ValueChanged<List<String>> onAttachmentsChanged;
  final String userId;
  final bool isEditMode;
  final String? label;
  final int maxAttachments;

  @override
  Widget build(BuildContext context) => SharedAttachmentSection(
    imageUrls: imageUrls,
    onAttachmentsChanged: onAttachmentsChanged,
    featureName: 'trade',
    userId: userId,
    isEditMode: isEditMode,
    label: label ?? 'Trade Screenshots & Documents',
    maxAttachments: maxAttachments,
  );
}
