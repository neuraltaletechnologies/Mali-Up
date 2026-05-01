import 'package:flutter/material.dart';

/// Mali Up Brand Colors - Premium Fintech Light Mode Palette
/// Inspired by Revolut/Wise/Monzo with clean white backgrounds,
/// bold financial numbers, and subtle shadows.
class AppColors {
  // ── Primary Brand Colors ──

  /// Vibrant yellow - main brand color for CTAs and highlights
  static const Color primary = Color(0xFFFACC15);

  /// Lighter yellow for backgrounds and subtle accents
  static const Color primaryLight = Color(0xFFFEF08A);

  /// Darker yellow for pressed states and depth
  static const Color primaryDark = Color(0xFFEAB308);

  /// Deep navy - primary text and secondary actions
  static const Color secondary = Color(0xFF1E3A8A);

  /// Lighter navy for hover states and secondary elements
  static const Color secondaryLight = Color(0xFF1D4ED8);

  // ── Surface Colors (Light Mode) ──

  /// Pure white - main background
  static const Color background = Color(0xFFFFFFFF);

  /// Very soft gray for cards, sheets, and elevated surfaces
  static const Color surface = Color(0xFFF8FAFC);

  /// Slightly darker surface for layered depth
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  /// White cards on gray surfaces
  static const Color card = Color(0xFFFFFFFF);

  // ── Typography Colors ──

  /// Primary text - deep navy for maximum contrast on white
  static const Color textPrimary = Color(0xFF1E3A8A);

  /// Secondary text - lighter navy for descriptions and labels
  static const Color textSecondary = Color(0xFF334E99);

  /// Muted text - for hints, placeholders, and tertiary info
  static const Color textMuted = Color(0xFF64748B);

  /// Disabled text
  static const Color textDisabled = Color(0xFF94A3B8);

  // ── Accent / Status Colors ──

  /// Success - green for positive financial indicators
  static const Color success = Color(0xFF10B981);

  /// Success background tint
  static const Color successBg = Color(0xFFD1FAE5);

  /// Error - red for negative balances or alerts
  static const Color error = Color(0xFFEF4444);

  /// Error background tint
  static const Color errorBg = Color(0xFFFEE2E2);

  /// Warning - amber for caution states
  static const Color warning = Color(0xFFF59E0B);

  /// Warning background tint
  static const Color warningBg = Color(0xFFFEF3C7);

  /// Info - blue for informational elements
  static const Color info = Color(0xFF3B82F6);

  /// Info background tint
  static const Color infoBg = Color(0xFFDBEAFE);

  // ── Border & Divider Colors ──

  /// Subtle border color for cards and inputs
  static const Color border = Color(0xFFE2E8F0);

  /// Lighter border for dividers
  static const Color borderLight = Color(0xFFF1F5F9);

  /// Glass-style border for overlays
  static const Color glassBorder = Color(0x335B6FA8);

  // ── Shadow Colors ──

  /// Ultra-subtle shadow for cards (light mode)
  static const Color shadowCard = Color(0x0A000000);

  /// Subtle shadow for elevated elements
  static const Color shadowElevated = Color(0x0D000000);

  /// Soft shadow for modals and dialogs
  static const Color shadowModal = Color(0x1A000000);

  // ── Additional Utility Colors ──

  /// Inactive/disabled state background
  static const Color disabled = Color(0xFFE5E7EB);

  /// Overlay/scrim for modals and bottom sheets
  static const Color overlay = Color(0x661E3A8A);

  /// Inverse text color (white on dark backgrounds)
  static const Color inverseText = Color(0xFFFFFFFF);

  // ── Financial Data Visualization Colors ──

  /// Income/positive trend color
  static const Color income = Color(0xFF10B981);

  /// Expense/negative trend color
  static const Color expense = Color(0xFFEF4444);

  /// Neutral financial data color
  static const Color neutralData = Color(0xFF64748B);

  /// Chart color 1 - primary yellow
  static const Color chart1 = Color(0xFFFACC15);

  /// Chart color 2 - navy
  static const Color chart2 = Color(0xFF1E3A8A);

  /// Chart color 3 - green
  static const Color chart3 = Color(0xFF10B981);

  /// Chart color 4 - blue
  static const Color chart4 = Color(0xFF3B82F6);

  /// Chart color 5 - purple
  static const Color chart5 = Color(0xFF8B5CF6);
}