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

  /// Decode JWT payload — returns null when token is invalid.
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final jwt = token.startsWith('Bearer ') ? token.substring(7) : token;
      final parts = jwt.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Roles from `roles`, `groups`, or Keycloak `realm_access.roles`.
  static List<String> extractRoles(String token) {
    final payload = decodePayload(token);
    if (payload == null) return const [];

    final roles = <String>[];

    void addFromList(dynamic value) {
      if (value is List) {
        for (final item in value) {
          final role = item?.toString().trim();
          if (role != null && role.isNotEmpty) roles.add(role);
        }
      }
    }

    addFromList(payload['roles']);
    if (roles.isEmpty) addFromList(payload['groups']);

    if (roles.isEmpty && payload['realm_access'] is Map) {
      addFromList((payload['realm_access'] as Map)['roles']);
    }

    return roles;
  }

  /// Whether the token grants admin access (Keycloak `admin` or Spring `ROLE_ADMIN`).
  static bool hasAdminRole(String token) {
    return isAdminRole(extractRoles(token));
  }

  static bool isAdminRole(List<String> roles) {
    for (final role in roles) {
      final normalized = role.toLowerCase().replaceAll('-', '_');
      if (normalized == 'admin' || normalized == 'role_admin') {
        return true;
      }
    }
    return false;
  }
}
