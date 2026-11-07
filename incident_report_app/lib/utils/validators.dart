import '../models/user_role.dart';

/// Each returns an error message, or null if the value is valid.
class Validators {
  Validators._();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 2) {
      return 'Name is too short';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!_emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Like [email], but the address must also use the role's ALU domain.
  static String? emailForRole(String? value, UserRole role) {
    final basicError = email(value);
    if (basicError != null) return basicError;

    if (!value!.trim().toLowerCase().endsWith('@${role.emailDomain}')) {
      return '${role.label} accounts must use an @${role.emailDomain} email';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}
