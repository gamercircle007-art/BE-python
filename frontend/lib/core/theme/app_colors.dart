import 'package:flutter/material.dart';

/// Paythan brand colors for auth screens.
class AppColors {
  static const primaryPurple = Color(0xFF7B2FF7);
  static const primaryBlue = Color(0xFF3B82F6);
  static const textDark = Color(0xFF1A1A2E);
  static const textMuted = Color(0xFF888888);
  static const border = Color(0xFFE0E0E0);
  static const inputFill = Color(0xFFF9F9F9);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, primaryBlue],
  );

  static const buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryPurple, primaryBlue],
  );
}