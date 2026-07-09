import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/reports_providers.dart';
import '../../services/report_export_service.dart';
import 'reports_hub_screen.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class VatSummaryScreen extends ConsumerWidget {
  const VatSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(vatSummaryProvider);
    final range = ref.watch(reportDateRangeProvider);
    final isSwahili = LocalizationService.isSwahili;
    final periodLabel = isSwahili ? range.labelSw : range.label;
    final isPayable = report.netVatPayable >= 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: AppColors.secondary),
        title: Text(
          _tr('VAT Summary', 'Muhtasari wa VAT'),
          style: GoogleFonts.dmSans(
            color: AppColors.secondary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(52),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: ReportDateRangeBar(),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TRA compliance badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _tr(
                      'TRA-compliant VAT report for period: $periodLabel',
                      'Ripoti ya VAT inayofuata TRA kwa kipindi: $periodLabel',
                    ),
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Output VAT (Sales)
          _VatSection(
            title: _tr(
              'Output VAT (on Sales)',
              'VAT ya Uzalishaji (kwa Mauzo)',
            ),
            color: AppColors.success,
            icon: Icons.arrow_upward_rounded,
            children: [
              _VatRow(
                label: _tr(
                  'Taxable Sales Amount',
                  'Kiasi cha Mauzo Yanayotozwa',
                ),
                value: formatCurrency(report.taxableSalesAmount),
              ),
              _VatRow(
                label: _tr(
                  'Number of Taxable Invoices',
                  'Idadi ya Ankara Zinazotosha',
                ),
                value: '${report.taxableSalesCount}',
                isAmount: false,
              ),
              _VatRow(
                label: _tr(
                  'VAT Collected (Output)',
                  'VAT Iliyokusanywa (Output)',
                ),
                value: formatCurrency(report.vatCollectedOnSales),
                bold: true,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Input VAT (Purchases)
          _VatSection(
            title: _tr(
              'Input VAT (on Purchases)',
              'VAT ya Mauzo ya Ndani (kwa Manunuzi)',
            ),
            color: AppColors.warning,
            icon: Icons.arrow_downward_rounded,
            children: [
              _VatRow(
                label: _tr(
                  'Taxable Purchases Amount',
                  'Kiasi cha Manunuzi Yanayotozwa',
                ),
                value: formatCurrency(report.taxablePurchasesAmount),
              ),
              _VatRow(
                label: _tr(
                  'Taxable Purchase Records',
                  'Rekodi za Manunuzi Yanayotosha',
                ),
                value: '${report.taxablePurchasesCount}',
                isAmount: false,
              ),
              _VatRow(
                label: _tr('VAT Paid (Input)', 'VAT Iliyolipwa (Input)'),
                value: formatCurrency(report.vatPaidOnPurchases),
                bold: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Net result
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isPayable ? AppColors.errorBg : AppColors.successBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isPayable ? AppColors.error : AppColors.success,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  isPayable
                      ? _tr(
                          'NET VAT PAYABLE TO TRA',
                          'VAT HALISI INAYOLIPWA KWA TRA',
                        )
                      : _tr('NET VAT REFUNDABLE', 'VAT HALISI INAYORUDISHWA'),
                  style: GoogleFonts.dmSans(
                    color: isPayable ? AppColors.error : AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  formatCurrency(report.netVatPayable.abs()),
                  style: GoogleFonts.dmSans(
                    color: isPayable ? AppColors.error : AppColors.success,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  isPayable
                      ? _tr(
                          'Amount to remit to TRA this period',
                          'Kiasi cha kulipa TRA kipindi hiki',
                        )
                      : _tr(
                          'Excess input VAT — claim refund from TRA',
                          'VAT ya ziada ya input — dai kurejeshesha kutoka TRA',
                        ),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: isPayable
                        ? AppColors.error.withValues(alpha: 0.8)
                        : AppColors.success.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // TRA note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _tr(
                'Note: This report is based on your recorded transactions. Always verify with your accountant before TRA filing.',
                'Kumbuka: Ripoti hii inategemea miamala yako iliyorekodiwa. Thibitisha na mhasibu wako kabla ya kuwasilisha TRA.',
              ),
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          ReportExportRow(
            onPdf: () => exportReportPdf(
              context,
              () => ReportExportService.shareVatPdf(report, periodLabel),
            ),
            onCsv: () async {
              await ReportExportService.copyToClipboard(
                ReportExportService.vatCsv(report, periodLabel),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _tr('CSV copied to clipboard', 'CSV imenakiliwa'),
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _VatSection extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final List<Widget> children;

  const _VatSection({
    required this.title,
    required this.color,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.dmSans(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.border),
          ...children,
        ],
      ),
    );
  }
}

class _VatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool isAmount;

  const _VatRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.isAmount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.dmSans(
              color: bold ? AppColors.secondary : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
