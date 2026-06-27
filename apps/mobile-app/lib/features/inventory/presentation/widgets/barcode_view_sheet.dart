import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/mali_components.dart';

/// Bottom sheet that displays a product's 1D (Code 128) barcode for scanning or printing.
class BarcodeViewSheet extends StatelessWidget {
  final String productName;
  final String sku;
  final double price;

  const BarcodeViewSheet({
    super.key,
    required this.productName,
    required this.sku,
    required this.price,
  });

  static Future<void> show(
    BuildContext context, {
    required String productName,
    required String sku,
    required double price,
  }) {
    return showAppSheet<void>(
      context,
      builder: (_) => BarcodeViewSheet(
        productName: productName,
        sku: sku,
        price: price,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              const SizedBox(height: 8),
              Text(
                productName,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'TSh ${price.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: BarcodeWidget(
                  barcode: Barcode.code128(),
                  data: sku,
                  width: double.infinity,
                  height: 90,
                  drawText: false,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.barcode_reader, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    sku,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          letterSpacing: 1.5,
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Code'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: sku));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Barcode copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('Print Label'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tealAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _printLabel(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _printLabel(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Label: $productName | $sku | TSh ${price.toStringAsFixed(0)}\n'
          'Use your label printer app to print this barcode.',
        ),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }
}
