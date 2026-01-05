import '../../../../../internal/domain/entities/journal_entry.dart';

/// Helper functions for journal form operations
class JournalFormHelpers {
  /// Convert image URLs to JournalAttachment objects
  static List<JournalAttachment> convertImageUrlsToAttachments(List<String> imageUrls) => imageUrls.map((url) {
    final fileName = url.split('/').last.split('?').first;
    return JournalAttachment(
      fileName: fileName,
      fileUrl: url,
      fileType: _getFileTypeFromUrl(url),
      uploadedAt: DateTime.now(),
    );
  }).toList();

  /// Get file MIME type from URL extension
  static String? _getFileTypeFromUrl(String url) {
    final extension = url.split('.').last.split('?').first.toLowerCase();
    const imageTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'svg': 'image/svg+xml',
    };
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
  };
}

