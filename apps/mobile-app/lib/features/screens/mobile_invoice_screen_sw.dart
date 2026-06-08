import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localization.dart' hide localeProvider;
import '../../core/localization/translation_manager.dart';

class InvoiceScreenSW extends ConsumerWidget {
  const InvoiceScreenSW({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final manager = TranslationManager();

    return Scaffold(
      appBar: AppBar(
        title: Text(manager.t('finance.invoiceList', locale)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text(manager.t('finance.invoice', locale)),
              subtitle: const Text('INV-001'),
              trailing: Text(
                CurrencyFormatter.formatCurrency(150000.00),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            child: Text(manager.t('common.add', locale)),
          ),
        ],
      ),
    );
  }
}
