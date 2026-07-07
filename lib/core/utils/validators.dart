import 'package:proof/core/constants/app_constants.dart';

class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? handle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Handle is required';
    }
    final handle = value.trim().toLowerCase();
    if (handle.length < AppConstants.handleMinLength) {
      return 'Handle must be at least ${AppConstants.handleMinLength} characters';
    }
    if (handle.length > AppConstants.handleMaxLength) {
      return 'Handle must be at most ${AppConstants.handleMaxLength} characters';
    }
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(handle)) {
      return 'Use lowercase letters, numbers, and underscores only';
    }
    return null;
  }

  static String? displayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Display name is required';
    }
    if (value.trim().length > AppConstants.displayNameMaxLength) {
      return 'Display name is too long';
    }
    return null;
  }
}
