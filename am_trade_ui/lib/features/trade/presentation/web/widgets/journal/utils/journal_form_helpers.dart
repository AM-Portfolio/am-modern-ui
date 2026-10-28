import '../../../../../internal/domain/entities/journal_entry.dart';

/// Helper functions for journal form operations
class JournalFormHelpers {
  /// Convert image URLs to JournalAttachment objects
  static List<JournalAttachment> convertImageUrlsToAttachments(List<String> imageUrls) => imageUrls.map((url) {
    final path = Uri.tryParse(url)?.path ?? url;
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    final fileName = segments.isNotEmpty ? segments.last : 'attachment';
    return JournalAttachment(
      fileName: fileName.contains('.') ? fileName : '$fileName.jpg',
      fileUrl: url,
      fileType: _getFileTypeFromUrl(url),
      // Omit uploadedAt — ISO-8601 with Z can break Java LocalDateTime on create.
      uploadedAt: null,
    );
  }).toList();

  /// Get file MIME type from URL extension
  static String? _getFileTypeFromUrl(String url) {
    final path = Uri.tryParse(url)?.path ?? url;
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    final last = segments.isNotEmpty ? segments.last : '';
    final dot = last.lastIndexOf('.');
    final extension = (dot > 0 && dot < last.length - 1)
        ? last.substring(dot + 1).toLowerCase()
        : '';
    const imageTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'svg': 'image/svg+xml',
    };
    if (extension.isEmpty || extension.length > 5 || extension.contains('/')) {
      // Cloudinary / CDN paths often omit extensions — treat as image.
      return 'image/jpeg';
    }
    return imageTypes[extension] ?? 'image/$extension';
  }

  /// Build customFields map from phase data
  static Map<String, dynamic> buildCustomFields({
    required String planningBehavior,
    required String? planningMood,
    required String? planningSentiment,
    required String midBehavior,
    required String? midMood,
    required String? midSentiment,
    required String endBehavior,
    required String? endMood,
    required String? endSentiment,
    Map<String, String>? promptAnswers,
    Map<String, String>? fieldAnswers,
    List<String>? promptLabels,
    List<String>? fieldLabels,
  }) => {
    // Planning phase
    if (planningBehavior.trim().isNotEmpty) 'planningBehavior': planningBehavior.trim(),
    if (planningMood != null) 'planningMood': planningMood,
    if (planningSentiment != null) 'planningSentiment': planningSentiment,
    // Mid phase
    if (midBehavior.trim().isNotEmpty) 'midBehavior': midBehavior.trim(),
    if (midMood != null) 'midMood': midMood,
    if (midSentiment != null) 'midSentiment': midSentiment,
    // End phase
    if (endBehavior.trim().isNotEmpty) 'endBehavior': endBehavior.trim(),
    if (endMood != null) 'endMood': endMood,
    if (endSentiment != null) 'endSentiment': endSentiment,
    if (promptLabels != null && promptLabels.isNotEmpty)
      'notePromptLabels': promptLabels,
    if (promptAnswers != null && promptAnswers.isNotEmpty)
      'notePromptAnswers': promptAnswers,
    if (fieldLabels != null && fieldLabels.isNotEmpty)
      'templateFieldLabels': fieldLabels,
    if (fieldAnswers != null && fieldAnswers.isNotEmpty)
      'templateFieldAnswers': fieldAnswers,
  };

  /// Reads a string→string map from customFields (API may decode as Map).
  static Map<String, String> stringMapFromCustom(
    Map<String, dynamic> customFields,
    String key,
  ) {
    final raw = customFields[key];
    if (raw is! Map) return {};
    return {
      for (final e in raw.entries)
        if (e.key != null && '${e.key}'.trim().isNotEmpty)
          '${e.key}': '${e.value ?? ''}',
    };
  }

  static List<String> stringListFromCustom(
    Map<String, dynamic> customFields,
    String key,
  ) {
    final raw = customFields[key];
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if ('$e'.trim().isNotEmpty) '$e'.trim(),
    ];
  }
}

