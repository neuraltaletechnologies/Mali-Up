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
        return 'Continue in English';
      case AppLanguage.swahili:
        return 'Endelea kwa Kiswahili';
    }
  }
}

class LocalizationService {
  static const String _languageKey = 'app_language';
  static const String _languageSelectedKey = 'language_selected';
  static final ValueNotifier<AppLanguage> languageNotifier =
      ValueNotifier<AppLanguage>(AppLanguage.english);
  static final ValueNotifier<bool> languageSelectedNotifier =
      ValueNotifier<bool>(false);

  static Future<void> initialize() async {
    languageNotifier.value = await getLanguage();
  }

  static Future<void> initializeWithPrefs(SharedPreferences prefs) async {
    final languageCode = prefs.getString(_languageKey) ?? 'en';
    languageSelectedNotifier.value =
        prefs.getBool(_languageSelectedKey) ?? false;

    switch (languageCode) {
      case 'sw':
        languageNotifier.value = AppLanguage.swahili;
        return;
      case 'en':
      default:
        languageNotifier.value = AppLanguage.english;
        return;
    }
  }

  static bool get isSwahili => languageNotifier.value == AppLanguage.swahili;

  static String tr({required String en, required String sw}) {
    return isSwahili ? sw : en;
  }

  static Future<void> setLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.code);
    await prefs.setBool(_languageSelectedKey, true);
    if (!languageSelectedNotifier.value) {
      languageSelectedNotifier.value = true;
    }

    if (languageNotifier.value != language) {
      languageNotifier.value = language;
    }
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

    if (languageSelectedNotifier.value) {
      languageSelectedNotifier.value = false;
    }

    if (languageNotifier.value != AppLanguage.english) {
      languageNotifier.value = AppLanguage.english;
    }
  }
}
