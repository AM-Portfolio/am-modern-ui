/// Utility class for form field validation
class Validators {
  /// Validates an email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // Simple regex for email validation
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  /// Validates a password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  /// Validates a name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
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

  /// Validates a phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone might be optional
    }

    // Remove any non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length < 10) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  /// Check if email is valid
  static bool isValidEmail(String email) => RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  ).hasMatch(email);

  /// Check if phone is valid (with country code)
  static bool isValidPhone(String phone) {
    // Remove all non-digit characters except +
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d+]'), '');
    // Should start with + and have at least 10 digits after country code
    return RegExp(r'^\+\d{10,15}$').hasMatch(digitsOnly);
  }

  /// Check if string has uppercase letter
  static bool hasUpperCase(String value) => RegExp('[A-Z]').hasMatch(value);

  /// Check if string has lowercase letter
  static bool hasLowerCase(String value) => RegExp('[a-z]').hasMatch(value);

  /// Check if string has digit
  static bool hasDigit(String value) => RegExp(r'\d').hasMatch(value);
}
