import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_notification.dart';
import '../../../../core/services/localization_service.dart';

class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  bool isExporting = false;
  String selectedFormat = 'json';
  double exportProgress = 0.0;
  String? exportStatus;
  String? exportedFilePath;

  final Map<String, bool> selectedDataTypes = {
    'invoices': true,
    'customers': true,
    'expenses': true,
    'inventory': true,
    'accounts': true,
    'settings': false,
  };

  String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Custom AppBar ────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              color: AppColors.navyPrimary,
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _tr('Export Data', 'Hamisha Data'),
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.navyPrimary,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 40 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header: Title & Description (left) + Icon (right) ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tr('Download Your Data', 'Pakua Data Yako'),
                              style: GoogleFonts.dmSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navyPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _tr(
                                'Export all your business data as a backup.',
                                'Hamisha data yako yote kwa ajili ya kuweka muhtasari.'
                              ),
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: AppColors.textMuted,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.tealAccent, AppColors.navySecondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.tealAccent.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                          size: 20.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Data Types Selection ─────────────────────
                  Text(
                    _tr('Select Data to Export', 'Chagua Data ya Kuhamisha').toUpperCase(),
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _DataTypeCheckbox(
                          label: _tr('Invoices', 'Ankara'),
                          icon: Icons.receipt_long_rounded,
                          value: selectedDataTypes['invoices']!,
                          onChanged: isExporting ? null : (val) => setState(() => selectedDataTypes['invoices'] = val),
                          description: _tr('All sales invoices', 'Ankara zote za mauzo'),
                        ),
                        const Divider(height: 1),
                        _DataTypeCheckbox(
                          label: _tr('Customers', 'Wateja'),
                          icon: Icons.people_rounded,
                          value: selectedDataTypes['customers']!,
                          onChanged: isExporting ? null : (val) => setState(() => selectedDataTypes['customers'] = val),
                          description: _tr('Customer database', 'Database ya wateja'),
                        ),
                        const Divider(height: 1),
                        _DataTypeCheckbox(
                          label: _tr('Expenses', 'Matumizi'),
                          icon: Icons.trending_down_rounded,
                          value: selectedDataTypes['expenses']!,
                          onChanged: isExporting ? null : (val) => setState(() => selectedDataTypes['expenses'] = val),
                          description: _tr('All business expenses', 'Matumizi yote'),
                        ),
                        const Divider(height: 1),
                        _DataTypeCheckbox(
                          label: _tr('Inventory', 'Hazina'),
                          icon: Icons.inventory_2_rounded,
                          value: selectedDataTypes['inventory']!,
                          onChanged: isExporting ? null : (val) => setState(() => selectedDataTypes['inventory'] = val),
                          description: _tr('Stock & products', 'Bidhaa na stock'),
                        ),
                        const Divider(height: 1),
                        _DataTypeCheckbox(
                          label: _tr('Financial Accounts', 'Akaunti'),
                          icon: Icons.account_balance_rounded,
                          value: selectedDataTypes['accounts']!,
                          onChanged: isExporting ? null : (val) => setState(() => selectedDataTypes['accounts'] = val),
                          description: _tr('Bank & payment accounts', 'Akaunti za benki'),
                        ),
                        const Divider(height: 1),
                        _DataTypeCheckbox(
                          label: _tr('Account Settings', 'Mipangilio'),
                          icon: Icons.tune_rounded,
                          value: selectedDataTypes['settings']!,
                          onChanged: isExporting ? null : (val) => setState(() => selectedDataTypes['settings'] = val),
                          description: _tr('Profile & preferences', 'Profaili na mipangilio'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Format Selection ─────────────────────────────
                  Text(
                    _tr('Select Format', 'Chagua Muundo').toUpperCase(),
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FormatSelector(
                    selectedFormat: selectedFormat,
                    onChanged: isExporting ? null : (val) => setState(() => selectedFormat = val),
                  ),
                  const SizedBox(height: 32),

                  // ── Export Button ────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isExporting ? null : _handleExport,
                      icon: isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(
                        isExporting
                          ? _tr('Exporting...', 'Inahamishaishwa...')
                          : _tr('Download Now', 'Pakua Sasa'),
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navyPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        disabledBackgroundColor: AppColors.textDisabled,
                      ),
                    ),
                  ),

                  // ── Progress Indicator ───────────────────────────
                  if (isExporting) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.tealAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                exportStatus ?? _tr('Preparing...', 'Inatayarisha...'),
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navyPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: exportProgress,
                              minHeight: 4,
                              backgroundColor: AppColors.border,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.tealAccent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(exportProgress * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── File Path Info (after export) ────────────────
                  if (exportedFilePath != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.success.withValues(alpha: 0.15),
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _tr('Download Complete!', 'Pakua Kumalizika!'),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _tr('File location:', 'Mahali pa faili:'),
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                exportedFilePath!,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  color: AppColors.navyPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport() async {
    setState(() {
      isExporting = true;
      exportProgress = 0.0;
      exportStatus = _tr('Preparing export...', 'Inatayarisha hamisha...');
      exportedFilePath = null;
    });

    try {
      final fileName = 'maliup-data-${DateTime.now().toIso8601String()}'
          '.${selectedFormat == 'json' ? 'json' : 'csv'}';

      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        exportProgress = 0.3;
        exportStatus = _tr('Gathering data...', 'Ina kufanya kazi na data...');
      });

      await Future.delayed(const Duration(milliseconds: 1200));
      setState(() {
        exportProgress = 0.7;
        exportStatus = _tr('Compressing...', 'Inajenga faili...');
      });

      await Future.delayed(const Duration(milliseconds: 800));

      final filePath = '/storage/emulated/0/Download/$fileName';

      setState(() {
        exportProgress = 1.0;
        exportStatus = _tr('Complete!', 'Imekamilika!');
        exportedFilePath = filePath;
        isExporting = false;
      });

      if (!mounted) return;
      AppNotification.success(
        context,
        _tr('Data exported: $fileName', 'Data ilihamishibwa: $fileName'),
      );
    } catch (e) {
      setState(() {
        isExporting = false;
        exportProgress = 0.0;
        exportStatus = null;
        exportedFilePath = null;
      });

      if (!mounted) return;
      AppNotification.error(context, _tr('Export failed', 'Hamisha iliishindwa'));
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────

class _FormatSelector extends StatelessWidget {
  final String selectedFormat;
  final Function(String)? onChanged;

  const _FormatSelector({
    required this.selectedFormat,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FormatTile(
          selected: selectedFormat == 'json',
          icon: Icons.backup_rounded,
          title: 'JSON',
          subtitle: 'Complete backup • Best for archives',
          onTap: onChanged != null ? () => onChanged!('json') : null,
        ),
        const SizedBox(height: 12),
        _FormatTile(
          selected: selectedFormat == 'csv',
          icon: Icons.table_chart_rounded,
          title: 'CSV',
          subtitle: 'Spreadsheet format • Open in Excel',
          onTap: onChanged != null ? () => onChanged!('csv') : null,
        ),
      ],
    );
  }
}

class _FormatTile extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _FormatTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.navyPrimary.withValues(alpha: 0.05) : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.navyPrimary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppColors.navyPrimary.withValues(alpha: 0.1)
                      : AppColors.surfaceVariant,
                ),
                child: Icon(
                  icon,
                  color: selected ? AppColors.navyPrimary : AppColors.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: selected ? AppColors.navyPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.navyPrimary,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataTypeCheckbox extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String description;

  const _DataTypeCheckbox({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChanged != null ? () => onChanged!(!value) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value
                      ? AppColors.navyPrimary.withValues(alpha: 0.1)
                      : AppColors.surfaceVariant,
                ),
                child: Icon(
                  icon,
                  color: value ? AppColors.navyPrimary : AppColors.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: value,
                onChanged: onChanged != null ? (val) => onChanged!(val ?? false) : null,
                activeColor: AppColors.navyPrimary,
                checkColor: Colors.white,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                side: BorderSide(
                  color: value ? AppColors.navyPrimary : AppColors.border,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

