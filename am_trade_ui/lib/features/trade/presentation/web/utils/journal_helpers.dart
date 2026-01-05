import 'dart:convert';

/// Helper utilities for journal entry processing
class JournalHelpers {
  /// Extracts plain text from HTML or Quill delta JSON content
  static String extractPlainText(String? content) {
    if (content == null || content.isEmpty) return '';

    // Try to parse as Quill delta JSON
    try {
      if (content.trim().startsWith('[') || content.trim().startsWith('{')) {
        // It's JSON - could be Quill delta format
        final decoded = json.decode(content);
        if (decoded is List) {
          // Quill delta format: [{"insert":"text\n"}]
          final buffer = StringBuffer();
          for (final op in decoded) {
            if (op is Map && op['insert'] != null) {
              buffer.write(op['insert'].toString());
            }
          }
          return buffer.toString().trim();
        } else if (decoded is Map && decoded['ops'] != null) {
          // Alternative Quill format: {"ops":[{"insert":"text\n"}]}
          final ops = decoded['ops'] as List;
          final buffer = StringBuffer();
          for (final op in ops) {
            if (op is Map && op['insert'] != null) {
              buffer.write(op['insert'].toString());
            }
          }
          return buffer.toString().trim();
        }
      }
    } catch (e) {
      // Not valid JSON, continue with HTML parsing
    }

    // Remove HTML tags
    var text = content.replaceAll(RegExp('<[^>]*>'), '');

    // Decode common HTML entities
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    // Trim and normalize whitespace
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Limits text to a specified number of words
  static String limitToWords(String text, int wordLimit) {
    if (text.isEmpty) return '';

    final words = text.split(RegExp(r'\s+'));
    if (words.length <= wordLimit) return text;

    return '${words.take(wordLimit).join(' ')}...';
  }
}
