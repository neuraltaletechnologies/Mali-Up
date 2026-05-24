import 'package:flutter/material.dart';

/// Mali Up — Premium Fintech White Design System
/// Exact token spec: navyPrimary, tealAccent, yellowBrand, etc.
class AppColors {
  // ── Core Brand Tokens ──

  static const Color navyPrimary = Color(0xFF003153);
  static const Color navySecondary = Color(0xFF003153);
  static const Color tealAccent = Color(0xFF1A6E8A);
  static const Color yellowBrand = Color(0xFFFFC107);
  static const Color purpleAccent = Color(0xFF7C3AED); // Reserved — personal mode

  // ── Semantic Aliases ──

  static const Color primary = yellowBrand;
  static const Color primaryLight = Color(0xFFFFF3CD);
  static const Color primaryDark = Color(0xFFE5AC00);

  static const Color secondary = navyPrimary;
  static const Color secondaryLight = navySecondary;

  // ── Surface & Background ──

  static const Color background = Color(0xFFFFFFFF); // cardWhite
  static const Color surface = Color(0xFFF8F9FC); // surfaceLight
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color card = Color(0xFFFFFFFF);

  // ── Typography ──

  static const Color textPrimary = navyPrimary;
  static const Color textSecondary = Color(0xFF374151);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF94A3B8);

  // ── Status Colors ──

  static const Color success = Color(0xFF059669); // successGreen
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color error = Color(0xFFDC2626); // dangerRed
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFD97706); // warningAmber
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color info = tealAccent;
  static const Color infoBg = Color(0xFFE0F2FE);

  // ── Borders & Dividers ──

  static const Color border = Color(0xFFE2E8F0); // borderGray
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color glassBorder = Color(0x33003153);

  // ── Shadows ──

  static const Color shadowCard = Color(0x0A000000);
  static const Color shadowElevated = Color(0x0D000000);
  static const Color shadowModal = Color(0x1A000000);

  // ── Utility ──

  static const Color disabled = Color(0xFFE5E7EB);
  static const Color overlay = Color(0x66003153);
  static const Color inverseText = Color(0xFFFFFFFF);

  // ── Data Visualization ──

  static const Color income = success;
  static const Color expense = error;
  static const Color neutralData = textMuted;
  static const Color chart1 = yellowBrand;
  static const Color chart2 = navyPrimary;
  static const Color chart3 = success;
  static const Color chart4 = tealAccent;
  static const Color chart5 = purpleAccent;
}
