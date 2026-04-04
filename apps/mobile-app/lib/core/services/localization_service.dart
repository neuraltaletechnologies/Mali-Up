import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english,
  swahili,
}

extension AppLanguageX on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.swahili:
        return 'sw';
    }
  }

  String get label {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.swahili:
        return 'Kiswahili';
    }
  }

  String get nativeLabel {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.swahili:
        return 'Kiswahili';
    }
  }
}

class LocalizationService {
  static const String _languageKey = 'app_language';
  static const String _languageSelectedKey = 'language_selected';
  static final ValueNotifier<AppLanguage> languageNotifier =
      ValueNotifier<AppLanguage>(AppLanguage.english);

  static Future<void> initialize() async {
    languageNotifier.value = await getLanguage();
  }

  static Future<void> setLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.code);
    await prefs.setBool(_languageSelectedKey, true);
    languageNotifier.value = language;
  }

  static Future<AppLanguage> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'en';
    
    switch (languageCode) {
      case 'sw':
        return AppLanguage.swahili;
      case 'en':
      default:
        return AppLanguage.english;
    }
  }

  static Future<bool> hasLanguageBeenSelected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_languageSelectedKey) ?? false;
  }

  static Future<void> resetLanguageSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_languageKey);
    await prefs.remove(_languageSelectedKey);
    languageNotifier.value = AppLanguage.english;
  }
}
