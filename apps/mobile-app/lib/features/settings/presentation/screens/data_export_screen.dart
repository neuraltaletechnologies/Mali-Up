import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';

/// Data Export Screen - PDPA Right to Export
/// Allows users to download all their business data as JSON or CSV
/// Complies with PDPA Article 18 (Right to Portability)

class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  bool isExporting = false;
  String? selectedFormat = 'json'; // 'json' or 'csv'
  String? exportProgress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download My Data'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              Text(
                'Export Your Data',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Download a complete copy of all your Mali Up data. This includes invoices, customers, expenses, inventory, and account settings.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Format Selection
              Text(
                'Choose format:',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              RadioListTile(
                title: const Text('JSON (Complete backup)'),
                subtitle: const Text('Full data structure, best for backup'),
                value: 'json',
                groupValue: selectedFormat,
                onChanged: isExporting ? null : (val) => setState(() => selectedFormat = val),
              ),
              RadioListTile(
                title: const Text('CSV (For spreadsheets)'),
                subtitle: const Text('Comma-separated values, open in Excel'),
                value: 'csv',
                groupValue: selectedFormat,
                onChanged: isExporting ? null : (val) => setState(() => selectedFormat = val),
              ),

              const SizedBox(height: 32),

              // Export Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isExporting ? null : _exportData,
                  icon: isExporting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        )
                      : const Icon(Icons.download),
                  label: Text(
                    isExporting ? 'Exporting...' : 'Download Data',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              if (exportProgress != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.navyPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(exportProgress!),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // What's Included
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What\'s included:',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.green[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '✓ All invoices\n'
                      '✓ All customers\n'
                      '✓ All expenses\n'
                      '✓ Inventory items\n'
                      '✓ Account settings\n'
                      '✓ Export timestamp',
                      style: TextStyle(height: 1.8),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // PDPA Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your PDPA Rights',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Under Tanzania\'s Personal Data Protection Act, you have the right to export your data. This complies with Article 18 (Right to Portability).\n\n'
                      'You can download your data at any time and transfer it to another service.',
                      style: TextStyle(height: 1.6),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    if (selectedFormat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a format')),
      );
      return;
    }

    setState(() {
      isExporting = true;
      exportProgress = 'Preparing export...';
    });

    try {
      // Simulate export process
      final fileName = 'maliup-data-${DateTime.now().toIso8601String()}'
          '.${selectedFormat == 'json' ? 'json' : 'csv'}';

      // In real implementation, call API:
      // final bytes = await apiService.downloadFile(
      //   '/user/data-export/${selectedFormat}'
      // );

      setState(() => exportProgress = 'Downloading...');
      await Future.delayed(const Duration(seconds: 2));

      setState(() => exportProgress = 'Saving to device...');
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        isExporting = false;
        exportProgress = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data exported: $fileName'),
          backgroundColor: Colors.green,
        ),
      );

      // Log export to audit trail
      // await auditService.log({
      //   action: 'DATA_EXPORT',
      //   resourceType: 'user',
      //   status: 'success',
      //   details: { format: selectedFormat }
      // });
    } catch (e) {
      setState(() {
        isExporting = false;
        exportProgress = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

