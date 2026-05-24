import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import '../../core/localization/translation_manager.dart';

class LanguageSwitcherWidget extends ConsumerWidget {
  const LanguageSwitcherWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            locale.languageCode == 'sw' ? 'Lugha' : 'Language',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          DropdownButton<String>(
            value: locale.languageCode,
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'sw', child: Text('Kiswahili')),
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(localeProvider.notifier).setLocale(Locale(value));
              }
            },
          ),
        ],
      ),
    );
  }
}
