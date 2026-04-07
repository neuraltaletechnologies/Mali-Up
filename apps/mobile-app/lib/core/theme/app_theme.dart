import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.manropeTextTheme(
      const TextTheme(
        displayLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, height: 1.1),
        displayMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, height: 1.15),
        headlineLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, height: 1.2),
        headlineMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, height: 1.2),
        titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: AppColors.textPrimary, height: 1.5),
        bodyMedium: TextStyle(color: AppColors.textSecondary, height: 1.45),
      ),
    );

    final appTextTheme = baseTextTheme.copyWith(
      displayLarge: GoogleFonts.sora(textStyle: baseTextTheme.displayLarge),
      displayMedium: GoogleFonts.sora(textStyle: baseTextTheme.displayMedium),
      headlineLarge: GoogleFonts.sora(textStyle: baseTextTheme.headlineLarge),
      headlineMedium: GoogleFonts.sora(textStyle: baseTextTheme.headlineMedium),
      titleLarge: GoogleFonts.sora(textStyle: baseTextTheme.titleLarge),
      titleMedium: GoogleFonts.sora(textStyle: baseTextTheme.titleMedium),
      labelLarge: GoogleFonts.sora(textStyle: baseTextTheme.labelLarge),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.secondary,
        onSecondary: AppColors.background,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: appTextTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.sora(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1.5),
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primary, width: 3),
        ),
        labelStyle: GoogleFonts.sora(fontWeight: FontWeight.w700, fontSize: 15),
      ),

      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.sora(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        disabledColor: AppColors.border,
        selectedColor: AppColors.primary,
        secondarySelectedColor: AppColors.secondary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.border),
        ),
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: 0.3),
        selectionHandleColor: AppColors.primary,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: AppColors.surface,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),

      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.secondary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.secondary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}

