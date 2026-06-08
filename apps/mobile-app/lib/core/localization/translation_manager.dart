import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages all translations for the app
class TranslationManager {
  static final TranslationManager _instance = TranslationManager._internal();
  
  Map<String, dynamic> _swahiliTranslations = {};
  Map<String, dynamic> _englishTranslations = {};
  
  factory TranslationManager() {
    return _instance;
  }
  
  TranslationManager._internal();
  
  /// Load all translation files
  Future<void> initialize() async {
    try {
      // Load Kiswahili translations
      final swString = await rootBundle.loadString('assets/locales/sw.json');
      _swahiliTranslations = json.decode(swString);
      
      // Load English translations
      final enString = await rootBundle.loadString('assets/locales/en.json');
      _englishTranslations = json.decode(enString);
    } catch (e) {
      debugPrint('Error loading translations: $e');
    }
  }
  
  /// Get translation by key using dot notation
  /// Example: t('common.home') -> returns 'Nyumbani' in Kiswahili
  String t(String key, Locale locale) {
    final translations = locale.languageCode == 'sw' 
      ? _swahiliTranslations 
      : _englishTranslations;
    
    final keys = key.split('.');
    dynamic value = translations;
    
    for (final k in keys) {
      if (value is Map && value.containsKey(k)) {
        value = value[k];
      } else {
        // Fallback to key itself or empty string
        return key;
      }
    }
    
    return value is String ? value : key;
  }
  
  /// Get translation with parameter substitution
  String tp(String key, Map<String, String> params, Locale locale) {
    String value = t(key, locale);
    
    params.forEach((param, replacement) {
      value = value.replaceAll('{$param}', replacement);
    });
    
    return value;
  }
  
  /// Get entire namespace (e.g., 'common', 'finance')
  Map<String, dynamic> getNamespace(String namespace, Locale locale) {
    final translations = locale.languageCode == 'sw'
      ? _swahiliTranslations
      : _englishTranslations;
    
    return (translations[namespace] as Map<String, dynamic>?) ?? {};
  }
}

/// Translation service provider
final translationManagerProvider = Provider<TranslationManager>((ref) {
  return TranslationManager();
});

/// Locale state provider
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

/// Notifier for managing locale state
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en', 'US')) {
    _loadPreferredLocale();
  }
  
  Future<void> _loadPreferredLocale() async {
    // TODO: Load from SharedPreferences
    // For now, default to English
    state = const Locale('en', 'US');
  }
  
  Future<void> setLocale(Locale locale) async {
    state = locale;
    // TODO: Save to SharedPreferences
  }
  
  void toggleLocale() {
    final newLocale = state.languageCode == 'sw'
      ? const Locale('en', 'US')
      : const Locale('sw', 'TZ');
    setLocale(newLocale);
  }
}

/// Extension for easy translation access in widgets
extension TranslationExt on BuildContext {
  String t(String key) {
    final locale = Localizations.localeOf(this);
    final manager = TranslationManager();
    return manager.t(key, locale);
  }
  
  String tp(String key, Map<String, String> params) {
    final locale = Localizations.localeOf(this);
    final manager = TranslationManager();
    return manager.tp(key, params, locale);
  }
  
  Locale getLocale() => Localizations.localeOf(this);
}

/// Translation helper for accessing translations in widgets
class L10n {
  static String t(BuildContext context, String key) {
    return context.t(key);
  }
  
  static String tp(BuildContext context, String key, Map<String, String> params) {
    return context.tp(key, params);
  }
}

/// Localization delegate for Flutter localizations
class AppLocalizationsDelegate extends LocalizationsDelegate<String> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'sw'].contains(locale.languageCode);
  }

  @override
  Future<String> load(Locale locale) async {
    // Translations loaded via TranslationManager
    return '';
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

/// Supported locales configuration
class AppLocales {
  static const Locale english = Locale('en', 'US');
  static const Locale swahili = Locale('sw', 'TZ');
  
  static const List<Locale> supportedLocales = [
    english,
    swahili,
  ];
  
  static String getDisplayName(Locale locale) {
    return locale.languageCode == 'sw' ? 'Kiswahili' : 'English';
  }
  
  static String getCountryName(Locale locale) {
    return locale.languageCode == 'sw' ? 'Tanzania' : 'USA';
  }
}
