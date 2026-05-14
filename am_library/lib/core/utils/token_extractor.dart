import 'dart:convert';

/// Utility class to extract information from JWT tokens
class TokenExtractor {
  /// Extract the userId (sub) from a JWT token
  static String extractUserId(String token) {
    try {
      // Remove 'Bearer ' if present
      final jwt = token.startsWith('Bearer ') ? token.substring(7) : token;
      
      final parts = jwt.split('.');
      if (parts.length != 3) return '';
      
      final payload = parts[1];
      // Padding check
      String normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> data = json.decode(decoded);
      
      return data['sub'] ?? data['user_id'] ?? data['id'] ?? '';
    } catch (e) {
      return '';
    }
  }
}
