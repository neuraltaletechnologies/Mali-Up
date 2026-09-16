import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mali_up/core/services/localization_service.dart';
import 'package:mali_up/i18n/gen/strings.g.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalizationService <-> slang LocaleSettings sync', () {
    test('setLanguage keeps LocaleSettings.currentLocale in sync', () async {
      await LocalizationService.setLanguage(AppLanguage.swahili);
      expect(LocalizationService.languageNotifier.value, AppLanguage.swahili);
      expect(LocaleSettings.currentLocale, AppLocale.sw);

      await LocalizationService.setLanguage(AppLanguage.english);
      expect(LocalizationService.languageNotifier.value, AppLanguage.english);
      expect(LocaleSettings.currentLocale, AppLocale.en);
    });

    test('changeLanguage keeps LocaleSettings.currentLocale in sync', () async {
      await LocalizationService.changeLanguage(AppLanguage.swahili);
      expect(LocaleSettings.currentLocale, AppLocale.sw);
    });

    test('initializeWithPrefs syncs LocaleSettings from stored language', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', 'sw');

      await LocalizationService.initializeWithPrefs(prefs);

      expect(LocalizationService.languageNotifier.value, AppLanguage.swahili);
      expect(LocaleSettings.currentLocale, AppLocale.sw);
    });
  });
}
