import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'package:riverpod/riverpod.dart';

/// Supported locales for Mali Up
class AppLocales {
  static const Locale swahili = Locale('sw', 'TZ');
  static const Locale english = Locale('en', 'US');
  
  static const List<Locale> supportedLocales = [
    swahili,
    english,
  ];
  
  static const Map<String, Locale> localeMap = {
    'sw': swahili,
    'en': english,
  };
  
  /// Get display name for locale
  static String getDisplayName(Locale locale) {
    if (locale.languageCode == 'sw') return 'Kiswahili';
    return 'English';
  }
}

/// Provider to manage current locale
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

/// Provider for translations
final translationsProvider = Provider<Map<String, dynamic>>((ref) {
  final locale = ref.watch(localeProvider);
  // Load translations based on locale
  // This will be populated by the app initialization
  return {};
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(AppLocales.english) {
    _loadLocale();
  }
  
  Future<void> _loadLocale() async {
    // Load saved locale preference
    // For now, default to English
    final savedLocale = await _getSavedLocale();
    state = savedLocale ?? AppLocales.english;
  }
  
  Future<Locale?> _getSavedLocale() async {
    // TODO: Implement SharedPreferences to save locale
    return null;
  }
  
  Future<void> setLocale(Locale locale) async {
    state = locale;
    // Save preference
    await _saveLocale(locale);
  }
  
  Future<void> _saveLocale(Locale locale) async {
    // TODO: Implement SharedPreferences to save locale
  }
}

/// Localization delegate
class AppLocalizationDelegate extends LocalizationsDelegate<String> {
  @override
  bool isSupported(Locale locale) {
    return AppLocales.supportedLocales
        .any((l) => l.languageCode == locale.languageCode);
  }

  @override
  Future<String> load(Locale locale) async {
    // Load translation files here
    return '';
  }

  @override
  bool shouldReload(AppLocalizationDelegate old) => false;
}

/// Helper class for date formatting
class DateFormatter {
  /// Format date as DD/MM/YYYY (Tanzanian standard)
  static String formatDate(DateTime date) {
    return intl.DateFormat('dd/MM/yyyy').format(date);
  }
  
  /// Format date with month name (Tanzanian)
  static String formatDateWithMonth(DateTime date, Locale locale) {
    if (locale.languageCode == 'sw') {
      return intl.DateFormat('dd MMMM yyyy', 'sw_TZ').format(date);
    }
    return intl.DateFormat('dd MMMM yyyy', 'en_US').format(date);
  }
  
  /// Format time (24-hour format)
  static String formatTime(DateTime time) {
    return intl.DateFormat('HH:mm').format(time);
  }
  
  /// Format as relative date (Today, Yesterday, etc.)
  static String formatRelativeDate(DateTime date, Locale locale) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return locale.languageCode == 'sw' ? 'Leo' : 'Today';
    } else if (dateOnly == yesterday) {
      return locale.languageCode == 'sw' ? 'Jana' : 'Yesterday';
    } else if (dateOnly == tomorrow) {
      return locale.languageCode == 'sw' ? 'Kesho' : 'Tomorrow';
    }
    
    return formatDate(date);
  }
}

/// Helper class for currency formatting
class CurrencyFormatter {
  /// Format currency as TSh (Tanzanian Shilling)
  /// Format: TSh 150,000.00 (with space as thousand separator)
  static String formatCurrency(double amount) {
    final formatter = intl.NumberFormat('#,##0.00', 'sw_TZ');
    return 'TSh ${formatter.format(amount)}';
  }
  
  /// Format currency without symbol
  static String formatAmount(double amount) {
    final formatter = intl.NumberFormat('#,##0.00', 'sw_TZ');
    return formatter.format(amount);
  }
  
  /// Parse currency string to double
  static double? parseCurrency(String value) {
    try {
      return double.parse(value.replaceAll(RegExp(r'[^\d.]'), ''));
    } catch (e) {
      return null;
    }
  }
}

/// Helper class for number formatting
class NumberFormatter {
  /// Format number with thousand separators
  static String formatNumber(int number) {
    final formatter = intl.NumberFormat('#,##0', 'sw_TZ');
    return formatter.format(number);
  }
  
  /// Format percentage
  static String formatPercentage(double percentage) {
    final formatter = intl.NumberFormat('0.00', 'sw_TZ');
    return '${formatter.format(percentage)}%';
  }
}
