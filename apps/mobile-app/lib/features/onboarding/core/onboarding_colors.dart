import 'package:flutter/material.dart';

/// Modern, premium color scheme for onboarding experience
/// Designed for African market - clean and accessible
class OnboardingColors {
  // Primary gradient colors
  static const Color primaryDeep = Color(0xFF0B5ED7); // Deep Blue
  static const Color primaryGradient = Color(0xFF00A8E8); // Bright Blue
  static const Color accentGreen = Color(0xFF16C47F); // Fresh Green
  
  // Secondary palette
  static const Color successGreen = Color(0xFF10B981); // Standard green
  static const Color lightGreen = Color(0xFFD1FAE5); // Light green background
  static const Color lightBlue = Color(0xFFDEF2FF); // Light blue background
  
  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC); // Very light gray
  static const Color textDark = Color(0xFF1F2937); // Dark gray text
  static const Color textLight = Color(0xFF6B7280); // Medium gray
  static const Color divider = Color(0xFFE5E7EB); // Light divider
  
  // Gradient constants
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryDeep,
      primaryGradient,
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      accentGreen,
      Color(0xFF0EA85D), // Darker green
    ],
  );
}
