import 'package:flutter/material.dart';

/// Modern, premium color scheme for onboarding experience
/// Designed for African market - clean and accessible
class OnboardingColors {
  // Primary brand colors (white, black, yellow)
  static const Color primaryDeep = Color(0xFF111111); // Black
  static const Color primaryGradient = Color(0xFFFACC15); // Yellow
  static const Color accentGreen = Color(0xFFEAB308); // Amber-yellow accent
  
  // Secondary palette tuned to brand
  static const Color successGreen = Color(0xFFEAB308);
  static const Color lightGreen = Color(0xFFFFFBEB); // Light yellow background
  static const Color lightBlue = Color(0xFFF5F5F5); // Light neutral background
  
  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFFFFFF); // White
  static const Color textDark = Color(0xFF111111); // Black text
  static const Color textLight = Color(0xFF6B7280); // Medium gray
  static const Color divider = Color(0xFFE5E7EB); // Light divider
  
  // Gradient constants
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryDeep,
      Color(0xFF2A2A2A),
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryGradient,
      accentGreen,
    ],
  );
}
