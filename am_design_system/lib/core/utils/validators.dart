/// Utility class for form field validation
class Validators {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9](?:[a-zA-Z0-9._%+-]*[a-zA-Z0-9])?@[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?(?:\.[a-zA-Z]{2,})+$',
  );

  /// E.164-friendly: optional +, 10–15 digits, first digit of national number non-zero.
  static final RegExp _phoneRegex = RegExp(r'^\+?[1-9]\d{9,14}$');

  /// Validates an email address
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final email = value.trim();
    if (email.contains(' ') || email.contains('..')) {
      return 'Enter a valid email address';
    }
    if (!_emailRegex.hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates a password (aligned with Keycloak realm policy)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!hasUpperCase(value) || !hasLowerCase(value) || !hasDigit(value)) {
      return 'Use upper, lower, and a digit';
    }
    return null;
  }

  /// Validates a name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Validates that a field is not empty
  static String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates that a password confirmation matches the password
  static String? validatePasswordMatch(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates a phone number (optional when empty)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (!isValidPhone(value.trim())) {
      return 'Enter a valid phone with country code (e.g. +9198XXXXXXXX)';
    }
    return null;
  }

  /// Check if email is valid
  static bool isValidEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.contains(' ') || trimmed.contains('..')) return false;
    return _emailRegex.hasMatch(trimmed);
  }

  /// Check if phone is valid (optional +, 10–15 digits)
  static bool isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    return _phoneRegex.hasMatch(cleaned);
  }

  static bool hasUpperCase(String value) => RegExp(r'[A-Z]').hasMatch(value);

  static bool hasLowerCase(String value) => RegExp(r'[a-z]').hasMatch(value);

  static bool hasDigit(String value) => RegExp(r'\d').hasMatch(value);
}
