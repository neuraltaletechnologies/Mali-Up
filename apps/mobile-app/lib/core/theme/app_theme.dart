import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Mali Up — Premium Fintech White Theme
/// Typography: DM Sans (body/UI), DM Serif Display (hero amounts via AmountDisplay widget),
/// JetBrains Mono (monetary values via AmountDisplay widget).
class AppTheme {
  // ── Spacing / Layout ──
  static const double headerTopPadding = 16.0;
  static const double pageHorizontalPadding = 20.0;
  static const double pageVerticalPadding = 32.0;

  // ── Shadow Definitions ──

  static List<BoxShadow> get cardShadow => [
        const BoxShadow(color: AppColors.shadowCard, blurRadius: 8, offset: Offset(0, 2)),
        const BoxShadow(color: AppColors.shadowCard, blurRadius: 4, offset: Offset(0, 1)),
      ];

  static List<BoxShadow> get elevatedShadow => [
        const BoxShadow(color: AppColors.shadowElevated, blurRadius: 16, offset: Offset(0, 4)),
        const BoxShadow(color: AppColors.shadowCard, blurRadius: 8, offset: Offset(0, 2)),
      ];

  static List<BoxShadow> get modalShadow => [
        const BoxShadow(color: AppColors.shadowModal, blurRadius: 24, offset: Offset(0, 8)),
        const BoxShadow(color: AppColors.shadowElevated, blurRadius: 12, offset: Offset(0, 4)),
      ];

  static ThemeData get lightTheme {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);

    // Base DM Sans text theme with brand colors applied
    final baseTextTheme = GoogleFonts.dmSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    final appTextTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 32, height: 1.1, letterSpacing: -0.5,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 28, height: 1.15, letterSpacing: -0.3,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 24, height: 1.2,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 22, height: 1.2,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 20, height: 1.25,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 18, height: 1.3,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 17, height: 1.3,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15, height: 1.4,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13, height: 1.4,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: AppColors.textPrimary, fontSize: 16, height: 1.5, fontWeight: FontWeight.w400,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary, fontSize: 14, height: 1.5, fontWeight: FontWeight.w400,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: AppColors.textMuted, fontSize: 12, height: 1.5, fontWeight: FontWeight.w400,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3, height: 1.2,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.2, height: 1.3,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.4,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.surface,
        tertiary: AppColors.tealAccent,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.secondary,
        onSecondary: AppColors.background,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
        shadow: AppColors.shadowCard,
      ),

      textTheme: appTextTheme,
      primaryTextTheme: appTextTheme.apply(
        bodyColor: AppColors.inverseText,
        displayColor: AppColors.inverseText,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.dmSans(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
        actionsIconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
      ),

      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: AppColors.shadowCard,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.secondary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: AppColors.border, width: 1.5),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.secondary,
        elevation: 4,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        labelStyle: GoogleFonts.dmSans(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 14),
        hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        errorStyle: GoogleFonts.dmSans(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w400),
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(borderSide: BorderSide(color: AppColors.primary, width: 3)),
        dividerColor: AppColors.border,
        labelPadding: EdgeInsets.symmetric(horizontal: 8),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary);
          }
          return GoogleFonts.dmSans(fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.textMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textMuted,
            size: 24,
          );
        }),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        elevation: 0,
        shadowColor: AppColors.shadowModal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
        contentTextStyle: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w400),
        actionsPadding: const EdgeInsets.all(16),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        disabledColor: AppColors.disabled,
        selectedColor: AppColors.primary,
        secondarySelectedColor: AppColors.primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
        labelStyle: GoogleFonts.dmSans(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13),
        secondaryLabelStyle: GoogleFonts.dmSans(color: AppColors.secondary, fontWeight: FontWeight.w600),
        brightness: Brightness.light,
      ),

      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1, thickness: 1),

      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
      primaryIconTheme: const IconThemeData(color: AppColors.secondary, size: 24),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: 0.3),
        selectionHandleColor: AppColors.primary,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: AppColors.surface,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.border;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.secondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(width: 1.5, color: AppColors.border),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent;
        }),
      ),

      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.secondary,
        contentTextStyle: GoogleFonts.dmSans(color: AppColors.inverseText, fontSize: 14, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(16),
      ),

      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.error,
        textColor: AppColors.inverseText,
        largeSize: 20,
        smallSize: 16,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        titleTextStyle: GoogleFonts.dmSans(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
        subtitleTextStyle: GoogleFonts.dmSans(color: AppColors.textMuted, fontWeight: FontWeight.w400, fontSize: 13),
        iconColor: AppColors.textSecondary,
        selectedColor: AppColors.primary,
      ),

      expansionTileTheme: const ExpansionTileThemeData(
        backgroundColor: AppColors.surface,
        collapsedBackgroundColor: Colors.transparent,
        textColor: AppColors.textPrimary,
        collapsedTextColor: AppColors.textPrimary,
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.dmSans(color: AppColors.inverseText, fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        waitDuration: const Duration(milliseconds: 500),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.background,
        elevation: 8,
        shadowColor: AppColors.shadowModal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          selectedForegroundColor: AppColors.secondary,
          backgroundColor: AppColors.surface,
          selectedBackgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
